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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header with gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: _buildHeader(),
              ),
              
              // Content with rounded top
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Compact Hero Section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 4 : 16,
                            vertical: isMobile ? 12 : 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'E-Learning Platform',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Learn anytime, anywhere',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Content Section
                        Container(
                          constraints: const BoxConstraints(maxWidth: 1280),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 1 : 16,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          
          // Title
          const Expanded(
            child: Text(
              'eLearning',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          
          // Info Icon
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
            onPressed: () {
              // Show info dialog
            },
            tooltip: 'Information',
          ),
        ],
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
