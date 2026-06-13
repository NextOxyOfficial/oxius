import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/classified_post.dart';
import '../services/classified_post_service.dart';
import '../services/api_service.dart';
import '../utils/network_error_handler.dart';
import '../services/auth_service.dart';
import '../services/adsyconnect_service.dart';
import '../config/app_config.dart';
import '../utils/url_launcher_utils.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/common/adsy_report_sheet.dart';
import '../widgets/common/adsy_share_sheet.dart';
import 'adsy_connect_chat_interface.dart';
import 'user_posts_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class ClassifiedPostDetailsScreen extends StatefulWidget {
  final String postId;
  final String postSlug;

  const ClassifiedPostDetailsScreen({
    super.key,
    required this.postId,
    required this.postSlug,
  });

  @override
  State<ClassifiedPostDetailsScreen> createState() =>
      _ClassifiedPostDetailsScreenState();
}

class _ClassifiedPostDetailsScreenState
    extends State<ClassifiedPostDetailsScreen> {
  late final ClassifiedPostService _postService;

  ClassifiedPost? _post;
  bool _isLoading = true;
  bool _showPhone = false;
  int _currentImageIndex = 0;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _postService = ClassifiedPostService(baseUrl: ApiService.baseUrl);
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() => _isLoading = true);

    try {
      final post = await _postService.fetchPostById(widget.postSlug);
      if (mounted && post != null) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          onRetry: () => _loadPost(),
        );
      }
    }
  }

  Future<void> _openChatWithSeller() async {
    // Check authentication first
    if (!AuthService.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    if (_post?.user == null) {
      AdsyToast.error(context, 'Seller information not available');
      return;
    }

    debugPrint('🔵 Chat button tapped!');
    debugPrint('🔵 Post data: ${_post?.id}');
    debugPrint('🔵 User ID: ${_post?.user?.id}');

    if (_post?.user?.id == null) {
      debugPrint('🔴 Seller information not available');
      AdsyToast.error(context, 'Seller information not available');
      return;
    }

    debugPrint('🔵 Opening chat with seller ID: ${_post!.user!.id}');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: AdsyLoadingIndicator(color: Color(0xFF3B82F6)),
      ),
    );

    try {
      debugPrint('🔵 Creating/getting chat room...');
      // Get or create chat room with the seller
      final chatroom = await AdsyConnectService.getOrCreateChatRoom(
        _post!.user!.id.toString(),
      );

      debugPrint('🟢 Chat room created: ${chatroom['id']}');

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show chat interface (stack-deduplicated)
      if (mounted) {
        debugPrint('🔵 Opening chat...');
        AdsyConnectChatInterface.open(
          context,
          chatroomId: chatroom['id'].toString(),
          userId: _post!.user!.id.toString(),
          userName: _getSellerName(),
          userAvatar: _post!.user!.profilePicture,
          profession: 'Seller',
          isOnline: false,
        );
        debugPrint('🟢 Chat opened successfully!');
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 Error opening chat: $e');
      debugPrint('🔴 Stack trace: $stackTrace');

      // Close loading indicator if still showing
      if (mounted) {
        Navigator.pop(context);
      }

      // Check if it's an authentication error
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        if (mounted) {
          _showLoginRequiredDialog();
        }
      } else if (mounted) {
        AdsyToast.error(context, 'Failed to open chat. Please try again.');
      }
    }
  }

  String _getSellerName() {
    if (_post?.user == null) return 'Seller';

    final firstName = _post!.user!.firstName ?? '';
    final lastName = _post!.user!.lastName ?? '';
    final username = _post!.user!.username ?? 'Seller';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }
    return username;
  }

  void _navigateToUserPosts(UserDetails user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPostsScreen(
          userId: user.id ?? '',
          userName: user.displayName,
          userAvatar: user.profilePicture,
          userPhone: user.phone,
        ),
      ),
    );
  }

  Future<void> _sharePost() async {
    final post = _post;
    if (post == null) return;

    String? mediaImage;
    for (final media in post.medias ?? const <MediaItem>[]) {
      final image = media.image?.trim();
      if (image != null && image.isNotEmpty) {
        mediaImage = image;
        break;
      }
    }
    final shareImageUrl = mediaImage ?? post.categoryDetails?.image?.trim();

    final shareUrl =
        'https://adsyclub.com/classified-categories/details/${post.slug ?? post.id}';
    await AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: post.title,
        description: post.instructions,
        url: shareUrl,
        imageUrl: shareImageUrl,
        subject: post.title,
        eyebrow: 'Classified',
      ),
    );
  }

  void _showShareDialog() {
    _sharePost();
  }

  void _showReportDialog() {
    final post = _post;
    if (post == null) return;

    AdsyReportSheet.show(
      context,
      title: 'Report Service',
      prompt: 'Please select a reason for reporting this service.',
      options: AdsyReportSheet.postOptions,
      onSubmit: (option, details) {
        return _postService.reportPost(
          post.slug ?? post.id,
          option.value,
          details: details,
        );
      },
    );
  }

  void _contactProvider() {
    if (_post?.user == null) return;

    final user = _post!.user!;

    if (user.phone != null) {
      launchUrl(Uri.parse('tel:${user.phone}'));
    } else if (user.email != null) {
      launchUrl(Uri.parse('mailto:${user.email}'));
    } else if (user.whatsappLink != null) {
      launchUrl(Uri.parse(user.whatsappLink!));
    } else {
      AdsyToast.info(context, 'Contact information not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
        ),
        body: SkeletonLoader.detailPage(),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Post not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _post!.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _showShareDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/icons/share.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Gallery at Top (only if images exist)
            if (_post!.medias != null &&
                _post!.medias!.any((m) => m.image != null))
              _buildImageGallery(),

            if (_post!.medias != null &&
                _post!.medias!.any((m) => m.image != null))
              const SizedBox(height: 8),

            // Price and Title Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Text(
                    _post!.displayPrice,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title
                  Text(
                    _post!.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Meta info row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Location
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            [_post!.city, _post!.state]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Views
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_rounded,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${_post!.viewsCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Time
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _post!.getRelativeTime(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Report link (inline, no button background)
                      GestureDetector(
                        onTap: _showReportDialog,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.flag_outlined,
                                size: 13, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text(
                              'Report',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Description Section
            if (_post!.instructions != null) ...[
              Container(height: 1, color: Colors.grey.shade200),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Html(
                      data: _post!.instructions!,
                      onLinkTap: (url, attributes, element) {
                        UrlLauncherUtils.launchExternalUrl(url);
                      },
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(14),
                          lineHeight: const LineHeight(1.6),
                          color: const Color(0xFF374151),
                        ),
                        "p": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          display: Display.inline,
                        ),
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Seller Information Section
            Container(height: 1, color: Colors.grey.shade200),
            _buildProviderSection(),

            // Safety Tips Section
            Container(height: 1, color: Colors.grey.shade200),
            _buildSafetyTipsSection(),

            const SizedBox(height: 80), // Bottom padding for contact bar
          ],
        ),
      ),
      bottomNavigationBar: _buildContactBar(),
    );
  }

  Widget _buildImageGallery() {
    final images = _post!.medias?.where((m) => m.image != null).toList() ?? [];
    final hasImages = images.isNotEmpty;

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Main image
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              children: [
                if (!hasImages && _post!.categoryDetails?.image == null)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[800]!, Colors.grey[900]!],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, size: 64, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text(
                            'No Photo Uploaded',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemCount: hasImages ? images.length : 1,
                    itemBuilder: (context, index) {
                      final rawImageUrl = hasImages
                          ? images[index].image!
                          : _post!.categoryDetails!.image!;

                      // Convert to absolute URL using AppConfig
                      final imageUrl = AppConfig.getAbsoluteUrl(rawImageUrl);
                      debugPrint(
                          '🖼️ Classified Details - Raw: $rawImageUrl → Absolute: $imageUrl');

                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: AdsyLoadingIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[400]!),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint(
                              '❌ Classified Details - Image load error for $url: $error');
                          return Container(
                            color: Colors.grey[800],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_rounded,
                                    color: Colors.grey[400], size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'Image failed to load',
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                // Navigation buttons
                if (images.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (_currentImageIndex > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (_currentImageIndex < images.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // Page indicator (bottom center)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactBar() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _contactProvider,
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text('Call Now',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _openChatWithSeller,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                  backgroundColor: const Color(0xFFF0F9FF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/chat_icon.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTipsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      color: const Color(0xFFFFFBEB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_rounded,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'নিরাপত্তা পরামর্শ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSafetyTip('পরিচিত ও জনবহুল স্থানে দেখা করুন'),
          _buildSafetyTip('পণ্য ভালোভাবে দেখে ও যাচাই করে কিনুন'),
          _buildSafetyTip('পণ্য হাতে পাওয়ার আগে টাকা পরিশোধ করবেন না'),
          _buildSafetyTip('অগ্রিম বিকাশ/নগদ পাঠানোর অনুরোধ থেকে সতর্ক থাকুন'),
          _buildSafetyTip(
              'অপরিচিত লিংকে ক্লিক করা বা ব্যক্তিগত তথ্য শেয়ার করা থেকে বিরত থাকুন'),
          _buildSafetyTip('প্রতারণার শিকার হলে সাথে সাথে পুলিশকে জানান'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: const [
                Icon(Icons.phone_in_talk_rounded,
                    size: 15, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'জরুরি সহায়তার জন্য ৯৯৯ নম্বরে কল করুন',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF92400E),
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSection() {
    final user = _post!.user;

    if (user == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: const Text('Seller information not available'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seller Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Profile header with name and posted date
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                ),
                child: () {
                  final avatarUrl =
                      AppConfig.getAbsoluteUrl(user.profilePicture);

                  Widget fallback() {
                    final initial = user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : 'U';
                    return Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    );
                  }

                  if (avatarUrl.isEmpty) return fallback();

                  return ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return fallback();
                      },
                    ),
                  );
                }(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToUserPosts(user),
                      child: Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Posted ${_post!.getRelativeTime()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // AdsyClub profile icon with logo
              InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/business-network/profile',
                    arguments: {'userId': user.id},
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/favicon.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person_rounded,
                        size: 22,
                        color: Color(0xFF10B981),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Contact details in compact rows
          Column(
            children: [
              if (user.email != null)
                _buildCompactContactRow(
                  Icons.email_outlined,
                  user.email!,
                  const Color(0xFF6B7280),
                ),
              if (user.phone != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      _showPhone ? user.phone! : user.maskedPhone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _showPhone = !_showPhone),
                      child: Icon(
                        _showPhone
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
              if (user.createdAt != null) ...[
                const SizedBox(height: 6),
                _buildCompactContactRow(
                  Icons.calendar_today_outlined,
                  'Member since ${user.createdAt!.year}',
                  const Color(0xFF6B7280),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactContactRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Login Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to be logged in to chat with the seller.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please login or create an account to continue.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
