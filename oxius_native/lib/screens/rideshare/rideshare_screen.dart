import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'rideshare_passenger_panel.dart';
import 'rideshare_driver_panel.dart';

class RideshareScreen extends StatefulWidget {
  const RideshareScreen({super.key});

  @override
  State<RideshareScreen> createState() => _RideshareScreenState();
}

class _RideshareScreenState extends State<RideshareScreen> {
  String _mode = 'passenger'; // 'passenger' or 'driver'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 4),
          _buildModeSwitch(),
          const SizedBox(height: 4),
          Expanded(
            child: _mode == 'passenger'
                ? const RidesharePassengerPanel()
                : const RideshareDriverPanel(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ride Share',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Book a ride or drive',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(
            context,
            _mode == 'driver'
                ? '/rideshare/driver-history'
                : '/rideshare/history',
          ),
          tooltip: 'History',
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        if (_mode == 'driver')
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/rideshare/vehicles'),
            tooltip: 'Vehicles',
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              label: 'Passenger',
              icon: Icons.person_rounded,
              isActive: _mode == 'passenger',
              onTap: () => setState(() => _mode = 'passenger'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeButton(
              label: 'Driver',
              icon: Icons.badge_rounded,
              isActive: _mode == 'driver',
              onTap: () => setState(() => _mode = 'driver'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
