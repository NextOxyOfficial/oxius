import 'package:flutter/material.dart';
import '../../services/support_ticket_service.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final ticket = await SupportTicketService.createTicket(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (ticket != null) {
          AdsyToast.success(context, 'Support ticket created successfully!');
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          AdsyToast.error(context, 'Failed to create ticket. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AdsyToast.error(context, 'কিছু একটা সমস্যা হয়েছে');
      }
    }
  }

  static const _ink = Color(0xFF111827);
  static const _slate = Color(0xFF64748B);

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _ink, width: 1.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _fieldLabel(String label, String helper) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 2),
        Text(helper,
            style: const TextStyle(fontSize: 11.5, color: _slate, height: 1.4)),
      ],
    );
  }

  Widget _stepRow(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(number,
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w800, color: _ink)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11.5, color: _slate, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'সাপোর্ট টিকিট',
          style: TextStyle(
            color: _ink,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Intro — what this is and what to expect.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                    child: const Icon(Icons.support_agent_rounded,
                        size: 23, color: Color(0xFF334155)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('কী সমস্যায় পড়েছেন?',
                            style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                letterSpacing: -0.2)),
                        SizedBox(height: 3),
                        Text(
                          'সমস্যাটি লিখে জানান — আমাদের সাপোর্ট টিম ২৪ ঘণ্টার মধ্যে উত্তর দেবে। উত্তরটি এই অ্যাপের Support ট্যাবেই পাবেন।',
                          style: TextStyle(
                              fontSize: 12.5, color: _slate, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 8,
              margin: const EdgeInsets.symmetric(vertical: 16),
              color: const Color(0xFFF8FAFC),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('বিষয়', 'এক লাইনে সমস্যাটা কী — যেমন "টাকা উত্তোলন হচ্ছে না"'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration:
                        _fieldDecoration('সংক্ষেপে সমস্যার বিষয় লিখুন'),
                    style: const TextStyle(fontSize: 14, height: 1.35),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'বিষয় লিখুন';
                      }
                      if (value.trim().length < 5) {
                        return 'বিষয় কমপক্ষে ৫ অক্ষরের হতে হবে';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _fieldLabel('বিস্তারিত',
                      'কখন, কোন পেজে, কী করতে গিয়ে সমস্যা হয়েছে — যত বিস্তারিত লিখবেন তত দ্রুত সমাধান পাবেন'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 7,
                    decoration:
                        _fieldDecoration('সমস্যাটি বিস্তারিত লিখুন...'),
                    style: const TextStyle(fontSize: 14, height: 1.45),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'বিস্তারিত লিখুন';
                      }
                      if (value.trim().length < 20) {
                        return 'কমপক্ষে ২০ অক্ষরে সমস্যাটি বর্ণনা করুন';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Submit — ink, AdsyConnect-style
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE2E8F0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: AdsyLoadingIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Text(
                              'টিকিট জমা দিন',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 8,
              margin: const EdgeInsets.symmetric(vertical: 16),
              color: const Color(0xFFF8FAFC),
            ),

            // How it works — simple 3 steps.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('যেভাবে কাজ করে',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 10),
                  _stepRow('১', 'টিকিট জমা দিন',
                      'বিষয় ও বিস্তারিত লিখে জমা দিলেই টিকিট তৈরি হয়ে যাবে।'),
                  _stepRow('২', 'টিম রিভিউ করবে',
                      'আমাদের সাপোর্ট টিম আপনার সমস্যাটি যাচাই করবে।'),
                  _stepRow('৩', '২৪ ঘণ্টার মধ্যে উত্তর',
                      'Support ট্যাবে উত্তর আসবে, নোটিফিকেশনও পাবেন।'),
                ],
              ),
            ),

            // Safe area bottom padding for devices with gesture navigation
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }
}
