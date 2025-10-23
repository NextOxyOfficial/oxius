import 'package:flutter/material.dart';
import '../../models/elearning_models.dart';
import '../../services/elearning_service.dart';

class DivisionSelector extends StatefulWidget {
  final String? batch;
  final String? selectedDivision;
  final Function(String) onSelectDivision;

  const DivisionSelector({
    super.key,
    this.batch,
    this.selectedDivision,
    required this.onSelectDivision,
  });

  @override
  State<DivisionSelector> createState() => _DivisionSelectorState();
}

class _DivisionSelectorState extends State<DivisionSelector> {
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

      final divisions = await ElearningService.fetchDivisionsForBatch(widget.batch!);

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
    } else if (lowerCode.contains('commerce') || lowerCode.contains('business')) {
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
    } else if (lowerCode.contains('commerce') || lowerCode.contains('business')) {
      return Icons.attach_money;
    }
    return Icons.school;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.batch == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Your Division',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Step 2/4',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Loading state
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
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

          // Division grid
          if (!_loading && _error == null)
            LayoutBuilder(
              builder: (context, constraints) {
                // Compact grid - 3 items per row on all screen sizes
                int crossAxisCount = 3;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 0.92, // Slightly taller to fit content
                  ),
                  itemCount: _divisions.length,
                  itemBuilder: (context, index) {
                    final division = _divisions[index];
                    final isSelected = widget.selectedDivision == division.code;
                    final colors = _getDivisionColors(division.code);

                    return InkWell(
                      onTap: () => widget.onSelectDivision(division.code),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade500
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon on top
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors['bg'],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getDivisionIcon(division.code),
                                size: 24,
                                color: colors['icon'],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Text below
                            Text(
                              division.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (division.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                division.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
