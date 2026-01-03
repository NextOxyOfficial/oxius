import 'package:flutter/material.dart';
import '../../services/user_suggestions_service.dart';
import '../../config/app_config.dart';
import '../../screens/business_network/profile_screen.dart';

class UserSuggestionsCard extends StatefulWidget {
  final VoidCallback? onRefresh;
  
  const UserSuggestionsCard({
    super.key,
    this.onRefresh,
  });

  @override
  State<UserSuggestionsCard> createState() => _UserSuggestionsCardState();
}

class _UserSuggestionsCardState extends State<UserSuggestionsCard> {
  List<Map<String, dynamic>> _allSuggestions = [];
  List<Map<String, dynamic>> _displayedSuggestions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final Map<String, bool> _followingStates = {};
  final Map<String, bool> _followingPending = {};

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    
    try {
      final suggestions = await UserSuggestionsService.getUserSuggestions();
      
      if (mounted) {
        setState(() {
          _allSuggestions = suggestions;
          _refreshDisplayedSuggestions();
        });
      }
    } catch (e) {
      print('Error loading suggestions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _refreshDisplayedSuggestions() {
    if (_allSuggestions.isEmpty) {
      _displayedSuggestions = [];
      return;
    }

    // Show random 2-3 users from all suggestions
    final isMobile = MediaQuery.of(context).size.width < 768;
    final count = isMobile ? 2 : 3;
    
    final shuffled = List<Map<String, dynamic>>.from(_allSuggestions)..shuffle();
    _displayedSuggestions = shuffled.take(count).toList();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      setState(() {
        _refreshDisplayedSuggestions();
        _isRefreshing = false;
      });
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic> user) async {
    final userId = user['id'].toString();
    final isFollowing = _followingStates[userId] ?? false;

    if (_followingPending[userId] == true) return;

    setState(() {
      _followingPending[userId] = true;
    });

    try {
      bool success;
      if (isFollowing) {
        success = await UserSuggestionsService.unfollowUser(userId);
      } else {
        success = await UserSuggestionsService.followUser(userId);
      }

      if (success && mounted) {
        setState(() {
          if (!isFollowing) {
            // User was followed - remove from suggestions list
            _allSuggestions.removeWhere((u) => u['id'].toString() == userId);
            _displayedSuggestions.removeWhere((u) => u['id'].toString() == userId);
            
            // If we have more suggestions, add a new one to display
            if (_displayedSuggestions.length < 2 && _allSuggestions.isNotEmpty) {
              final remaining = _allSuggestions.where((u) => 
                !_displayedSuggestions.any((d) => d['id'].toString() == u['id'].toString())
              ).toList();
              if (remaining.isNotEmpty) {
                remaining.shuffle();
                _displayedSuggestions.add(remaining.first);
              }
            }
          } else {
            // User was unfollowed - just update state
            _followingStates[userId] = false;
          }
        });
      }
    } catch (e) {
      print('Error toggling follow: $e');
    } finally {
      if (mounted) {
        setState(() {
          _followingPending[userId] = false;
        });
      }
    }
  }

  String _getUserDisplayName(Map<String, dynamic>? user) {
    if (user == null) return 'Unknown User';
    
    final firstName = (user['first_name'] ?? '').toString().trim();
    final lastName = (user['last_name'] ?? '').toString().trim();
    
    if (firstName.isEmpty && lastName.isEmpty) {
      return (user['username'] ?? 'Unknown User').toString();
    }
    
    return '$firstName $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue.shade50.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with modern gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade700,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.people, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'People you may know',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading || _isRefreshing ? null : _handleRefresh,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: _isLoading || _isRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(4),
            child: _isLoading
                ? _buildLoadingState(isMobile)
                : _displayedSuggestions.isEmpty
                    ? _buildEmptyState()
                    : _buildSuggestionsList(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: isMobile ? 0.72 : 0.68,
      children: List.generate(
        isMobile ? 2 : 3,
        (index) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isMobile ? 96 : 144,
                height: isMobile ? 96 : 144,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No suggestions available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(bool isMobile) {
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      // Increased aspect ratio to reduce card height
      childAspectRatio: isMobile ? 0.75 : 0.62,
      children: _displayedSuggestions.map((user) => _buildUserCard(user, isMobile)).toList(),
    );
  }

  String _getImageUrl(String? imageUrl) {
    // Use AppConfig.getAbsoluteUrl() which correctly uses mediaBaseUrl
    // This avoids /api/media/ issue and uses correct /media/ path
    return AppConfig.getAbsoluteUrl(imageUrl);
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isMobile) {
    final userId = (user['id'] ?? '').toString();
    final isFollowing = _followingStates[userId] ?? false;
    final isPending = _followingPending[userId] ?? false;
    final rawImageUrl = user['image']?.toString();
    final imageUrl = _getImageUrl(rawImageUrl);
    final mutualConnections = int.tryParse((user['mutual_connections'] ?? 0).toString()) ?? 0;
    
    // Debug logging
    if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
      print('📸 User: ${user['first_name']} ${user['last_name']}');
      print('🔗 Raw URL: $rawImageUrl');
      print('🌐 Absolute URL: $imageUrl');
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to user's profile
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: userId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade50, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile image - full width
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: isMobile ? 130 : 170,
                        fit: BoxFit.cover,
                        headers: const {
                          'User-Agent': 'Mozilla/5.0 (compatible; Flutter/3.0)',
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPlaceholderImage(isMobile);
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Image load error for: $imageUrl');
                          print('❌ Error: $error');
                          return _buildPlaceholderImage(isMobile);
                        },
                      )
                    : _buildPlaceholderImage(isMobile),
              ),

              const SizedBox(height: 6),

              // User name
              Text(
                _getUserDisplayName(user),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),

              // Profession
              if (user['profession'] != null && user['profession'].toString().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  user['profession'].toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],

              // Mutual connections
              if (mutualConnections > 0) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$mutualConnections mutual',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Follow button
              SizedBox(
                width: double.infinity,
                height: isMobile ? 28 : 32,
                child: ElevatedButton(
                  onPressed: isPending ? null : () => _toggleFollow(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.white : Colors.blue.shade600,
                    foregroundColor: isFollowing ? Colors.blue.shade700 : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: isFollowing
                          ? BorderSide(color: Colors.blue.shade200, width: 1.5)
                          : BorderSide.none,
                    ),
                    shadowColor: isFollowing ? Colors.transparent : Colors.blue.withOpacity(0.3),
                  ),
                  child: isPending
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              isFollowing ? Colors.blue.shade700 : Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 130 : 170,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade100,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Icon(
        Icons.person_rounded,
        size: isMobile ? 48 : 64,
        color: Colors.blue.shade300,
      ),
    );
  }
}
