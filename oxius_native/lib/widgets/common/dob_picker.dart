import 'package:flutter/material.dart';

/// A simple date-of-birth picker: a popup with Day / Month / Year dropdowns.
/// Much easier than scrolling a calendar back decades. Returns the chosen date
/// (or null if cancelled).
Future<DateTime?> showDobPicker(
  BuildContext context, {
  DateTime? initial,
  Color accent = const Color(0xFF5B67E8),
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _DobPickerDialog(initial: initial, accent: accent),
  );
}

class _DobPickerDialog extends StatefulWidget {
  final DateTime? initial;
  final Color accent;
  const _DobPickerDialog({this.initial, required this.accent});

  @override
  State<_DobPickerDialog> createState() => _DobPickerDialogState();
}

class _DobPickerDialogState extends State<_DobPickerDialog> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late int _year;
  late int _month;
  late int _day;
  late final int _maxYear;

  @override
  void initState() {
    super.initState();
    // `DateTime.now()` isn't allowed in some sandboxes but is fine in the app.
    final now = DateTime.now();
    _maxYear = now.year;
    final base = widget.initial ?? DateTime(now.year - 18, 1, 1);
    _year = base.year.clamp(1900, _maxYear);
    _month = base.month;
    _day = base.day;
    _clampDay();
  }

  int _daysInMonth(int year, int month) {
    // Day 0 of the next month == last day of this month.
    return DateTime(year, month + 1, 0).day;
  }

  void _clampDay() {
    final max = _daysInMonth(_year, _month);
    if (_day > max) _day = max;
  }

  @override
  Widget build(BuildContext context) {
    final years = [for (int y = _maxYear; y >= 1900; y--) y];
    final days = [for (int d = 1; d <= _daysInMonth(_year, _month); d++) d];

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cake_outlined, size: 20, color: widget.accent),
                const SizedBox(width: 8),
                const Text(
                  'Date of birth',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _dropdown<int>(
                    label: 'Day',
                    value: _day,
                    items: days,
                    display: (d) => d.toString(),
                    onChanged: (v) => setState(() => _day = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _dropdown<int>(
                    label: 'Month',
                    value: _month,
                    items: List.generate(12, (i) => i + 1),
                    display: (m) => _months[m - 1],
                    onChanged: (v) => setState(() {
                      _month = v!;
                      _clampDay();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _dropdown<int>(
                    label: 'Year',
                    value: _year,
                    items: years,
                    display: (y) => y.toString(),
                    onChanged: (v) => setState(() {
                      _year = v!;
                      _clampDay();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      foregroundColor: const Color(0xFF64748B),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, DateTime(_year, _month, _day)),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirm',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) display,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B))),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              menuMaxHeight: 320,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF64748B), size: 20),
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A)),
              items: items
                  .map((e) => DropdownMenuItem<T>(
                        value: e,
                        child: Text(display(e),
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
