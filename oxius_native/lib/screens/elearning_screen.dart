import 'package:flutter/material.dart';
import '../widgets/elearning/batch_selector.dart';
import '../widgets/elearning/batch_products.dart';
import '../widgets/elearning/division_selector.dart';
import '../widgets/elearning/subject_selector.dart';
import '../widgets/elearning/video_lessons.dart';

class ElearningScreen extends StatefulWidget {
  const ElearningScreen({super.key});

  @override
  State<ElearningScreen> createState() => _ElearningScreenState();
}

class _ElearningScreenState extends State<ElearningScreen> {
  String? _selectedBatch;
  String? _selectedDivision;
  String? _selectedSubject;

  void _handleBatchSelection(String batchCode) {
    setState(() {
      _selectedBatch = batchCode;
      // Reset subsequent selections
      _selectedDivision = null;
      _selectedSubject = null;
    });
  }

  void _handleDivisionSelection(String divisionCode) {
    setState(() {
      _selectedDivision = divisionCode;
      // Reset subject selection
      _selectedSubject = null;
    });
  }

  void _handleSubjectSelection(String subjectCode) {
    setState(() {
      _selectedSubject = subjectCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'E-Learning',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Compact Hero Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.indigo.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'E-Learning Platform',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Learn at your own pace',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade100,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Progress Indicator Pills - Compact
                  if (!isMobile)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildProgressStep(1, 'Batch', _selectedBatch != null),
                          _buildProgressArrow(),
                          _buildProgressStep(2, 'Division', _selectedDivision != null),
                          _buildProgressArrow(),
                          _buildProgressStep(3, 'Subject', _selectedSubject != null),
                          _buildProgressArrow(),
                          _buildProgressStep(4, 'Videos', _selectedSubject != null),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Content Section - Compact
            Container(
              constraints: const BoxConstraints(maxWidth: 1280),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 16,
                vertical: 12,
              ),
              child: Column(
                children: [
                  // Batch Selector
                  BatchSelector(
                    selectedBatch: _selectedBatch,
                    onSelectBatch: _handleBatchSelection,
                  ),

                  // Batch Products
                  BatchProducts(selectedBatch: _selectedBatch),

                  // Division Selector
                  DivisionSelector(
                    batch: _selectedBatch,
                    selectedDivision: _selectedDivision,
                    onSelectDivision: _handleDivisionSelection,
                  ),

                  // Subject Selector
                  SubjectSelector(
                    batch: _selectedBatch,
                    division: _selectedDivision,
                    selectedSubject: _selectedSubject,
                    onSelectSubject: _handleSubjectSelection,
                  ),

                  // Video Lessons
                  VideoLessons(subject: _selectedSubject),

                  // Compact Getting Started Info
                  if (_selectedBatch == null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Start Guide',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '1. Select batch → 2. Choose division → 3. Pick subject → 4. Watch videos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40), // Reduced bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(int number, String label, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.blue.shade600 : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right,
        size: 14,
        color: Colors.white.withOpacity(0.5),
      ),
    );
  }
}
