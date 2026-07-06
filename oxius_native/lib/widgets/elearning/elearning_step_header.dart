import 'package:flutter/material.dart';
import '../../services/translation_service.dart';

/// Shared header for each step inside the single eLearning card.
///
/// Renders a numbered/step badge, title + contextual subtitle, and a trailing
/// affordance ("Step n/4" while active, or the chosen value + Change while
/// collapsed) so all four steps read as one cohesive vertical stepper.
class ElearningStepHeader extends StatelessWidget {
  static const _slate100 = Color(0xFFF1F5F9);
  static const _slate500 = Color(0xFF64748B);
  static const _slate800 = Color(0xFF1E293B);
  static const _indigo = Color(0xFF6366F1);

  final int number;
  final int totalSteps;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final bool isDone;
  final String? collapsedValue;
  final VoidCallback onTapExpand;

  const ElearningStepHeader({
    super.key,
    required this.number,
    this.totalSteps = 4,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.isDone,
    required this.onTapExpand,
    this.collapsedValue,
  });

  @override
  Widget build(BuildContext context) {
    final collapsed = isDone && !isActive;

    return InkWell(
      onTap: collapsed ? onTapExpand : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            _buildBadge(collapsed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _slate800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    collapsed && (collapsedValue?.isNotEmpty ?? false)
                        ? collapsedValue!
                        : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                          collapsed ? FontWeight.w600 : FontWeight.w400,
                      color: collapsed ? _indigo : _slate500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildTrailing(collapsed),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(bool collapsed) {
    if (collapsed) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: _indigo,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
      );
    }
    if (isActive) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _indigo,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _indigo.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    // Locked / upcoming
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: _slate100,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _slate500,
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(bool collapsed) {
    if (collapsed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            TranslationService().t('el_change', fallback: 'Change'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _indigo,
            ),
          ),
          const Icon(Icons.expand_more_rounded, size: 18, color: _indigo),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${TranslationService().t('el_step', fallback: 'Step')} $number/$totalSteps',
        style: const TextStyle(
          fontSize: 11,
          color: _indigo,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
