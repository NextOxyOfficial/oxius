import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/gigs_service.dart';
import '../services/api_service.dart';
import '../utils/url_launcher_utils.dart';
import 'terms_and_conditions_screen.dart';
import 'privacy_policy_screen.dart';

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
  bool _hasSubmitted = false;
  
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
          _hasSubmitted = gigData['user_has_submitted'] ?? false;
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
          // Return true to indicate successful submission
          Navigator.pop(context, true);
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Gig Details',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading gig details...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadGigDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_gig == null) {
      return const Center(child: Text('Gig not found'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildHeader(),
            const SizedBox(height: 4),
            _buildInstructions(),
            if (_gig!['medias'] != null && (_gig!['medias'] as List).isNotEmpty)
              _buildReferenceMedia(),
            if (_gig!['action_link'] != null && _gig!['action_link'].toString().isNotEmpty)
              _buildActionLink(),
            const SizedBox(height: 4),
            _buildUploadSection(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = _gig!['title'] ?? '';
    final price = _gig!['price'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Earn: ',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '৳$price',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (_hasSubmitted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.orange.shade700,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Submitted',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final instructions = _gig!['instructions'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF3B82F6),
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Instructions',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Html(
              data: instructions,
              onLinkTap: (url, attributes, element) {
                UrlLauncherUtils.launchExternalUrl(url);
              },
              style: {
                "body": Style(
                  fontSize: FontSize(13),
                  textAlign: TextAlign.justify,
                  color: const Color(0xFF374151),
                  lineHeight: const LineHeight(1.5),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceMedia() {
    final medias = _gig!['medias'] as List;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF8B5CF6),
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Reference Media',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: medias.map((media) {
              if (media['image'] != null) {
                return GestureDetector(
                  onTap: () {
                    // TODO: Open media viewer
                  },
                  child: Hero(
                    tag: media['image'],
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          media['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 28,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        ),
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
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.play_circle_filled_rounded,
                      size: 32,
                      color: Colors.red.shade400,
                    ),
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () async {
          final url = Uri.parse(actionLink);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not open URL'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFBBF24),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Action URL',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      actionLink,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: const Color(0xFF78350F),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.open_in_new_rounded,
                color: const Color(0xFFFBBF24),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: Color(0xFF10B981),
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Upload Your Work',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Submit Details
              Text(
                'Submit Details *',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _submitDetailsController,
                maxLines: 4,
                style: GoogleFonts.roboto(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Describe how you completed this task...',
                  hintStyle: GoogleFonts.roboto(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(10),
                  errorText: _showValidationErrors && _submitDetailsController.text.trim().isEmpty
                      ? 'Please enter your work details'
                      : null,
                  errorStyle: GoogleFonts.roboto(fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
          
              // Upload Images
              Text(
                'Upload Proof Images',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final image = entry.value;
                    
                    return Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
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
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.red.shade500,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 12,
                                color: Colors.white,
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
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 24,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add',
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
                
              // Terms and Conditions
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                            activeColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Wrap(
                              children: [
                                Text(
                                  'I accept ',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TermsAndConditionsScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Terms & Condition',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: const Color(0xFF3B82F6),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text(
                                  ', ',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PrivacyPolicyScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Privacy Policy',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: const Color(0xFF3B82F6),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                Text(
                                  '.',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showValidationErrors && !_acceptedTerms)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, size: 12, color: Colors.red.shade700),
                            const SizedBox(width: 3),
                            Text(
                              'Please accept Terms & Conditions',
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // Fraud Warning Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                            value: _acceptedCondition,
                            onChanged: (value) => setState(() => _acceptedCondition = value ?? false),
                            activeColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'I am aware that fake and fraud submission may lead to account ban!',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showValidationErrors && !_acceptedCondition)
                      Padding(
                        padding: const EdgeInsets.only(left: 32, top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded, size: 12, color: Colors.red.shade700),
                            const SizedBox(width: 3),
                            Text(
                              'Please acknowledge the warning',
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
                
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _hasSubmitted) ? null : _submitGig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasSubmitted 
                        ? Colors.grey.shade400 
                        : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade400,
                    disabledForegroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _hasSubmitted ? Icons.check_circle_rounded : Icons.check_circle_rounded,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _hasSubmitted ? 'Already Submitted' : 'Submit Work',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
