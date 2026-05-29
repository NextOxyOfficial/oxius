import 'package:flutter/material.dart';
import '../../models/elearning_models.dart';
import '../../services/elearning_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

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
  static const _violet = Color(0xFF8B5CF6);

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
        setState(() {
          _divisions = [];
        });
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
        _error = 'Failed to load divisions. Please try again.';
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
      return Icons.science;
    } else if (lowerCode.contains('humanities') || lowerCode.contains('arts')) {
      return Icons.menu_book;
    } else if (lowerCode.contains('commerce') ||
        lowerCode.contains('business')) {
      return Icons.attach_money;
    }
    return Icons.school;
  }

  Division? get _selectedDivisionItem {
    final code = widget.selectedDivision;
    if (code == null) {
      return null;
    }

    for (final division in _divisions) {
      if (division.code == code) {
        return division;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.batch == null) return const SizedBox.shrink();

    final selectedDivision = _selectedDivisionItem;
    final isCollapsed = !widget.isExpanded && selectedDivision != null;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: isCollapsed ? widget.onTapExpand : null,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_indigo, _violet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_tree_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose division',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _slate800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Keep the syllabus focused',
                          style: TextStyle(
                            fontSize: 11,
                            color: _slate500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: _indigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Step 2/4',
                        style: TextStyle(
                          fontSize: 11,
                          color: _indigo,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isCollapsed) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.expand_more_rounded,
                          size: 18, color: _slate500),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Loading state
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: AdsyLoadingIndicator(),
              ),
            ),

          // Error state
          if (_error != null)
            Container(
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadDivisions,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),

          if (!_loading && _error == null && isCollapsed)
            _buildCollapsedSummary(selectedDivision),

          if (!_loading && _error == null && !isCollapsed)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _divisions.length,
              separatorBuilder: (context, index) =>
                  Divider(color: _slate200, height: 1),
              itemBuilder: (context, index) {
                final division = _divisions[index];
                final isSelected = widget.selectedDivision == division.code;
                final colors = _getDivisionColors(division.code);

                return InkWell(
                  onTap: () => widget.onSelectDivision(division.code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colors['bg'],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getDivisionIcon(division.code),
                            size: 18,
                            color: colors['text'],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                division.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? _indigo : _slate800,
                                ),
                              ),
                              if (division.description.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  division.description,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.4,
                                    color: _slate500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(left: 8, top: 2),
                            child: Icon(Icons.check_circle_rounded,
                                size: 18, color: _indigo),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsedSummary(Division division) {
    final colors = _getDivisionColors(division.code);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors['bg'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getDivisionIcon(division.code),
              size: 18,
              color: colors['text'],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  division.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _slate800,
                  ),
                ),
                if (division.description.isNotEmpty)
                  Text(
                    division.description,
                    style: const TextStyle(fontSize: 11, color: _slate500),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onTapExpand,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
