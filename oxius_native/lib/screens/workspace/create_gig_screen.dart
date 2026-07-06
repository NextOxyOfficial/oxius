import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/workspace_service.dart';
import '../../services/translation_service.dart';
import '../../utils/network_error_handler.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _emerald = Color(0xFF10B981);
const _slate50 = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFE2E8F0);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate700 = Color(0xFF334155);
const _slate800 = Color(0xFF1E293B);

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

  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

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
          _categories =
              List<Map<String, dynamic>>.from(options['categories'] ?? []);
          _allSkills = List<Map<String, dynamic>>.from(options['skills'] ?? []);
          _deliveryTimes =
              List<Map<String, dynamic>>.from(options['delivery_times'] ?? []);
          _revisionOptions = List<Map<String, dynamic>>.from(
              options['revision_options'] ?? []);

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
      return _allSkills
          .take(8)
          .map((s) => s['name']?.toString() ?? '')
          .toList();
    }
    final categorySkills = _allSkills
        .where((s) => s['category_slug'] == _selectedCategory)
        .map((s) => s['name']?.toString() ?? '')
        .toList();
    if (categorySkills.isEmpty) {
      return _allSkills
          .take(8)
          .map((s) => s['name']?.toString() ?? '')
          .toList();
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
              AdsyToast.info(context,
                  _t('workspace_max_5_images', 'সর্বোচ্চ ৫টি ছবি দেওয়া যাবে'));
            }
            break;
          }

          // Use XFile.readAsBytes() directly - works on all platforms
          final bytes = await image.readAsBytes();

          // Check file size (5MB max)
          if (bytes.length > 5 * 1024 * 1024) {
            if (mounted) {
              AdsyToast.info(context,
                  '${image.name} ${_t('workspace_image_too_large', 'অনেক বড়। সর্বোচ্চ ৫MB')}');
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
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          customMessage:
              _t('workspace_pick_images_failed', 'ছবি বেছে নেওয়া যায়নি'),
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

    final validFeatures =
        _featureControllers.where((c) => c.text.trim().isNotEmpty).length >= 3;

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
      _selectedDeliveryTime = _deliveryTimes.isNotEmpty
          ? _deliveryTimes[0]['days']?.toString()
          : '3';
      _selectedRevisions = _revisionOptions.isNotEmpty
          ? _revisionOptions[0]['count']?.toString()
          : '2';
      _selectedImages.clear();
      _imageBytes.clear();
      _base64Images.clear();
      _skills.clear();
    });
  }

  Future<void> _submitGig() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      AdsyToast.warning(
          context, _t('workspace_select_category', 'একটি ক্যাটাগরি বেছে নিন'));
      return;
    }

    if (_selectedImages.isEmpty) {
      AdsyToast.warning(
          context, _t('workspace_add_one_image', 'অন্তত একটি ছবি দিন'));
      return;
    }

    final validFeatures = _featureControllers
        .map((c) => c.text.trim())
        .where((f) => f.isNotEmpty)
        .toList();

    if (validFeatures.length < 3) {
      AdsyToast.warning(
          context, _t('workspace_add_3_features', 'অন্তত ৩টি ফিচার দিন'));
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

        AdsyToast.success(context,
            '"$gigTitle" ${_t('workspace_submitted_for_review', 'রিভিউর জন্য জমা হয়েছে!')}');

        _resetForm();
        widget.onGigCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        AdsyToast.error(
            context, _t('workspace_gig_create_failed', 'গিগ তৈরি করা যায়নি'));
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
      return const ColoredBox(
        color: _slate50,
        child: Center(child: AdsyLoadingIndicator()),
      );
    }

    return Container(
      color: _slate50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),
              const SizedBox(height: 12),
              _buildImagesSection(),
              const SizedBox(height: 12),
              _buildDetailsSection(),
              const SizedBox(height: 12),
              _buildSkillsSection(),
              const SizedBox(height: 12),
              _buildDeliverySection(),
              const SizedBox(height: 12),
              _buildFeaturesSection(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final activeFeatures = _featureControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _indigo.withValues(alpha: 0.12),
            _violet.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _indigo.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_indigo, _violet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('workspace_post_pro_gig', 'পেশাদার গিগ দিন'),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _t('workspace_post_pro_gig_sub',
                          'অফারটি পরিষ্কার, ছোট আর মার্কেটপ্লেসের সাথে মানানসই রাখুন।'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.35,
                        color: _slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildHeroStat(
                  icon: Icons.photo_library_outlined,
                  label: _t('workspace_images', 'ছবি'),
                  value: '${_selectedImages.length}/5',
                  tint: _indigo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeroStat(
                  icon: Icons.checklist_rounded,
                  label: _t('workspace_features', 'ফিচার'),
                  value: '$activeFeatures ${_t('workspace_ready', 'রেডি')}',
                  tint: _emerald,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String label,
    required String value,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: tint),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _slate500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _slate800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return _buildSectionCard(
      title: _t('workspace_gig_gallery', 'গিগ গ্যালারি'),
      subtitle: _t('workspace_gig_gallery_sub',
          'সর্বোচ্চ ৫টি সুন্দর প্রিভিউ ছবি দিন। প্রথমটি কভার হবে।'),
      icon: Icons.photo_library_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 360
                  ? 3
                  : constraints.maxWidth < 560
                      ? 4
                      : 5;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _selectedImages.length +
                    (_selectedImages.length < 5 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFF6F8FC)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _slate200, width: 1.4),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: _indigo,
                                size: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _t('workspace_add', 'যোগ'),
                              style: GoogleFonts.inter(
                                color: _slate700,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => _setAsMainImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: index == 0 ? _indigo : _slate200,
                                width: index == 0 ? 2 : 1,
                              ),
                              image: DecorationImage(
                                image: MemoryImage(_imageBytes[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: _indigo,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _t('workspace_main', 'মেইন'),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.58),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                      if (index > 0)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _setAsMainImage(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.46),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _t('workspace_set_as_main', 'মেইন করুন'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            _t('workspace_image_size_hint',
                'সাইজ ১২৮০x৭২০px রাখলে ভালো। পরিষ্কার প্রিভিউ বেশি কাজ করে।'),
            style: GoogleFonts.inter(
              color: _slate500,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return _buildSectionCard(
      title: _t('workspace_gig_details_title', 'গিগের বিবরণ'),
      subtitle: _t('workspace_gig_details_sub',
          'পজিশনিং, দাম আর সার্ভিসের বর্ণনা পরিষ্কারভাবে দিন।'),
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: _t('workspace_gig_title_label', 'গিগ টাইটেল'),
            controller: _titleController,
            hintText: _t('workspace_gig_title_hint',
                'আমি আপনার ব্যবসার জন্য পেশাদার লোগো ডিজাইন করব'),
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _t('workspace_enter_title', 'একটি টাইটেল দিন');
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          Text(
            _t('workspace_title_helper',
                'একনজরে বোঝা যায় এমন একটি প্রতিশ্রুতি দিয়ে শুরু করুন।'),
            style: GoogleFonts.inter(color: _slate500, fontSize: 11),
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: _t('workspace_category', 'ক্যাটাগরি'),
            value: _selectedCategory,
            isRequired: true,
            items: _categories.map((cat) {
              return DropdownMenuItem(
                value: cat['slug']?.toString() ??
                    cat['value']?.toString() ??
                    cat['id']?.toString() ??
                    '',
                child: Text(
                  cat['name'] ?? cat['label'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: (value) =>
                value == null ? _t('workspace_required', 'আবশ্যক') : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: _t('workspace_price_label', 'দাম (৳)'),
            controller: _priceController,
            keyboardType: TextInputType.number,
            hintText: '500',
            prefixText: '৳ ',
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _t('workspace_required', 'আবশ্যক');
              }
              final price = double.tryParse(value.trim());
              if (price == null || price < 5) {
                return _t('workspace_min_price', 'কমপক্ষে ৳৫');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: _t('workspace_description', 'বিবরণ'),
            controller: _descriptionController,
            minLines: 4,
            maxLines: 7,
            hintText: _t('workspace_description_hint',
                'বায়াররা কী পাবে, আপনি কীভাবে কাজ করেন আর আপনার অফার কেন আলাদা তা লিখুন।'),
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _t('workspace_enter_description', 'একটি বিবরণ দিন');
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          Text(
            _t('workspace_description_helper',
                'ছোট কিন্তু পূর্ণাঙ্গ বিবরণ দিন যাতে বায়াররা সহজে ভরসা পায়।'),
            style: GoogleFonts.inter(color: _slate500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return _buildSectionCard(
      title: _t('workspace_skills_title', 'দক্ষতা ও অভিজ্ঞতা'),
      subtitle: _t('workspace_skills_sub',
          'প্রাসঙ্গিক ট্যাগ দিন যাতে গিগটি সঠিক বায়ার ও সার্চে আসে।'),
      icon: Icons.auto_awesome_motion_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillInputController,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _slate800,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: _buildInputDecoration(
                    hintText:
                        _t('workspace_skill_hint', 'যেমন: লোগো ডিজাইন, ফটোশপ'),
                  ),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _skills.length < 10 ? _addSkill : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slate800,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _slate200,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add_rounded, size: 18),
                ),
              ),
            ],
          ),
          if (_skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _skills.asMap().entries.map((entry) {
                return Chip(
                  label: Text(
                    entry.value,
                    style: GoogleFonts.inter(
                      color: _indigo,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  deleteIcon:
                      const Icon(Icons.close_rounded, size: 14, color: _indigo),
                  onDeleted: () => _removeSkill(entry.key),
                  backgroundColor: const Color(0xFFEEF2FF),
                  side: BorderSide.none,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity:
                      const VisualDensity(horizontal: -2, vertical: -2),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }).toList(),
            ),
          ],
          if (_suggestedSkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _t('workspace_suggested_skills', 'সাজেস্ট করা দক্ষতা'),
              style: GoogleFonts.inter(
                color: _slate500,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestedSkills
                  .where((skill) => !_skills.contains(skill))
                  .take(8)
                  .map((skill) {
                return GestureDetector(
                  onTap: () => _addSuggestedSkill(skill),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _slate200),
                    ),
                    child: Text(
                      '+ $skill',
                      style: GoogleFonts.inter(
                        color: _slate700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _t('workspace_skills_helper',
                'সর্বোচ্চ ১০টি দক্ষতা দিন। এন্টার চাপুন বা প্লাস বাটন ব্যবহার করুন।'),
            style: GoogleFonts.inter(color: _slate500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return _buildSectionCard(
      title: _t('workspace_delivery_title', 'ডেলিভারি ও রিভিশন'),
      subtitle: _t('workspace_delivery_sub',
          'বায়াররা ভরসা করতে পারে এমন বাস্তবসম্মত সময় ও রিভিশন সীমা দিন।'),
      icon: Icons.schedule_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useVerticalLayout = constraints.maxWidth < 420;

          if (useVerticalLayout) {
            return Column(
              children: [
                _buildDropdownField(
                  label: _t('workspace_delivery_time', 'ডেলিভারি সময়'),
                  value: _selectedDeliveryTime,
                  items: _deliveryTimes.map((time) {
                    return DropdownMenuItem(
                      value: time['days']?.toString(),
                      child: Text(
                        time['label'] ?? '${time['days']} Days',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedDeliveryTime = value),
                ),
                const SizedBox(height: 12),
                _buildDropdownField(
                  label: _t('workspace_revisions', 'রিভিশন'),
                  value: _selectedRevisions,
                  items: _revisionOptions.map((rev) {
                    return DropdownMenuItem(
                      value: rev['count']?.toString(),
                      child: Text(
                        rev['label'] ?? '${rev['count']} Revisions',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedRevisions = value),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: _t('workspace_delivery_time', 'ডেলিভারি সময়'),
                  value: _selectedDeliveryTime,
                  items: _deliveryTimes.map((time) {
                    return DropdownMenuItem(
                      value: time['days']?.toString(),
                      child: Text(
                        time['label'] ?? '${time['days']} Days',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedDeliveryTime = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdownField(
                  label: _t('workspace_revisions', 'রিভিশন'),
                  value: _selectedRevisions,
                  items: _revisionOptions.map((rev) {
                    return DropdownMenuItem(
                      value: rev['count']?.toString(),
                      child: Text(
                        rev['label'] ?? '${rev['count']} Revisions',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedRevisions = value),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return _buildSectionCard(
      title: _t('workspace_features_title', 'বায়াররা যা পাবে'),
      subtitle: _t('workspace_features_sub',
          'এই সার্ভিস থেকে বায়াররা ঠিক কী কী পাবে তা লিখুন।'),
      icon: Icons.checklist_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._featureControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: _emerald,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _slate800,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _buildInputDecoration(
                        hintText: _t('workspace_feature_hint',
                            'যেমন: হাই-কোয়ালিটি লোগো ডিজাইন'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _featureControllers.length > 1
                        ? () => _removeFeature(index)
                        : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _featureControllers.length > 1
                            ? const Color(0xFFFEF2F2)
                            : _slate100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _featureControllers.length > 1
                              ? const Color(0xFFFECACA)
                              : _slate200,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: _featureControllers.length > 1
                            ? const Color(0xFFDC2626)
                            : _slate400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          InkWell(
            onTap: _featureControllers.length < 10 ? _addFeature : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _slate200),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: _slate700, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _t('workspace_add_feature', 'ফিচার যোগ করুন'),
                    style: GoogleFonts.inter(
                      color: _slate700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t('workspace_features_helper',
                'অন্তত ৩টি নির্দিষ্ট ডেলিভারেবল দিন যা বায়াররা সহজে যাচাই করতে পারে।'),
            style: GoogleFonts.inter(color: _slate500, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_indigo, _violet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 17, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.35,
                        color: _slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? prefixText,
    bool isRequired = false,
    int? minLines,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _slate700,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _slate800,
            fontWeight: FontWeight.w500,
          ),
          decoration: _buildInputDecoration(
            hintText: hintText,
            prefixText: prefixText,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _slate700,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _slate800,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _slate500,
            size: 18,
          ),
          decoration: _buildInputDecoration(),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    String? hintText,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      hintStyle: GoogleFonts.inter(
        fontSize: 12,
        color: _slate400,
      ),
      prefixStyle: GoogleFonts.inter(
        fontSize: 12,
        color: _slate700,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _indigo, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
      ),
      errorStyle: GoogleFonts.inter(fontSize: 11),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _resetForm,
              style: OutlinedButton.styleFrom(
                foregroundColor: _slate700,
                side: BorderSide(color: _slate200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _t('workspace_reset', 'রিসেট'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _isLoading || !_isFormValid ? null : _submitGig,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigo,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _slate200,
                  disabledForegroundColor: _slate400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: AdsyLoadingIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _t('workspace_create_gig', 'গিগ তৈরি করুন'),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
