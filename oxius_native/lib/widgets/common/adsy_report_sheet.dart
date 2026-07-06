import 'package:flutter/material.dart';

import 'adsy_loading.dart';
import 'adsy_toast.dart';

class AdsyReportOption {
  final String label;
  final String value;

  const AdsyReportOption({
    required this.label,
    required this.value,
  });
}

class AdsyReportSheet {
  static const List<AdsyReportOption> postOptions = [
    AdsyReportOption(label: 'Spam or misleading', value: 'spam'),
    AdsyReportOption(label: 'Inappropriate content', value: 'inappropriate'),
    AdsyReportOption(label: 'Harassment or hate speech', value: 'harassment'),
    AdsyReportOption(label: 'Violence or dangerous content', value: 'violence'),
    AdsyReportOption(label: 'Fraudulent or scam', value: 'fraud'),
    AdsyReportOption(label: 'Other', value: 'other'),
  ];

  static const List<AdsyReportOption> saleOptions = [
    AdsyReportOption(label: 'Spam or misleading', value: 'spam'),
    AdsyReportOption(label: 'Inappropriate content', value: 'inappropriate'),
    AdsyReportOption(label: 'Duplicate listing', value: 'duplicate'),
    AdsyReportOption(label: 'Fraudulent', value: 'fraud'),
    AdsyReportOption(label: 'Other', value: 'other'),
  ];

  static const List<AdsyReportOption> userOptions = [
    AdsyReportOption(label: 'Spam', value: 'spam'),
    AdsyReportOption(label: 'Harassment', value: 'harassment'),
    AdsyReportOption(label: 'Inappropriate content', value: 'inappropriate'),
    AdsyReportOption(label: 'Scam or fraud', value: 'scam'),
    AdsyReportOption(label: 'Other', value: 'other'),
  ];

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String prompt,
    required Future<bool> Function(AdsyReportOption option, String details)
        onSubmit,
    List<AdsyReportOption> options = postOptions,
    String detailsHint = 'Additional details (optional)',
    String successMessage = 'Report submitted. We will review it shortly.',
    String failureMessage = 'Failed to submit report. Please try again.',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AdsyReportSheetContent(
        title: title,
        prompt: prompt,
        options: options,
        detailsHint: detailsHint,
        onSubmit: onSubmit,
        successMessage: successMessage,
        failureMessage: failureMessage,
      ),
    );
  }
}

class _AdsyReportSheetContent extends StatefulWidget {
  final String title;
  final String prompt;
  final List<AdsyReportOption> options;
  final String detailsHint;
  final Future<bool> Function(AdsyReportOption option, String details) onSubmit;
  final String successMessage;
  final String failureMessage;

  const _AdsyReportSheetContent({
    required this.title,
    required this.prompt,
    required this.options,
    required this.detailsHint,
    required this.onSubmit,
    required this.successMessage,
    required this.failureMessage,
  });

  @override
  State<_AdsyReportSheetContent> createState() =>
      _AdsyReportSheetContentState();
}

class _AdsyReportSheetContentState extends State<_AdsyReportSheetContent> {
  final TextEditingController _detailsController = TextEditingController();
  AdsyReportOption? _selectedOption;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final option = _selectedOption;
    if (option == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);

    final success = await widget.onSubmit(option, _detailsController.text);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    navigator.pop();

    if (success) {
      AdsyToast.success(context, widget.successMessage);
    } else {
      AdsyToast.error(context, widget.failureMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Color(0xFFF97316),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.prompt,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 10),
              RadioGroup<AdsyReportOption>(
                groupValue: _selectedOption,
                onChanged: (value) {
                  if (_isSubmitting) return;
                  setState(() => _selectedOption = value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in widget.options)
                      RadioListTile<AdsyReportOption>(
                        value: option,
                        enabled: !_isSubmitting,
                        title: Text(
                          option.label,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: const Color(0xFFF97316),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsController,
                enabled: !_isSubmitting,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: widget.detailsHint,
                  hintStyle: const TextStyle(fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFF97316), width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _selectedOption == null || _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: AdsyLoadingIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Submitting...'),
                          ],
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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
}
