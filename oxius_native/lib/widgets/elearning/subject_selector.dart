import 'package:flutter/material.dart';
import '../../models/elearning_models.dart';
import '../../services/elearning_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import '../../services/translation_service.dart';
import 'elearning_step_header.dart';

class SubjectSelector extends StatefulWidget {
  final String? batch;
  final String? division;
  final String? selectedSubject;
  final bool isExpanded;
  final VoidCallback onTapExpand;
  final Function(String) onSelectSubject;

  const SubjectSelector({
    super.key,
    this.batch,
    this.division,
    this.selectedSubject,
    required this.isExpanded,
    required this.onTapExpand,
    required this.onSelectSubject,
  });

  @override
  State<SubjectSelector> createState() => _SubjectSelectorState();
}

class _SubjectSelectorState extends State<SubjectSelector> {
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate500 = Color(0xFF64748B);
  static const _slate800 = Color(0xFF1E293B);
  static const _indigo = Color(0xFF6366F1);

  final TranslationService _i18n = TranslationService();

  List<Subject> _subjects = [];
  bool _loading = false;
  String? _error;

  final List<Map<String, Color>> _colorOptions = [
    {'bg': Colors.blue.shade100, 'text': Colors.blue.shade600},
    {'bg': Colors.green.shade100, 'text': Colors.green.shade600},
    {'bg': Colors.purple.shade100, 'text': Colors.purple.shade600},
    {'bg': Colors.cyan.shade100, 'text': Colors.cyan.shade600},
    {'bg': Colors.amber.shade100, 'text': Colors.amber.shade600},
    {'bg': Colors.pink.shade100, 'text': Colors.pink.shade600},
    {'bg': Colors.teal.shade100, 'text': Colors.teal.shade600},
    {'bg': Colors.indigo.shade100, 'text': Colors.indigo.shade600},
    {'bg': Colors.orange.shade100, 'text': Colors.orange.shade600},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.division != null) {
      _loadSubjects();
    }
  }

  @override
  void didUpdateWidget(SubjectSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.division != oldWidget.division) {
      if (widget.division != null) {
        _loadSubjects();
      } else {
        setState(() => _subjects = []);
      }
    }
  }

  Future<void> _loadSubjects() async {
    if (widget.division == null) return;
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final subjects =
          await ElearningService.fetchSubjectsForDivision(widget.division!);
      setState(() {
        _subjects = subjects;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = _i18n.t('el_error_subjects',
            fallback: 'Failed to load subjects. Please try again.');
        _loading = false;
      });
    }
  }

  Map<String, Color> _getSubjectColors(int index) {
    return _colorOptions[index % _colorOptions.length];
  }

  Subject? get _selectedSubjectItem {
    final code = widget.selectedSubject;
    if (code == null) return null;
    for (final subject in _subjects) {
      if (subject.code == code) return subject;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.division == null) return const SizedBox.shrink();

    final selectedSubject = _selectedSubjectItem;
    final isCollapsed = !widget.isExpanded && selectedSubject != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElearningStepHeader(
            number: 3,
            title: _i18n.t('el_choose_subject', fallback: 'Choose subject'),
            subtitle: _i18n.t('el_subject_sub',
                fallback: 'Open the exact lesson track'),
            icon: Icons.menu_book_rounded,
            isActive: widget.isExpanded,
            isDone: selectedSubject != null,
            collapsedValue: selectedSubject?.name,
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
            if (!_loading && _error == null && _subjects.isEmpty)
              _buildEmpty(
                  _i18n.t('el_no_subjects', fallback: 'No subjects found')),
            if (!_loading && _error == null && _subjects.isNotEmpty)
              SizedBox(
                height: 132,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _subjects.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      final isSelected =
                          widget.selectedSubject == subject.code;
                      return _buildTile(subject, isSelected, index);
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
            Icon(Icons.menu_book_rounded,
                size: 36, color: Colors.grey.shade300),
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
            onPressed: _loadSubjects,
            child: Text(_i18n.t('el_try_again', fallback: 'Try Again')),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Subject subject, bool isSelected, int index) {
    final colors = _getSubjectColors(index);
    return GestureDetector(
      onTap: () => widget.onSelectSubject(subject.code),
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
                  child: Icon(Icons.menu_book_rounded,
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
              subject.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? _indigo : _slate800,
              ),
            ),
            if (subject.description.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                subject.description,
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
