import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/gigs_service.dart';
import '../services/api_service.dart';

class GigDetailsScreen extends StatefulWidget {
  final String gigSlug;

  const GigDetailsScreen({
    super.key,
    required this.gigSlug,
  });

  @override
  State<GigDetailsScreen> createState() => _GigDetailsScreenState();
}

class _GigDetailsScreenState extends State<GigDetailsScreen> {
  final GigsService _gigsService = GigsService();
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic>? _gig;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  
  // Form fields
  final TextEditingController _submitDetailsController = TextEditingController();
  final List<File> _selectedImages = [];
  final List<String> _base64Images = [];
  bool _acceptedTerms = false;
  bool _acceptedCondition = false;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    _loadGigDetails();
  }

  @override
  void dispose() {
    _submitDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadGigDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final gigData = await _gigsService.fetchGigDetails(widget.gigSlug);
      
      if (mounted) {
        setState(() {
          _gig = gigData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final bytes = await imageFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        setState(() {
          _selectedImages.add(imageFile);
          _base64Images.add(base64String);
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _base64Images.removeAt(index);
    });
  }

  Future<void> _submitGig() async {
    // Validate form
    if (_submitDetailsController.text.trim().isEmpty ||
        !_acceptedTerms ||
        !_acceptedCondition) {
      setState(() => _showValidationErrors = true);
      return;
    }

    // Check if gig data is loaded
    if (_gig == null) {
      _showError('Gig details not loaded');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final headers = await ApiService.getHeaders();
      
      // Use the gig's UUID (id field), not the slug
      final gigId = _gig!['id'];
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/user-micro-gig-task-post/'),
        headers: headers,
        body: json.encode({
          'gig': gigId,  // Send UUID, not slug
          'medias': _base64Images,
          'submit_details': _submitDetailsController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order Submitted Successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Handle error response
        String errorMessage = 'Submission failed';
        try {
          final errorData = json.decode(response.body);
          
          // Check for various error formats from backend
          if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          } else if (errorData['detail'] != null) {
            errorMessage = errorData['detail'].toString();
          } else if (errorData['non_field_errors'] != null) {
            errorMessage = errorData['non_field_errors'].toString();
          }
        } catch (e) {
          errorMessage = 'Submission failed: ${response.statusCode}';
        }
        
        _showError(errorMessage);
      }
    } catch (e) {
      _showError('Error submitting gig: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gig Details'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading gig details...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGigDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_gig == null) {
      return const Center(child: Text('Gig not found'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildInstructions(),
          if (_gig!['medias'] != null && (_gig!['medias'] as List).isNotEmpty)
            _buildReferenceMedia(),
          if (_gig!['action_link'] != null && _gig!['action_link'].toString().isNotEmpty)
            _buildActionLink(),
          const Divider(height: 32, thickness: 1),
          _buildUploadSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final title = _gig!['title'] ?? '';
    final price = _gig!['price'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.work_outline, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Row(
              children: [
                Text(
                  'Earn: ',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
                Text(
                  '৳$price',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final instructions = _gig!['instructions'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instruction',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Html(
            data: instructions,
            style: {
              "body": Style(
                fontSize: FontSize(16),
                textAlign: TextAlign.justify,
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceMedia() {
    final medias = _gig!['medias'] as List;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reference Photo/Video',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: medias.map((media) {
              if (media['image'] != null) {
                return GestureDetector(
                  onTap: () {
                    // TODO: Open media viewer
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        media['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 40);
                        },
                      ),
                    ),
                  ),
                );
              } else if (media['video'] != null) {
                return GestureDetector(
                  onTap: () {
                    // TODO: Open video viewer
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_circle_outline, size: 40),
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionLink() {
    final actionLink = _gig!['action_link'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Url',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // TODO: Open URL in browser
            },
            child: Text(
              actionLink,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Proof',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Submit Details
          Text(
            'Submit Details *',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _submitDetailsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your micro job detail contents...',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              errorText: _showValidationErrors && _submitDetailsController.text.trim().isEmpty
                  ? 'Enter your micro job detail contents'
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          
          // Upload Images
          Text(
            'Upload',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                
                return Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              
              // Add Image Button
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Terms Checkbox
          CheckboxListTile(
            value: _acceptedTerms,
            onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text.rich(
              TextSpan(
                text: 'I accept ',
                style: GoogleFonts.roboto(fontSize: 14),
                children: const [
                  TextSpan(
                    text: 'Terms & Condition',
                    style: TextStyle(color: Colors.blue),
                  ),
                  TextSpan(text: ', '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(color: Colors.blue),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          if (_showValidationErrors && !_acceptedTerms)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                'Accept Terms & Condition, Privacy Policy',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
          
          // Condition Checkbox
          CheckboxListTile(
            value: _acceptedCondition,
            onChanged: (value) => setState(() => _acceptedCondition = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'I am aware that fake and fraud submission may lead to account ban!',
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
          if (_showValidationErrors && !_acceptedCondition)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                'Accept Conditions',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
          const SizedBox(height: 24),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitGig,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'I Completed!',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
