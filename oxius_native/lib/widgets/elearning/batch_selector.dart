import 'package:flutter/material.dart';
import '../../models/elearning_models.dart';
import '../../services/elearning_service.dart';

class BatchSelector extends StatefulWidget {
  final String? selectedBatch;
  final bool isExpanded;
  final VoidCallback onTapExpand;
  final Function(String) onSelectBatch;

  const BatchSelector({
    super.key,
    this.selectedBatch,
    required this.isExpanded,
    required this.onTapExpand,
    required this.onSelectBatch,
  });

  @override
  State<BatchSelector> createState() => _BatchSelectorState();
}

class _BatchSelectorState extends State<BatchSelector> {
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate500 = Color(0xFF64748B);
  static const _slate800 = Color(0xFF1E293B);
  static const _indigo = Color(0xFF6366F1);
  static const _violet = Color(0xFF8B5CF6);

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

  Batch? get _selectedBatchItem {
    final code = widget.selectedBatch;
    if (code == null) {
      return null;
    }

    for (final batch in _batches) {
      if (batch.code == code) {
        return batch;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedBatch = _selectedBatchItem;
    final isCollapsed = !widget.isExpanded && selectedBatch != null;

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
                      Icons.school_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose batch',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _slate800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Start with your academic level',
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: _indigo.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Step 1/4',
                      style: TextStyle(
                        fontSize: 11,
                        color: _indigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isCollapsed) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.expand_more_rounded, size: 18, color: _slate500),
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

          if (!_loading && _error == null && isCollapsed)
            _buildCollapsedSummary(selectedBatch),

          if (!_loading && _error == null && !isCollapsed)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _batches.length,
              separatorBuilder: (context, index) => Divider(color: _slate200, height: 1),
              itemBuilder: (context, index) {
                final batch = _batches[index];
                final isSelected = widget.selectedBatch == batch.code;

                return InkWell(
                  onTap: () => widget.onSelectBatch(batch.code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _getBatchColor(batch.name),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: _getBatchTextColor(batch.name),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                batch.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? _indigo : _slate800,
                                ),
                              ),
                              if (batch.description.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  batch.description,
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
                            child: Icon(Icons.check_circle_rounded, size: 18, color: _indigo),
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

  Widget _buildCollapsedSummary(Batch batch) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _getBatchColor(batch.name),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 18,
              color: _getBatchTextColor(batch.name),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _slate800,
                  ),
                ),
                if (batch.description.isNotEmpty)
                  Text(
                    batch.description,
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
