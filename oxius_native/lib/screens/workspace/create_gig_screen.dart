import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/workspace_service.dart';

class CreateGigScreen extends StatefulWidget {
  final VoidCallback? onGigCreated;
  
  const CreateGigScreen({super.key, this.onGigCreated});

  @override
  State<CreateGigScreen> createState() => _CreateGigScreenState();
}

class _CreateGigScreenState extends State<CreateGigScreen> {
  final WorkspaceService _workspaceService = WorkspaceService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _skillInputController = TextEditingController();
  
  // Dynamic options from API
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allSkills = [];
  List<Map<String, dynamic>> _deliveryTimes = [];
  List<Map<String, dynamic>> _revisionOptions = [];
  
  // Form state
  String? _selectedCategory;
  String? _selectedDeliveryTime;
  String? _selectedRevisions;
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imageBytes = [];
  final List<String> _base64Images = [];
  final List<String> _skills = [];
  final List<TextEditingController> _featureControllers = [];
  
  bool _isLoading = false;
  bool _isLoadingOptions = true;

  @override
  void initState() {
    super.initState();
    // Initialize with 3 feature controllers
    for (int i = 0; i < 3; i++) {
      _featureControllers.add(TextEditingController());
    }
    _loadOptions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _skillInputController.dispose();
    for (var controller in _featureControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await _workspaceService.fetchGigOptions();
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(options['categories'] ?? []);
          _allSkills = List<Map<String, dynamic>>.from(options['skills'] ?? []);
          _deliveryTimes = List<Map<String, dynamic>>.from(options['delivery_times'] ?? []);
          _revisionOptions = List<Map<String, dynamic>>.from(options['revision_options'] ?? []);
          
          // Set defaults
          if (_deliveryTimes.isNotEmpty) {
            _selectedDeliveryTime = _deliveryTimes[0]['days']?.toString();
          }
          if (_revisionOptions.isNotEmpty) {
            _selectedRevisions = _revisionOptions[0]['count']?.toString();
          }
          _isLoadingOptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
        // Fallback to basic categories
        _loadFallbackOptions();
      }
    }
  }

  Future<void> _loadFallbackOptions() async {
    try {
      final categories = await _workspaceService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          // Set default delivery times and revisions
          _deliveryTimes = [
            {'id': 1, 'days': 1, 'label': '1 Day'},
            {'id': 2, 'days': 3, 'label': '3 Days'},
            {'id': 3, 'days': 7, 'label': '7 Days'},
            {'id': 4, 'days': 14, 'label': '14 Days'},
            {'id': 5, 'days': 30, 'label': '30 Days'},
          ];
          _revisionOptions = [
            {'id': 1, 'count': 1, 'label': '1 Revision'},
            {'id': 2, 'count': 2, 'label': '2 Revisions'},
            {'id': 3, 'count': 3, 'label': '3 Revisions'},
            {'id': 4, 'count': 5, 'label': '5 Revisions'},
            {'id': 5, 'count': -1, 'label': 'Unlimited'},
          ];
          _selectedDeliveryTime = '3';
          _selectedRevisions = '2';
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  List<String> get _suggestedSkills {
    if (_selectedCategory == null || _allSkills.isEmpty) {
      return _allSkills.take(8).map((s) => s['name']?.toString() ?? '').toList();
    }
    final categorySkills = _allSkills
        .where((s) => s['category_slug'] == _selectedCategory)
        .map((s) => s['name']?.toString() ?? '')
        .toList();
    if (categorySkills.isEmpty) {
      return _allSkills.take(8).map((s) => s['name']?.toString() ?? '').toList();
    }
    return categorySkills;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        for (var image in images) {
          if (_selectedImages.length >= 5) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Maximum 5 images allowed')),
              );
            }
            break;
          }
          
          // Use XFile.readAsBytes() directly - works on all platforms
          final bytes = await image.readAsBytes();
          
          // Check file size (5MB max)
          if (bytes.length > 5 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${image.name} is too large. Max 5MB')),
              );
            }
            continue;
          }
          
          final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          
          setState(() {
            _selectedImages.add(image);
            _imageBytes.add(bytes);
            _base64Images.add(base64String);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageBytes.removeAt(index);
      _base64Images.removeAt(index);
    });
  }

  void _setAsMainImage(int index) {
    if (index == 0) return;
    setState(() {
      final image = _selectedImages.removeAt(index);
      final bytes = _imageBytes.removeAt(index);
      final base64 = _base64Images.removeAt(index);
      _selectedImages.insert(0, image);
      _imageBytes.insert(0, bytes);
      _base64Images.insert(0, base64);
    });
  }

  void _addSkill() {
    final skill = _skillInputController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill) && _skills.length < 10) {
      setState(() {
        _skills.add(skill);
        _skillInputController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
  }

  void _addSuggestedSkill(String skill) {
    if (!_skills.contains(skill) && _skills.length < 10) {
      setState(() {
        _skills.add(skill);
      });
    }
  }

  void _addFeature() {
    if (_featureControllers.length < 10) {
      setState(() {
        _featureControllers.add(TextEditingController());
      });
    }
  }

  void _removeFeature(int index) {
    if (_featureControllers.length > 1) {
      setState(() {
        _featureControllers[index].dispose();
        _featureControllers.removeAt(index);
      });
    }
  }

  bool get _isFormValid {
    final hasBasicInfo = _titleController.text.trim().isNotEmpty &&
        _selectedCategory != null &&
        _priceController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;
    
    final validFeatures = _featureControllers
        .where((c) => c.text.trim().isNotEmpty)
        .length >= 3;
    
    return hasBasicInfo && validFeatures && _selectedImages.isNotEmpty;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _skillInputController.clear();
    
    for (var controller in _featureControllers) {
      controller.dispose();
    }
    _featureControllers.clear();
    for (int i = 0; i < 3; i++) {
      _featureControllers.add(TextEditingController());
    }
    
    setState(() {
      _selectedCategory = null;
      _selectedDeliveryTime = _deliveryTimes.isNotEmpty ? _deliveryTimes[0]['days']?.toString() : '3';
      _selectedRevisions = _revisionOptions.isNotEmpty ? _revisionOptions[0]['count']?.toString() : '2';
      _selectedImages.clear();
      _imageBytes.clear();
      _base64Images.clear();
      _skills.clear();
    });
  }

  Future<void> _submitGig() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    
    final validFeatures = _featureControllers
        .map((c) => c.text.trim())
        .where((f) => f.isNotEmpty)
        .toList();
    
    if (validFeatures.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 3 features')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gigData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category': _selectedCategory,
        'delivery_time': int.parse(_selectedDeliveryTime ?? '3'),
        'revisions': int.parse(_selectedRevisions ?? '2'),
        'skills': _skills,
        'features': validFeatures,
        'images': _base64Images,
      };

      await _workspaceService.createGig(gigData);
      
      if (mounted) {
        final gigTitle = _titleController.text.trim();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$gigTitle" submitted for review!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        
        _resetForm();
        widget.onGigCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create gig: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Section
            _buildImagesSection(),
            const SizedBox(height: 24),

            // Gig Details Section
            _buildDetailsSection(),
            const SizedBox(height: 24),

            // Skills Section
            _buildSkillsSection(),
            const SizedBox(height: 24),

            // Delivery & Revisions
            _buildDeliverySection(),
            const SizedBox(height: 24),

            // Features Section
            _buildFeaturesSection(),
            const SizedBox(height: 32),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gig Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload up to 5 images. The first image will be your main gig image.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 12),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              // Add Image Button
              return GestureDetector(
                onTap: _pickImages,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.grey[500], size: 24),
                      const SizedBox(height: 2),
                      Text(
                        'Add',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Image preview
            return Stack(
              children: [
                GestureDetector(
                  onTap: () => _setAsMainImage(index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: index == 0 ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
                        width: index == 0 ? 2 : 1,
                      ),
                      image: DecorationImage(
                        image: MemoryImage(_imageBytes[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Main badge
                if (index == 0)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'Main',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                      ),
                    ),
                  ),
                // Remove button
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                    ),
                  ),
                ),
                // Set as main hint
                if (index > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _setAsMainImage(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(153),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(7),
                            bottomRight: Radius.circular(7),
                          ),
                        ),
                        child: const Text(
                          'Set main',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 8),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Recommended: 1280x720px • Max 5 images',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gig Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Title
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Gig Title *',
            hintText: 'I will design a professional logo for your business',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Make it clear and descriptive',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
        const SizedBox(height: 16),

        // Category
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Category *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: _categories.map((cat) {
            return DropdownMenuItem(
              value: cat['slug']?.toString() ?? cat['value']?.toString() ?? cat['id']?.toString() ?? '',
              child: Text(
                cat['name'] ?? cat['label'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
          validator: (value) => value == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),

        // Price
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Price (৳) *',
            prefixText: '৳ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            final price = double.tryParse(value.trim());
            if (price == null || price < 5) return 'Min ৳5';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Description
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Description *',
            hintText: 'Describe your service in detail. What will you deliver? What makes your service unique?',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(
          'Be specific about what you\'ll deliver',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Skills & Expertise',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        // Skill Input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _skillInputController,
                decoration: InputDecoration(
                  hintText: 'e.g., Logo Design, Photoshop',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                onSubmitted: (_) => _addSkill(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _skills.length < 10 ? _addSkill : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Added Skills
        if (_skills.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.asMap().entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.value,
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeSkill(entry.key),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        
        // Suggested Skills
        if (_suggestedSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Suggested skills:',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestedSkills
                .where((s) => !_skills.contains(s))
                .take(8)
                .map((skill) {
              return GestureDetector(
                onTap: () => _addSuggestedSkill(skill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+ $skill',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Add up to 10 skills (press Enter to add)',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedDeliveryTime,
            decoration: InputDecoration(
              labelText: 'Delivery Time',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _deliveryTimes.map((time) {
              return DropdownMenuItem(
                value: time['days']?.toString(),
                child: Text(time['label'] ?? '${time['days']} Days'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedDeliveryTime = value),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedRevisions,
            decoration: InputDecoration(
              labelText: 'Revisions',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _revisionOptions.map((rev) {
              return DropdownMenuItem(
                value: rev['count']?.toString(),
                child: Text(rev['label'] ?? '${rev['count']} Revisions'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedRevisions = value),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What Buyers Will Get *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        // Feature inputs
        ..._featureControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'e.g., High-quality logo design',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _featureControllers.length > 1 ? () => _removeFeature(index) : null,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _featureControllers.length > 1 ? Colors.red[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: _featureControllers.length > 1 ? Colors.red : Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        
        // Add feature button
        GestureDetector(
          onTap: _featureControllers.length < 10 ? _addFeature : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add feature',
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add at least 3 features that buyers will receive',
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading || !_isFormValid ? null : _submitGig,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 6),
                      Text('Create Gig', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
