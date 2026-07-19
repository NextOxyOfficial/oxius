import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/gigs_service.dart';
import '../services/api_service.dart';
import '../services/ads_service.dart';
import '../services/microgig_service.dart';
import '../utils/image_compressor.dart';
import '../utils/url_launcher_utils.dart';
import 'terms_and_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

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
  final TextEditingController _submitDetailsController =
      TextEditingController();
  final List<File> _selectedImages = [];
  final List<String> _base64Images = [];
  bool _acceptedTerms = false;
  bool _acceptedCondition = false;
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    _loadGigDetails();
    // Warm up the highest-eCPM slot so tapping Submit shows it instantly.
    AdsService.preloadRewarded('gig_submit_rewarded');
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
        // Sync surfaces that show this gig as an "earn now" card (e.g. the
        // BN feed) when the server says it was already submitted.
        if (_hasSubmitted) MicrogigService.markSubmitted(widget.gigSlug);
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
        // Compress before encoding (fallback to original bytes on failure)
        final compressed = await ImageCompressor.compressToBase64(
          image,
          targetSize: 80 * 1024,
        );
        final String base64String;
        if (compressed != null) {
          base64String = compressed;
        } else {
          final bytes = await imageFile.readAsBytes();
          base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }

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

    // Monetization: a rewarded video plays before the work is submitted.
    // This is the app's highest-eCPM slot and fits the earning context.
    // It NEVER blocks — if no ad is ready, showRewarded returns instantly and
    // the submission proceeds as normal.
    if (AdsService.placementActive('gig_submit_rewarded')) {
      await AdsService.showRewarded('gig_submit_rewarded');
      if (!mounted) return;
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
          'gig': gigId, // Send UUID, not slug
          'medias': _base64Images,
          'submit_details': _submitDetailsController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Record globally FIRST so every open surface (feed card, gig list)
        // flips to its completed state even if this screen is gone.
        MicrogigService.markSubmitted(widget.gigSlug);
        if (mounted) {
          AdsyToast.success(context, 'Order Submitted Successfully!');
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
      AdsyToast.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          'Task Details',
          style: AppFonts.roboto(
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
            color: const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        foregroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: AdsyLoadingIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 36, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                'টাস্কটা লোড করা গেল না',
                style: AppFonts.roboto(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।',
                textAlign: TextAlign.center,
                style: AppFonts.roboto(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: _loadGigDetails,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('আবার চেষ্টা করুন'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
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
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _sectionHeader(Icons.description_outlined, 'Instructions'),
            _buildInstructions(),
            if (_gig!['medias'] != null &&
                (_gig!['medias'] as List).isNotEmpty) ...[
              const SizedBox(height: 18),
              _sectionHeader(Icons.perm_media_outlined, 'Reference Media'),
              _buildReferenceMedia(),
            ],
            if (_gig!['action_link'] != null &&
                _gig!['action_link'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildActionLink(),
            ],
            const SizedBox(height: 18),
            _sectionHeader(Icons.cloud_upload_outlined, 'Submit Your Work'),
            _buildUploadSection(),
          ],
        ),
      ),
    );
  }

  // Consistent section header: a muted icon + uppercase label above each card.
  Widget _sectionHeader(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: AppFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final title = _gig!['title'] ?? '';
    final price = _gig!['price'] ?? 0;
    final required = int.tryParse('${_gig!['required_quantity'] ?? ''}') ?? 0;
    final filled = int.tryParse('${_gig!['filled_quantity'] ?? ''}') ?? 0;
    final remaining = (required - filled) < 0 ? 0 : (required - filled);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.roboto(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.35,
            ),
          ),
          if (_hasSubmitted) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      color: Color(0xFFD97706), size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted — under review',
                    style: AppFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Facts strip: earn / remaining slots — the numbers a worker needs.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEF2F6)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _statBlock(
                      Icons.payments_outlined,
                      'You earn',
                      '\u09f3$price',
                      const Color(0xFF059669),
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFE2E8F0),
                    indent: 2,
                    endIndent: 2,
                  ),
                  Expanded(
                    child: _statBlock(
                      Icons.groups_outlined,
                      'Slots left',
                      required > 0 ? '$remaining' : '—',
                      const Color(0xFF334155),
                      sub: required > 0 ? 'of $required' : null,
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

  Widget _statBlock(
    IconData icon,
    String label,
    String value,
    Color color, {
    String? sub,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppFonts.roboto(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(width: 4),
              Text(
                sub,
                style: AppFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Auto-links bare URLs typed as plain text inside the instructions HTML so
  // the existing Html onLinkTap makes them tappable. Skips anything already
  // inside an <a>...</a> anchor or an html tag/attribute (e.g. href="..."),
  // preserving hand-authored anchor links untouched.
  static final RegExp _autoLinkRegExp = RegExp(
    // 1: an existing anchor (kept verbatim)
    r'(<a\b[^>]*>[\s\S]*?</a>)'
    // 2: any other html tag (kept verbatim — protects attribute values)
    r'|(<[^>]+>)'
    // 3: a bare url in text content
    r'|((?:https?://|www\.)[^\s<>"' "'" r']+)',
    caseSensitive: false,
  );

  String _autoLinkBareUrls(String html) {
    if (html.isEmpty) return html;
    return html.replaceAllMapped(_autoLinkRegExp, (match) {
      final anchor = match.group(1);
      if (anchor != null) return anchor;
      final tag = match.group(2);
      if (tag != null) return tag;

      var url = match.group(3)!;
      // Keep trailing sentence punctuation outside the link target.
      var trailing = '';
      const trailingChars = ['.', ',', ';', ':', '!', '?', ')', ']', '}'];
      while (url.isNotEmpty && trailingChars.contains(url[url.length - 1])) {
        trailing = '${url[url.length - 1]}$trailing';
        url = url.substring(0, url.length - 1);
      }
      if (url.isEmpty) return match.group(3)!;

      final href = url.toLowerCase().startsWith('www.') ? 'https://$url' : url;
      return '<a href="$href">$url</a>$trailing';
    });
  }

  Widget _buildInstructions() {
    final instructions = _autoLinkBareUrls('${_gig!['instructions'] ?? ''}');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Html(
        data: instructions,
        onLinkTap: (url, attributes, element) {
          UrlLauncherUtils.launchExternalUrl(url);
        },
        style: {
          "body": Style(
            fontSize: FontSize(14.5),
            color: const Color(0xFF334155),
            lineHeight: const LineHeight(1.6),
            margin: Margins.zero,
          ),
          "a": Style(
            color: const Color(0xFF2563EB),
            textDecoration: TextDecoration.none,
          ),
        },
      ),
    );
  }

  Widget _buildReferenceMedia() {
    final medias = _gig!['medias'] as List;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: medias.map((media) {
              if (media['image'] != null) {
                return GestureDetector(
                  onTap: () => _openImageViewer(media['image']),
                  child: Hero(
                    tag: media['image'],
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
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
                  onTap: () =>
                      UrlLauncherUtils.launchExternalUrl(media['video']),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      size: 30,
                      color: Colors.white,
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

  void _openImageViewer(String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Hero(
                tag: imageUrl,
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
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
              AdsyToast.error(context, 'Could not open URL');
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF2563EB),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open the task link',
                      style: AppFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      actionLink,
                      style: AppFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF2563EB),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.open_in_new_rounded,
                color: Color(0xFF2563EB),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Submit Details
              Text(
                'Submit Details *',
                style: AppFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _submitDetailsController,
                maxLines: 4,
                style: AppFonts.roboto(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Describe how you completed this task...',
                  hintStyle: AppFonts.roboto(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF059669), width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(12),
                  errorText: _showValidationErrors &&
                          _submitDetailsController.text.trim().isEmpty
                      ? 'Please enter your work details'
                      : null,
                  errorStyle: AppFonts.roboto(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Upload Images
              Text(
                'Upload Proof Images',
                style: AppFonts.roboto(
                  fontSize: 14,
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
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
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
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 24,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add',
                            style: AppFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF059669),
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
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.scale(
                          scale: 1.0,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) =>
                                setState(() => _acceptedTerms = value ?? false),
                            activeColor: const Color(0xFF059669),
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
                                  style: AppFonts.roboto(
                                    fontSize: 13,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TermsAndConditionsScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Terms & Condition',
                                    style: AppFonts.roboto(
                                      fontSize: 13,
                                      color: const Color(0xFF3B82F6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  ', ',
                                  style: AppFonts.roboto(
                                    fontSize: 13,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PrivacyPolicyScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Privacy Policy',
                                    style: AppFonts.roboto(
                                      fontSize: 13,
                                      color: const Color(0xFF3B82F6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '.',
                                  style: AppFonts.roboto(
                                    fontSize: 13,
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
                            Icon(Icons.error_outline_rounded,
                                size: 12, color: Colors.red.shade700),
                            const SizedBox(width: 3),
                            Text(
                              'Please accept Terms & Conditions',
                              style: AppFonts.roboto(
                                fontSize: 12,
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
                          scale: 1.0,
                          child: Checkbox(
                            value: _acceptedCondition,
                            onChanged: (value) => setState(
                                () => _acceptedCondition = value ?? false),
                            activeColor: const Color(0xFF059669),
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
                              style: AppFonts.roboto(
                                fontSize: 13,
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
                            Icon(Icons.error_outline_rounded,
                                size: 12, color: Colors.red.shade700),
                            const SizedBox(width: 3),
                            Text(
                              'Please acknowledge the warning',
                              style: AppFonts.roboto(
                                fontSize: 12,
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
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      (_isSubmitting || _hasSubmitted) ? null : _submitGig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: AdsyLoadingIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _hasSubmitted ? 'Already Submitted' : 'Submit Work',
                          style: AppFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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
