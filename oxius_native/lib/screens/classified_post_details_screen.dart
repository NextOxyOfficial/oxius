import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
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
import 'adsy_connect_chat_interface.dart';
import 'user_posts_screen.dart';

class ClassifiedPostDetailsScreen extends StatefulWidget {
  final String postId;
  final String postSlug;

  const ClassifiedPostDetailsScreen({
    Key? key,
    required this.postId,
    required this.postSlug,
  }) : super(key: key);

  @override
  State<ClassifiedPostDetailsScreen> createState() => _ClassifiedPostDetailsScreenState();
}

class _ClassifiedPostDetailsScreenState extends State<ClassifiedPostDetailsScreen> {
  late final ClassifiedPostService _postService;
  
  ClassifiedPost? _post;
  bool _isLoading = true;
  bool _showPhone = false;
  int _currentImageIndex = 0;
  
  final PageController _pageController = PageController();

  bool _aiUserChoice = false;
  bool _aiSearching = false;
  bool _aiSearchDeclined = false;
  List<Map<String, dynamic>> _aiResults = [];
  String? _aiErrorMessage;

  String? _sanitizeAiValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();
    if (lower == 'null' || lower == 'n/a' || lower == 'na' || lower == 'none' || lower == 'unknown') {
      return null;
    }
    return text;
  }

  bool _isValidBangladeshPhone(String value) {
    final compact = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (compact.isEmpty) return false;
    if (compact.toLowerCase().contains('x')) return false;
    if (compact.contains('1234567') || compact.contains('12345678')) return false;

    final mobileIntl = RegExp(r'^\+8801\d{9}$');
    final mobileLocal = RegExp(r'^01\d{9}$');
    final landlineIntl = RegExp(r'^\+880\d{1,2}\d{6,8}$');
    final landlineIntlDash = RegExp(r'^\+880\-?\d{1,2}\-?\d{6,8}$');
    return mobileIntl.hasMatch(compact) || mobileLocal.hasMatch(compact) || landlineIntl.hasMatch(compact) || landlineIntlDash.hasMatch(value);
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool _isLikelyValidWebsite(String value) {
    final text = value.trim();
    if (text.isEmpty) return false;
    if (text.contains(' ')) return false;
    final lower = text.toLowerCase();
    if (lower.contains('example.com') || lower.contains('test.com')) return false;
    return lower.contains('.') && (lower.startsWith('http://') || lower.startsWith('https://') || RegExp(r'^[a-z0-9\-_.]+\.[a-z]{2,}').hasMatch(lower));
  }

  String _normalizeUrlForLaunch(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
    return 'https://$trimmed';
  }

  String? _extractEmailDomain(String email) {
    final trimmed = email.trim().toLowerCase();
    final at = trimmed.indexOf('@');
    if (at <= 0 || at >= trimmed.length - 1) return null;
    return trimmed.substring(at + 1);
  }

  String? _extractHostFromWebsite(String website) {
    final normalized = _normalizeUrlForLaunch(website);
    final uri = Uri.tryParse(normalized);
    final host = uri?.host.trim().toLowerCase();
    if (host == null || host.isEmpty) return null;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  bool _isWebsiteConsistentWithEmail({String? email, String? website}) {
    if (email == null || website == null) return true;
    final emailDomain = _extractEmailDomain(email);
    final websiteHost = _extractHostFromWebsite(website);
    if (emailDomain == null || websiteHost == null) return false;
    final cleanEmailDomain = emailDomain.startsWith('www.') ? emailDomain.substring(4) : emailDomain;
    return websiteHost == cleanEmailDomain || websiteHost.endsWith('.$cleanEmailDomain') || cleanEmailDomain.endsWith('.$websiteHost');
  }

  Map<String, dynamic> _sanitizeAiBusiness(Map<String, dynamic> business) {
    final sanitized = Map<String, dynamic>.from(business);

    final name = _sanitizeAiValue(sanitized['name']);
    if (name == null) return <String, dynamic>{};
    sanitized['name'] = name;

    final description = _sanitizeAiValue(sanitized['description']);
    if (description == null) {
      sanitized.remove('description');
    } else {
      sanitized['description'] = description;
    }

    final address = _sanitizeAiValue(sanitized['address']);
    if (address == null) {
      sanitized.remove('address');
    } else {
      sanitized['address'] = address;
    }

    final phone = _sanitizeAiValue(sanitized['phone']);
    if (phone == null || !_isValidBangladeshPhone(phone)) {
      sanitized.remove('phone');
    } else {
      sanitized['phone'] = phone;
    }

    final email = _sanitizeAiValue(sanitized['email']);
    if (email == null || !_isValidEmail(email)) {
      sanitized.remove('email');
    } else {
      sanitized['email'] = email;
    }

    final website = _sanitizeAiValue(sanitized['website']);
    if (website == null || !_isLikelyValidWebsite(website)) {
      sanitized.remove('website');
    } else {
      sanitized['website'] = website;
    }

    final finalEmail = sanitized['email'] as String?;
    final finalWebsite = sanitized['website'] as String?;
    if (!_isWebsiteConsistentWithEmail(email: finalEmail, website: finalWebsite)) {
      sanitized.remove('website');
    }

    return sanitized;
  }

  List<Map<String, dynamic>> _dropRepeatedFieldsAcrossAiResults(List<Map<String, dynamic>> items) {
    final phoneCount = <String, int>{};
    final websiteCount = <String, int>{};

    for (final item in items) {
      final p = item['phone'];
      if (p is String && p.trim().isNotEmpty) {
        phoneCount[p.trim()] = (phoneCount[p.trim()] ?? 0) + 1;
      }
      final w = item['website'];
      if (w is String && w.trim().isNotEmpty) {
        websiteCount[w.trim()] = (websiteCount[w.trim()] ?? 0) + 1;
      }
    }

    for (final item in items) {
      final p = item['phone'];
      if (p is String && (phoneCount[p.trim()] ?? 0) > 1) {
        item.remove('phone');
      }
      final w = item['website'];
      if (w is String && (websiteCount[w.trim()] ?? 0) > 1) {
        item.remove('website');
      }
    }

    return items;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Widget _buildCopyButton(String text, {IconData icon = Icons.copy_rounded}) {
    return InkWell(
      onTap: () => _copyToClipboard(text),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String value,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isLink ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _buildCopyButton(value),
      ],
    );
  }

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

  Future<void> _startAISearch() async {
    final post = _post;
    final businessType = post?.categoryDetails?.businessType;

    if (post == null || businessType == null || businessType.isEmpty) return;

    setState(() {
      _aiUserChoice = true;
      _aiSearching = true;
      _aiSearchDeclined = false;
      _aiResults = [];
      _aiErrorMessage = null;
    });

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/ai-business-finder/');
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'country': post.country ?? 'Bangladesh',
          'state': post.state ?? '',
          'city': post.city ?? '',
          'upazila': post.upazila ?? '',
          'business_type': businessType,
        }),
      );

      List<Map<String, dynamic>> businesses = [];
      String? errorMessage;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['businesses'] is List) {
          businesses = (decoded['businesses'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (decoded is List) {
          businesses = decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } else {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            if (decoded['error'] != null) {
              errorMessage = decoded['error']?.toString();
            } else if (decoded['detail'] != null) {
              errorMessage = decoded['detail']?.toString();
            }
          }
        } catch (_) {
          errorMessage = null;
        }

        errorMessage ??= 'Failed to fetch AI results (${response.statusCode})';
      }

      if (!mounted) return;
      setState(() {
        _aiSearching = false;
        final cleaned = businesses.map(_sanitizeAiBusiness).where((e) => e.isNotEmpty).toList();
        _aiResults = _dropRepeatedFieldsAcrossAiResults(cleaned);
        _aiErrorMessage = errorMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiSearching = false;
        _aiResults = [];
        _aiErrorMessage = e.toString();
      });
    }
  }

  void _declineAISearch() {
    setState(() {
      _aiUserChoice = true;
      _aiSearching = false;
      _aiSearchDeclined = true;
      _aiResults = [];
      _aiErrorMessage = null;
    });
  }

  Widget _buildAdsyAIBot() {
    final businessType = _post?.categoryDetails?.businessType;
    if (businessType == null || businessType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'AdsyAI Bot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: Color(0xFF064E3B),
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.smart_toy_rounded, size: 18, color: Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 12),
          if (!_aiUserChoice) ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 34, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 12),
            const Text(
              'আমি AdsyAI Bot\nআমি কি আপনার জন্য বিভিন্ন ওয়েবসাইট থেকে তথ্য খুঁজে বের করবো?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startAISearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'হ্যাঁ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _declineAISearch,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF111827),
                      side: BorderSide(color: Colors.grey.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'না',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_aiSearching) ...[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
              ),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'আমি AdsyAI Bot\nআপনার জন্য ইন্টারনেটে বিভিন্ন ওয়েবসাইট এ তথ্য খুঁজছি, একটু অপেক্ষা করুন...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
          if (_aiSearchDeclined) ...[
            const Icon(Icons.smart_toy_rounded, size: 44, color: Color(0xFF6B7280)),
            const SizedBox(height: 12),
            const Text(
              'আমি AdsyAI Bot\nঠিক আছে, আপনি যখন চাইবেন তখন আমি তথ্য খুঁজে দেখাবো।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _aiUserChoice = false;
                  _aiSearchDeclined = false;
                  _aiResults = [];
                  _aiErrorMessage = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
          if (_aiResults.isNotEmpty) ...[
            const Text(
              'আমি AdsyAI Bot\nআপনার জন্য ইন্টারনেট থেকে নিচের এই তথ্য গুলো খুঁজে বের করতে সক্ষম হয়েছি:',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ..._aiResults.asMap().entries.map((entry) {
              final index = entry.key;
              final result = entry.value;

              final name = _sanitizeAiValue(result['name']);
              if (name == null) return const SizedBox.shrink();

              final description = _sanitizeAiValue(result['description']);
              final address = _sanitizeAiValue(result['address']);
              final phone = _sanitizeAiValue(result['phone']);
              final email = _sanitizeAiValue(result['email']);
              final website = _sanitizeAiValue(result['website']);

              final copyAll = <String>[
                name,
                if (description != null) description,
                if (address != null) address,
                if (phone != null) phone,
                if (email != null) email,
                if (website != null) website,
              ].join('\n');

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${index + 1}. $name',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.1,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        _buildCopyButton(copyAll, icon: Icons.copy_all_rounded),
                      ],
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if (address != null) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        icon: Icons.location_on,
                        value: address,
                      ),
                    ],
                    if (phone != null) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        icon: Icons.phone,
                        value: phone,
                        onTap: () => UrlLauncherUtils.launchExternalUrl('tel:$phone'),
                      ),
                    ],
                    if (email != null) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        icon: Icons.email,
                        value: email,
                        onTap: () => UrlLauncherUtils.launchExternalUrl('mailto:$email'),
                      ),
                    ],
                    if (website != null) ...[
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        icon: Icons.language,
                        value: website,
                        isLink: true,
                        onTap: () => UrlLauncherUtils.launchExternalUrl(_normalizeUrlForLaunch(website)),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
          if (_aiUserChoice && !_aiSearching && !_aiSearchDeclined && _aiResults.isEmpty) ...[
            const Text(
              'আমি AdsyAI Bot\nদুঃখিত, আপনার জন্য ইন্টারনেট থেকে কোনো তথ্য খুঁজে পাইনি।',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (_aiErrorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _aiErrorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _aiUserChoice = false;
                  _aiSearchDeclined = false;
                  _aiResults = [];
                  _aiErrorMessage = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openChatWithSeller() async {
    // Check authentication first
    if (!AuthService.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    if (_post?.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller information not available'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    print('🔵 Chat button tapped!');
    print('🔵 Post data: ${_post?.id}');
    print('🔵 User ID: ${_post?.user?.id}');
    
    if (_post?.user?.id == null) {
      print('🔴 Seller information not available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller information not available'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    print('🔵 Opening chat with seller ID: ${_post!.user!.id}');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      ),
    );

    try {
      print('🔵 Creating/getting chat room...');
      // Get or create chat room with the seller
      final chatroom = await AdsyConnectService.getOrCreateChatRoom(
        _post!.user!.id.toString(),
      );

      print('🟢 Chat room created: ${chatroom['id']}');

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show chat interface in bottom sheet
      if (mounted) {
        print('🔵 Opening bottom sheet...');
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Chat interface
                  Expanded(
                    child: AdsyConnectChatInterface(
                      chatroomId: chatroom['id'].toString(),
                      userId: _post!.user!.id.toString(),
                      userName: _getSellerName(),
                      userAvatar: _post!.user!.profilePicture,
                      profession: 'Seller',
                      isOnline: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        print('🟢 Bottom sheet opened successfully!');
      }
    } catch (e, stackTrace) {
      print('🔴 Error opening chat: $e');
      print('🔴 Stack trace: $stackTrace');
      
      // Close loading indicator if still showing
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Check if it's an authentication error
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        if (mounted) {
          _showLoginRequiredDialog();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open chat. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
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

  String _getNumericServiceId() {
    if (_post == null) return '';
    
    int hash = 0;
    final str = _post!.id.toString();
    
    for (int i = 0; i < str.length; i++) {
      final char = str.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    
    final positiveHash = hash.abs();
    final numericId = positiveHash.toString().padLeft(10, '0');
    
    // Ensure we only return up to 10 digits
    return numericId.length > 10 ? numericId.substring(0, 10) : numericId;
  }

  void _sharePost() {
    if (_post == null) return;
    
    final shareUrl = 'https://adsyclub.com/classified-categories/details/${_post!.slug ?? _post!.id}';
    Share.share(
      '${_post!.title}\n\n$shareUrl',
      subject: _post!.title,
    );
  }

  void _showShareDialog() {
    if (_post == null) return;
    
    final shareUrl = 'https://adsyclub.com/classified-categories/details/${_post!.slug ?? _post!.id}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share this service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareUrl,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Share via', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildShareButton('Facebook', Icons.facebook, () {
                  launchUrl(Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$shareUrl'));
                  Navigator.pop(context);
                }),
                _buildShareButton('WhatsApp', Icons.message, () {
                  launchUrl(Uri.parse('https://api.whatsapp.com/send?text=${_post!.title} $shareUrl'));
                  Navigator.pop(context);
                }),
                _buildShareButton('Email', Icons.email, () {
                  launchUrl(Uri.parse('mailto:?subject=${_post!.title}&body=$shareUrl'));
                  Navigator.pop(context);
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    String? reportReason;
    final TextEditingController detailsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please select a reason for reporting this service:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  value: 'spam',
                  groupValue: reportReason,
                  onChanged: (value) => setDialogState(() => reportReason = value),
                  title: const Text('Spam or misleading', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'inappropriate',
                  groupValue: reportReason,
                  onChanged: (value) => setDialogState(() => reportReason = value),
                  title: const Text('Inappropriate content', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'fraud',
                  groupValue: reportReason,
                  onChanged: (value) => setDialogState(() => reportReason = value),
                  title: const Text('Fraudulent or scam', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'other',
                  groupValue: reportReason,
                  onChanged: (value) => setDialogState(() => reportReason = value),
                  title: const Text('Other', style: TextStyle(fontSize: 14)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    hintText: 'Additional details (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reportReason != null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted. We will review it shortly.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact information not available')),
      );
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
            if (_post!.medias != null && _post!.medias!.any((m) => m.image != null))
              _buildImageGallery(),
            
            if (_post!.medias != null && _post!.medias!.any((m) => m.image != null))
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
                          Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade600),
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
                          Icon(Icons.visibility_rounded, size: 14, color: Colors.grey.shade600),
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
                          Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade600),
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
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Report button
                  InkWell(
                    onTap: _showReportDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag_outlined, size: 14, color: Color(0xFFDC2626)),
                          const SizedBox(width: 6),
                          const Text(
                            'Report this listing',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Description Section
            if (_post!.instructions != null) ...[
              Container(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                      print('🖼️ Classified Details - Raw: $rawImageUrl → Absolute: $imageUrl');
                      
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          print('❌ Classified Details - Image load error for $url: $error');
                          return Container(
                            color: Colors.grey[800],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_rounded, color: Colors.grey[400], size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'Image failed to load',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
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
                          color: Colors.black.withOpacity(0.5),
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
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
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
                          color: Colors.black.withOpacity(0.5),
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
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
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

  Widget _buildPriceBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _post!.displayPrice,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _post!.getRelativeTime(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
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
            },
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
              color: Colors.black.withOpacity(0.08),
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
                label: const Text('Call Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/chat_icon.png',
                      width: 18,
                      height: 18,
                      color: const Color(0xFF10B981),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: const Color(0xFFFFFBEB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Safety Tips',
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
          _buildSafetyTip('Meet in a safe, public place'),
          _buildSafetyTip('Check the item before purchase'),
          _buildSafetyTip('Pay only after collecting the item'),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                height: 1.3,
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
                  color: const Color(0xFF10B981).withOpacity(0.1),
                ),
                child: () {
                  final avatarUrl = AppConfig.getAbsoluteUrl(user.profilePicture);

                  Widget fallback() {
                    final initial = user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U';
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
                    color: const Color(0xFF10B981).withOpacity(0.1),
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
                    Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
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
                        _showPhone ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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

  Widget _buildContactRow(IconData icon, String text, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
        ),
        if (trailing != null) trailing,
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
                color: const Color(0xFF10B981).withOpacity(0.1),
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
