import 'package:flutter/material.dart';
import '../../models/elearning_models.dart';
import '../../services/elearning_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import '../../services/translation_service.dart';
import 'elearning_step_header.dart';

class DivisionSelector extends StatefulWidget {
  final String? batch;
  final String? selectedDivision;
  final bool isExpanded;
  final VoidCallback onTapExpand;
  final Function(String) onSelectDivision;

  const DivisionSelector({
    super.key,
    this.batch,
    this.selectedDivision,
    required this.isExpanded,
    required this.onTapExpand,
    required this.onSelectDivision,
  });

  @override
  State<DivisionSelector> createState() => _DivisionSelectorState();
}

class _DivisionSelectorState extends State<DivisionSelector> {
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate500 = Color(0xFF64748B);
  static const _slate800 = Color(0xFF1E293B);
  static const _indigo = Color(0xFF6366F1);

  final TranslationService _i18n = TranslationService();

  List<Division> _divisions = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.batch != null) {
      _loadDivisions();
    }
  }

  @override
  void didUpdateWidget(DivisionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.batch != oldWidget.batch) {
      if (widget.batch != null) {
        _loadDivisions();
      } else {
        setState(() => _divisions = []);
      }
    }
  }

  Future<void> _loadDivisions() async {
    if (widget.batch == null) return;
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final divisions =
          await ElearningService.fetchDivisionsForBatch(widget.batch!);
      setState(() {
        _divisions = divisions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = _i18n.t('el_error_divisions',
            fallback: 'Failed to load divisions. Please try again.');
        _loading = false;
      });
    }
  }

  Map<String, Color> _getDivisionColors(String code) {
    final lowerCode = code.toLowerCase();
    if (lowerCode.contains('science')) {
      return {'bg': Colors.green.shade100, 'text': Colors.green.shade600};
    } else if (lowerCode.contains('humanities') || lowerCode.contains('arts')) {
      return {'bg': Colors.blue.shade100, 'text': Colors.blue.shade600};
    } else if (lowerCode.contains('commerce') ||
        lowerCode.contains('business')) {
      return {'bg': Colors.amber.shade100, 'text': Colors.amber.shade600};
    }
    return {'bg': Colors.grey.shade100, 'text': Colors.grey.shade600};
  }

  IconData _getDivisionIcon(String code) {
    final lowerCode = code.toLowerCase();
    if (lowerCode.contains('science')) {
      return Icons.science_rounded;
    } else if (lowerCode.contains('humanities') || lowerCode.contains('arts')) {
      return Icons.menu_book_rounded;
    } else if (lowerCode.contains('commerce') ||
        lowerCode.contains('business')) {
      return Icons.attach_money_rounded;
    }
    return Icons.account_tree_rounded;
  }

  Division? get _selectedDivisionItem {
    final code = widget.selectedDivision;
    if (code == null) return null;
    for (final division in _divisions) {
      if (division.code == code) return division;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.batch == null) return const SizedBox.shrink();

    final selectedDivision = _selectedDivisionItem;
    final isCollapsed = !widget.isExpanded && selectedDivision != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElearningStepHeader(
            number: 2,
            title: _i18n.t('el_choose_division', fallback: 'Choose division'),
            subtitle:
                _i18n.t('el_division_sub', fallback: 'Keep the syllabus focused'),
            icon: Icons.account_tree_rounded,
            isActive: widget.isExpanded,
            isDone: selectedDivision != null,
            collapsedValue: selectedDivision?.name,
            onTapExpand: widget.onTapExpand,
          ),
          if (!isCollapsed) ...[
            const SizedBox(height: 14),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: AdsyLoadingIndicator(),
                ),
              ),
            if (_error != null) _buildError(),
            if (!_loading && _error == null && _divisions.isEmpty)
              _buildEmpty(
                  _i18n.t('el_no_divisions', fallback: 'No divisions found')),
            if (!_loading && _error == null && _divisions.isNotEmpty)
              SizedBox(
                height: 132,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _divisions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final division = _divisions[index];
                      final isSelected =
                          widget.selectedDivision == division.code;
                      return _buildTile(division, isSelected);
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(String label) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 36, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            _error!,
            style: TextStyle(fontSize: 14, color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadDivisions,
            child: Text(_i18n.t('el_try_again', fallback: 'Try Again')),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Division division, bool isSelected) {
    final colors = _getDivisionColors(division.code);
    return GestureDetector(
      onTap: () => widget.onSelectDivision(division.code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 150,
        height: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _indigo.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _indigo : _slate200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors['bg'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getDivisionIcon(division.code),
                      size: 20, color: colors['text']),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      size: 22, color: _indigo)
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _slate200, width: 1.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              division.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? _indigo : _slate800,
              ),
            ),
            if (division.description.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                division.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: _slate500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
