import 'package:flutter/material.dart';
import '../../models/elearning_models.dart';
import '../../services/elearning_service.dart';

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
  static const _violet = Color(0xFF8B5CF6);

  List<Subject> _subjects = [];
  bool _loading = false;
  String? _error;

  // Color options for subjects
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
        setState(() {
          _subjects = [];
        });
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

      final subjects = await ElearningService.fetchSubjectsForDivision(widget.division!);

      setState(() {
        _subjects = subjects;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load subjects. Please try again.';
        _loading = false;
      });
    }
  }

  Map<String, Color> _getSubjectColors(int index) {
    return _colorOptions[index % _colorOptions.length];
  }

  Subject? get _selectedSubjectItem {
    final code = widget.selectedSubject;
    if (code == null) {
      return null;
    }

    for (final subject in _subjects) {
      if (subject.code == code) {
        return subject;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.division == null) return const SizedBox.shrink();

    final selectedSubject = _selectedSubjectItem;
    final isCollapsed = !widget.isExpanded && selectedSubject != null;

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
                      Icons.menu_book_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose subject',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _slate800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Open the exact lesson track',
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
                      'Step 3/4',
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
                    onPressed: _loadSubjects,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),

          // Empty state
          if (!_loading && _error == null && _subjects.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book,
                      size: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No subjects found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_loading && _error == null && isCollapsed)
            _buildCollapsedSummary(selectedSubject),

          if (!_loading && _error == null && _subjects.isNotEmpty && !isCollapsed)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subjects.length,
              separatorBuilder: (context, index) => Divider(color: _slate200, height: 1),
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                final isSelected = widget.selectedSubject == subject.code;
                final colors = _getSubjectColors(index);

                return InkWell(
                  onTap: () => widget.onSelectSubject(subject.code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors['bg'],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
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
                                subject.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? _indigo : _slate800,
                                ),
                              ),
                              if (subject.description.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  subject.description,
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

  Widget _buildCollapsedSummary(Subject subject) {
    final colors = _getSubjectColors(_subjects.indexOf(subject));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors['bg'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.menu_book_rounded,
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
                  subject.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _slate800,
                  ),
                ),
                if (subject.description.isNotEmpty)
                  Text(
                    subject.description,
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
