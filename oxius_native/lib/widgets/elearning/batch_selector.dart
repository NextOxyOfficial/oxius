import 'package:flutter/material.dart';
import '../../models/elearning_models.dart';
import '../../services/elearning_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import '../../services/translation_service.dart';
import 'elearning_step_header.dart';

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

  final TranslationService _i18n = TranslationService();

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
        _error = _i18n.t('el_error_batches',
            fallback: 'Failed to load batches. Please try again.');
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
    if (code == null) return null;
    for (final batch in _batches) {
      if (batch.code == code) return batch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedBatch = _selectedBatchItem;
    final isCollapsed = !widget.isExpanded && selectedBatch != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElearningStepHeader(
            number: 1,
            title: _i18n.t('el_choose_batch', fallback: 'Choose batch'),
            subtitle: _i18n.t('el_batch_sub',
                fallback: 'Start with your academic level'),
            icon: Icons.school_rounded,
            isActive: widget.isExpanded,
            isDone: selectedBatch != null,
            collapsedValue: selectedBatch?.name,
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
            if (!_loading && _error == null)
              SizedBox(
                height: 132,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _batches.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final batch = _batches[index];
                      final isSelected = widget.selectedBatch == batch.code;
                      return _buildBatchTile(batch, isSelected);
                    },
                  ),
                ),
              ),
          ],
        ],
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
            onPressed: _loadBatches,
            child: Text(_i18n.t('el_try_again', fallback: 'Try Again')),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchTile(Batch batch, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onSelectBatch(batch.code),
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
                    color: _getBatchColor(batch.name),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 20,
                    color: _getBatchTextColor(batch.name),
                  ),
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
              batch.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? _indigo : _slate800,
              ),
            ),
            if (batch.description.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                batch.description,
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
