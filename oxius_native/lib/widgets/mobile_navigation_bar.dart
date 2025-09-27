import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/scroll_direction_service.dart';

class MobileNavigationBar extends StatefulWidget {
  final ScrollDirectionService? scrollService;
  
  const MobileNavigationBar({
    super.key,
    this.scrollService,
  });

  @override
  State<MobileNavigationBar> createState() => _MobileNavigationBarState();
}

class _MobileNavigationBarState extends State<MobileNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  ScrollDirectionService? _scrollService;
  final Set<String> _loadingButtons = <String>{};
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    
    // Create or use provided scroll service
    _scrollService = widget.scrollService ?? ScrollDirectionService();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 2), // Slide down by 2x height
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Only add listener if service is not disposed
    if (_scrollService != null && !_scrollService!.isDisposed) {
      _scrollService!.addListener(_onScrollDirectionChanged);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    
    // Remove listener before disposing
    if (_scrollService != null && !_scrollService!.isDisposed) {
      _scrollService!.removeListener(_onScrollDirectionChanged);
    }
    
    // Only dispose if we created the scroll service
    if (widget.scrollService == null && _scrollService != null) {
      _scrollService!.dispose();
    }
    
    _animationController.dispose();
    _scrollService = null;
    super.dispose();
  }

  void _onScrollDirectionChanged() {
    if (_disposed || _scrollService == null || _scrollService!.isDisposed) return;
    
    try {
      if (mounted) {
        if (_scrollService!.isVisible) {
          _animationController.reverse();
        } else {
          _animationController.forward();
        }
      }
    } catch (e) {
      debugPrint('MobileNavigationBar: Error in scroll direction change handler - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth < 640;
    
    if (!isMobile) return const SizedBox.shrink();

    return Container(
      height: 72,
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                isSelected: true,
                onTap: () => _handleNavigation('Home'),
              ),
              _buildNavItem(
                icon: Icons.category_outlined,
                selectedIcon: Icons.category,
                label: 'Categories',
                isSelected: false,
                onTap: () => _handleNavigation('Categories'),
              ),
              _buildNavItem(
                icon: Icons.add_circle_outline,
                selectedIcon: Icons.add_circle,
                label: 'Post',
                isSelected: false,
                isHighlighted: true,
                onTap: () => _handleNavigation('Post'),
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: 'Messages',
                isSelected: false,
                onTap: () => _handleNavigation('Messages'),
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                isSelected: false,
                onTap: () => _handleNavigation('Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loadingButtons.contains(label) ? null : () {
            if (_disposed) return;
            setState(() {
              _loadingButtons.add(label);
            });
            onTap();
            
            // Remove loading state after a delay
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!_disposed && mounted) {
                setState(() {
                  _loadingButtons.remove(label);
                });
              }
            });
          },
          borderRadius: BorderRadius.circular(36),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loadingButtons.contains(label))
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isHighlighted 
                            ? const Color(0xFF10B981)
                            : (isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade600),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: isHighlighted ? const EdgeInsets.all(6) : EdgeInsets.zero,
                    decoration: isHighlighted
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          )
                        : null,
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      color: isHighlighted
                          ? Colors.white
                          : (isSelected 
                              ? const Color(0xFF3B82F6)
                              : Colors.grey.shade600),
                      size: isHighlighted ? 20 : 24,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isHighlighted
                        ? const Color(0xFF10B981)
                        : (isSelected 
                            ? const Color(0xFF3B82F6)
                            : Colors.grey.shade600),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigation(String destination) {
    if (_disposed) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to $destination'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
  }
}