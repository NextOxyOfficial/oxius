import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/elearning/batch_selector.dart';
import '../widgets/elearning/division_selector.dart';
import '../widgets/elearning/subject_selector.dart';
import '../widgets/elearning/video_lessons.dart';

class ElearningScreen extends StatefulWidget {
  const ElearningScreen({super.key});

  @override
  State<ElearningScreen> createState() => _ElearningScreenState();
}

class _ElearningScreenState extends State<ElearningScreen> {
  static const _slate50 = Color(0xFFF8FAFC);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate500 = Color(0xFF64748B);
  static const _slate800 = Color(0xFF1E293B);
  static const _indigo = Color(0xFF6366F1);
  static const _violet = Color(0xFF8B5CF6);

  String? _selectedBatch;
  String? _selectedDivision;
  String? _selectedSubject;
  String _expandedStep = 'batch';

  void _handleBatchSelection(String batchCode) {
    setState(() {
      _selectedBatch = batchCode;
      // Reset subsequent selections
      _selectedDivision = null;
      _selectedSubject = null;
      _expandedStep = 'division';
    });
  }

  void _handleDivisionSelection(String divisionCode) {
    setState(() {
      _selectedDivision = divisionCode;
      // Reset subject selection
      _selectedSubject = null;
      _expandedStep = 'subject';
    });
  }

  void _handleSubjectSelection(String subjectCode) {
    setState(() {
      _selectedSubject = subjectCode;
      _expandedStep = 'videos';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final horizontalPadding = isMobile ? 4.0 : 12.0;

    return Scaffold(
      backgroundColor: _slate50,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(),
                  BatchSelector(
                    selectedBatch: _selectedBatch,
                    isExpanded: _expandedStep == 'batch',
                    onTapExpand: () => setState(() => _expandedStep = 'batch'),
                    onSelectBatch: _handleBatchSelection,
                  ),
                  DivisionSelector(
                    batch: _selectedBatch,
                    selectedDivision: _selectedDivision,
                    isExpanded: _expandedStep == 'division',
                    onTapExpand: () => setState(() => _expandedStep = 'division'),
                    onSelectDivision: _handleDivisionSelection,
                  ),
                  SubjectSelector(
                    batch: _selectedBatch,
                    division: _selectedDivision,
                    selectedSubject: _selectedSubject,
                    isExpanded: _expandedStep == 'subject',
                    onTapExpand: () => setState(() => _expandedStep = 'subject'),
                    onSelectSubject: _handleSubjectSelection,
                  ),
                  VideoLessons(subject: _selectedSubject),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: _slate800,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_indigo, _violet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'eLearning',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _slate800,
                ),
              ),
              Text(
                'Structured study path',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _slate500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'How it works',
          onPressed: _showLearningInfo,
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _slate100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: _slate500,
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _slate200),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_indigo, _violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _indigo.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Follow a focused study flow',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick your batch, narrow the syllabus, then jump straight into lessons.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLearningInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'How eLearning works',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Start with your batch, narrow it down by division and subject, then continue directly into the lesson videos. Recommended books appear after the study path so they do not interrupt the learning flow.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: _slate500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
