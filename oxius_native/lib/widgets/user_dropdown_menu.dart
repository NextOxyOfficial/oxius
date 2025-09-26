import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserDropdownMenu extends StatefulWidget {
  final User? user;
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onLogout;
  final VoidCallback onUpgradeToPro;
  final VoidCallback onManageSubscription;
  final Function(String) onNavigate;

  const UserDropdownMenu({
    Key? key,
    required this.user,
    required this.isOpen,
    required this.onClose,
    required this.onLogout,
    required this.onUpgradeToPro,
    required this.onManageSubscription,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<UserDropdownMenu> createState() => _UserDropdownMenuState();
}

class _UserDropdownMenuState extends State<UserDropdownMenu>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(UserDropdownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 640;

    return Positioned(
      top: 48, // top-12 in Tailwind (12 * 4 = 48px)
      right: 0,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: isSmallScreen ? 288 : 320, // w-72 sm:w-80
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated gradient accent
                      Container(
                        height: 4,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF818CF8), // primary-400
                              Color(0xFF6366F1), // indigo-500
                              Color(0xFF8B5CF6), // primary-600
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                      ),
                      
                      // User Profile Section
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Container(),
                      ),

                      // Membership Section
                      _buildMembershipSection(),

                      // Main Navigation Links
                      _buildNavigationSection(),

                      // Settings & Logout
                      _buildSettingsSection(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMembershipSection() {
    final isPro = widget.user?.userType == 'pro' || widget.user?.isSuperuser == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPro 
              ? const Color(0xFFC7D2FE) // indigo-200
              : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Top Section: Current Plan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isPro 
                  ? const Color(0xFFEEF2FF) // indigo-50
                  : const Color(0xFFF8FAFC), // slate-50
                gradient: isPro 
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFEEF2FF), // indigo-50
                        Color(0xFFDBEAFE), // blue-50
                      ],
                    )
                  : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isPro 
                      ? const Color(0xFFE0E7FF) // indigo-100
                      : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPro ? Icons.star : Icons.person,
                        size: 16,
                        color: isPro 
                          ? const Color(0xFF4F46E5) // indigo-600
                          : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPro ? 'Premium Access' : 'Current Plan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isPro 
                            ? const Color(0xFF3730A3) // indigo-700
                            : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: isPro 
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF6366F1), // indigo-500
                              Color(0xFF2563EB), // blue-600
                            ],
                          )
                        : null,
                      color: isPro ? null : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPro) ...[
                          const Icon(
                            Icons.shield_outlined,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isPro ? 'PRO' : 'FREE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isPro ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Section: Action
            GestureDetector(
              onTap: isPro ? widget.onManageSubscription : widget.onUpgradeToPro,
              child: Container(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPro 
                            ? [
                                const Color(0xFF6366F1).withOpacity(0.1),
                                const Color(0xFF2563EB).withOpacity(0.1),
                              ]
                            : [
                                const Color(0xFFEEF2FF),
                                const Color(0xFFF3E8FF),
                              ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPro 
                            ? const Color(0xFF6366F1).withOpacity(0.3)
                            : const Color(0xFFC7D2FE).withOpacity(0.8),
                        ),
                      ),
                      child: Icon(
                        isPro ? Icons.shield_outlined : Icons.star,
                        size: 20,
                        color: isPro 
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isPro ? 'Pro Member' : 'Upgrade to Pro',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              if (!isPro) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFBBF24), // amber-400
                                        Color(0xFFF59E0B), // amber-500
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '+',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPro 
                              ? 'Valid until ${_formatDate(DateTime.now().add(const Duration(days: 30)))}'
                              : 'Unlock premium features',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Toggle Switch
                    Container(
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: isPro 
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF6366F1), // indigo-400
                                Color(0xFF2563EB), // blue-500
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade200,
                                Colors.grey.shade300,
                              ],
                            ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Align(
                          alignment: isPro ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildNavigationSection() {
    final navigationItems = [
      {
        'label': 'Business Network',
        'icon': Icons.network_check,
        'color': const Color(0xFFEA580C), // orange-600
        'bgGradient': const LinearGradient(colors: [Color(0xFFFED7AA), Color(0xFFFEF3C7)]), // orange-100 to orange-50
        'borderColor': const Color(0xFFFED7AA), // orange-200
        'route': '/business-network',
      },
      {
        'label': 'Adsy News',
        'icon': Icons.newspaper,
        'color': const Color(0xFF9333EA), // purple-600
        'bgGradient': const LinearGradient(colors: [Color(0xFFE9D5FF), Color(0xFFFAF5FF)]), // purple-100 to purple-50
        'borderColor': const Color(0xFFE9D5FF), // purple-200
        'route': '/adsy-news',
      },
      {
        'label': 'Ad',
        'icon': Icons.campaign,
        'color': const Color(0xFF059669), // emerald-600
        'bgGradient': const LinearGradient(colors: [Color(0xFFA7F3D0), Color(0xFFECFDF5)]), // emerald-100 to emerald-50
        'borderColor': const Color(0xFFA7F3D0), // emerald-200
        'route': '/my-classified-services',
        'badge': {'type': 'free', 'text': 'FREE'},
      },
      {
        'label': 'eShop Manager',
        'icon': Icons.shopping_bag,
        'color': const Color(0xFF2563EB), // blue-600
        'bgGradient': const LinearGradient(colors: [Color(0xFFBFDBFE), Color(0xFFEFF6FF)]), // blue-100 to blue-50
        'borderColor': const Color(0xFFBFDBFE), // blue-200
        'route': '/shop-manager',
        'badge': {'type': 'pro', 'text': 'PRO'},
      },
      {
        'label': 'Adsy Pay',
        'icon': Icons.payments,
        'color': const Color(0xFF059669), // emerald-600
        'bgGradient': const LinearGradient(colors: [Color(0xFFA7F3D0), Color(0xFFECFDF5)]), // emerald-100 to emerald-50
        'borderColor': const Color(0xFFA7F3D0), // emerald-200
        'route': '/deposit-withdraw',
      },
      {
        'label': 'Mobile Recharge',
        'icon': Icons.phone_android,
        'color': const Color(0xFFEA580C), // orange-600
        'bgGradient': const LinearGradient(colors: [Color(0xFFFED7AA), Color(0xFFFEF3C7)]), // orange-100 to orange-50
        'borderColor': const Color(0xFFFED7AA), // orange-200
        'route': '/mobile-recharge',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: navigationItems.length,
        itemBuilder: (context, index) {
          final item = navigationItems[index];
          return GestureDetector(
            onTap: () {
              widget.onNavigate(item['route'] as String);
              widget.onClose();
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: item['bgGradient'] as LinearGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item['borderColor'] as Color,
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Badge
                  if (item['badge'] != null) ...[
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: (item['badge'] as Map)['type'] == 'pro'
                              ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF2563EB)])
                              : const LinearGradient(colors: [Color(0xFF64748B), Color(0xFF475569)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if ((item['badge'] as Map)['type'] == 'pro') ...[
                                const Icon(
                                  Icons.star,
                                  size: 8,
                                  color: Color(0xFFFDE047), // yellow-200
                                ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                (item['badge'] as Map)['text'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: item['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade100.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Settings and Support Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Settings
              GestureDetector(
                onTap: () {
                  widget.onNavigate('/settings');
                  widget.onClose();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.settings,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Support/Verification
              GestureDetector(
                onTap: () {
                  widget.onNavigate('/upload-center');
                  widget.onClose();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.upload_file,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Verification',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Logout Button
          GestureDetector(
            onTap: widget.onLogout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout,
                      size: 16,
                      color: Colors.red.shade500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade600,
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}