import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../business_network/adsypay_qr_modal.dart';

/// Header Actions - Inbox, QR Code, Profile
class HeaderActions extends StatefulWidget {
  const HeaderActions({super.key});

  @override
  State<HeaderActions> createState() => _HeaderActionsState();
}

class _HeaderActionsState extends State<HeaderActions> {
  bool showQr = false;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final isAuthenticated = AuthService.isAuthenticated;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.045).clamp(18.0, 22.0);

    if (!isAuthenticated || user == null) {
      return _buildLoginButton(iconSize);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Inbox Button
        IconButton(
          icon: Icon(
            Icons.mark_email_unread_outlined,
            size: iconSize,
            color: const Color(0xFF3B82F6),
          ),
          onPressed: () => Navigator.pushNamed(context, '/inbox'),
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
        ),
        
        const SizedBox(width: 2),
        
        // QR Code Button
        IconButton(
          icon: Container(
            width: iconSize * 1.3,
            height: iconSize * 1.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade50,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              size: iconSize * 0.65,
              color: Colors.green.shade600,
            ),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AdsyPayQrModal(
                qrData: 'adsypay://pay/${user.id}',
                title: '${user.firstName ?? user.username}\'s QR',
              ),
            );
          },
          padding: const EdgeInsets.all(3),
          constraints: const BoxConstraints(),
        ),
        
        const SizedBox(width: 2),
        
        // User Avatar
        _buildUserAvatar(user, iconSize),
      ],
    );
  }

  Widget _buildLoginButton(double iconSize) {
    return IconButton(
      icon: Container(
        width: iconSize * 1.4,
        height: iconSize * 1.4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(
          Icons.person,
          size: iconSize * 0.75,
          color: Colors.grey.shade600,
        ),
      ),
      onPressed: () => Navigator.pushNamed(context, '/login'),
      padding: const EdgeInsets.all(3),
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildUserAvatar(user, double iconSize) {
    final avatarSize = iconSize * 1.4;
    final isPro = user.isPro ?? false;
    final isVerified = user.isVerified ?? false;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isPro ? Colors.indigo.shade500 : Colors.white,
            width: 2,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar Image
            ClipOval(
              child: user.profilePicture != null && user.profilePicture!.isNotEmpty
                  ? Image.network(
                      user.profilePicture!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarInitial(user, avatarSize),
                    )
                  : _buildAvatarInitial(user, avatarSize),
            ),
            
            // Pro Badge
            if (isPro)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade500, Colors.purple.shade600],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, size: avatarSize * 0.25, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        'Pro',
                        style: TextStyle(
                          fontSize: avatarSize * 0.22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Verified Badge
            if (isVerified)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: avatarSize * 0.4,
                  height: avatarSize * 0.4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified,
                    size: avatarSize * 0.35,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarInitial(user, double size) {
    final initial = (user.firstName?.isNotEmpty == true
            ? user.firstName![0]
            : user.username?.isNotEmpty == true
                ? user.username![0]
                : 'U')
        .toUpperCase();

    return Container(
      color: Colors.teal.shade400,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
