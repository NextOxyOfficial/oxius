import 'package:flutter/material.dart';
import '../../models/elearning_models.dart';
import '../../services/elearning_service.dart';

class BatchSelector extends StatefulWidget {
  final String? selectedBatch;
  final Function(String) onSelectBatch;

  const BatchSelector({
    super.key,
    this.selectedBatch,
    required this.onSelectBatch,
  });

  @override
  State<BatchSelector> createState() => _BatchSelectorState();
}

class _BatchSelectorState extends State<BatchSelector> {
  List<Batch> _batches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final batches = await ElearningService.fetchBatches();

      setState(() {
        _batches = batches;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load batches. Please try again.';
        _loading = false;
      });
    }
  }

  Color _getBatchColor(String name) {
    if (name.toUpperCase().contains('SSC')) {
      return Colors.blue.shade100;
    } else if (name.toUpperCase().contains('HSC')) {
      return Colors.purple.shade100;
    }
    return Colors.grey.shade100;
  }

  Color _getBatchTextColor(String name) {
    if (name.toUpperCase().contains('SSC')) {
      return Colors.blue.shade700;
    } else if (name.toUpperCase().contains('HSC')) {
      return Colors.purple.shade700;
    }
    return Colors.grey.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Your Batch',
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
                  'Step 1/4',
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
                    onPressed: _loadBatches,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),

          // Batch grid
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
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.92, // Slightly taller to fit content
                  ),
                  itemCount: _batches.length,
                  itemBuilder: (context, index) {
                    final batch = _batches[index];
                    final isSelected = widget.selectedBatch == batch.code;

                    return InkWell(
                      onTap: () => widget.onSelectBatch(batch.code),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _getBatchColor(batch.name),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.menu_book,
                                size: 24,
                                color: _getBatchTextColor(batch.name),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Name
                            Text(
                              batch.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Description
                            Text(
                              batch.description,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
