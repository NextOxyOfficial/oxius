import 'package:flutter/material.dart';
import '../../models/elearning_models.dart';
import '../../services/elearning_service.dart';

class SubjectSelector extends StatefulWidget {
  final String? batch;
  final String? division;
  final String? selectedSubject;
  final Function(String) onSelectSubject;

  const SubjectSelector({
    super.key,
    this.batch,
    this.division,
    this.selectedSubject,
    required this.onSelectSubject,
  });

  @override
  State<SubjectSelector> createState() => _SubjectSelectorState();
}

class _SubjectSelectorState extends State<SubjectSelector> {
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

  @override
  Widget build(BuildContext context) {
    if (widget.division == null) return const SizedBox.shrink();

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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Your Subject',
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
                  'Step 3/4',
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

          // Subject grid
          if (!_loading && _error == null && _subjects.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive grid columns
                int crossAxisCount = 3; // Mobile default (small cards)
                if (constraints.maxWidth >= 1024) {
                  crossAxisCount = 4; // Desktop
                } else if (constraints.maxWidth >= 768) {
                  crossAxisCount = 3; // Tablet
                } else if (constraints.maxWidth >= 640) {
                  crossAxisCount = 2; // Large mobile
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.95, // Match batches and divisions
                  ),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    final isSelected = widget.selectedSubject == subject.code;
                    final colors = _getSubjectColors(index);

                    return InkWell(
                      onTap: () => widget.onSelectSubject(subject.code),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade500
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors['bg'],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.menu_book,
                                size: 20,
                                color: colors['text'],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Name
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                subject.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Selected indicator
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.blue.shade600,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Selected',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                  ],
                                ),
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
