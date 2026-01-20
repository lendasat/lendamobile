import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Shows a Notion-style inline calendar in a bottom sheet.
/// Returns the selected date or null if dismissed.
Future<DateTime?> showInlineCalendar({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) async {
  return arkBottomSheet<DateTime>(
    context: context,
    child: _InlineCalendarSheet(
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2009), // Bitcoin genesis
      lastDate: lastDate ?? DateTime.now(),
      title: title ?? 'Select Date',
    ),
  );
}

class _InlineCalendarSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const _InlineCalendarSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
  });

  @override
  State<_InlineCalendarSheet> createState() => _InlineCalendarSheetState();
}

class _InlineCalendarSheetState extends State<_InlineCalendarSheet> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  void _previousMonth() {
    final newMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    if (newMonth.isAfter(widget.firstDate) ||
        newMonth.year == widget.firstDate.year &&
            newMonth.month == widget.firstDate.month) {
      HapticFeedback.selectionClick();
      setState(() => _focusedMonth = newMonth);
    }
  }

  void _nextMonth() {
    final newMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    if (newMonth.isBefore(widget.lastDate) ||
        newMonth.year == widget.lastDate.year &&
            newMonth.month == widget.lastDate.month) {
      HapticFeedback.selectionClick();
      setState(() => _focusedMonth = newMonth);
    }
  }

  void _selectDate(DateTime date) {
    HapticFeedback.lightImpact();
    setState(() => _selectedDate = date);
    // Auto-close after selection with small delay for visual feedback
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) Navigator.pop(context, date);
    });
  }

  bool _isDateSelectable(DateTime date) {
    return !date.isBefore(DateTime(widget.firstDate.year,
            widget.firstDate.month, widget.firstDate.day)) &&
        !date.isAfter(DateTime(
            widget.lastDate.year, widget.lastDate.month, widget.lastDate.day));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: BitNetAppBar(
        context: context,
        text: widget.title,
        hasBackButton: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.cardPadding),
            // Month navigation
            _buildMonthNavigation(isDark),
            const SizedBox(height: AppTheme.cardPadding),
            // Weekday headers
            _buildWeekdayHeaders(isDark),
            const SizedBox(height: 8),
            // Calendar grid
            Expanded(child: _buildCalendarGrid(isDark)),
            const SizedBox(height: AppTheme.cardPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigation(bool isDark) {
    final canGoPrevious = _focusedMonth.isAfter(widget.firstDate) ||
        (_focusedMonth.year == widget.firstDate.year &&
            _focusedMonth.month > widget.firstDate.month);
    final canGoNext = _focusedMonth
            .isBefore(DateTime(widget.lastDate.year, widget.lastDate.month)) ||
        (_focusedMonth.year == widget.lastDate.year &&
            _focusedMonth.month < widget.lastDate.month);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavigationButton(
          icon: Icons.chevron_left_rounded,
          onTap: canGoPrevious ? _previousMonth : null,
          isDark: isDark,
        ),
        GestureDetector(
          onTap: () => _showYearPicker(context, isDark),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
            ),
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedMonth),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        _NavigationButton(
          icon: Icons.chevron_right_rounded,
          onTap: canGoNext ? _nextMonth : null,
          isDark: isDark,
        ),
      ],
    );
  }

  void _showYearPicker(BuildContext context, bool isDark) {
    final years = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (i) => widget.lastDate.year - i,
    );

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.4,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelected = year == _focusedMonth.year;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _focusedMonth = DateTime(year, _focusedMonth.month);
              });
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                year.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? AppTheme.white60 : AppTheme.black60),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekdayHeaders(bool isDark) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: weekdays
          .map((day) => Expanded(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // Monday = 1, Sunday = 7, we want Monday as first day
    final startingWeekday = firstDayOfMonth.weekday - 1;

    final totalCells = ((startingWeekday + daysInMonth) / 7).ceil() * 7;
    final today = DateTime.now();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayOffset = index - startingWeekday;

        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          // Empty cell for days outside current month
          return const SizedBox.shrink();
        }

        final date =
            DateTime(_focusedMonth.year, _focusedMonth.month, dayOffset + 1);
        final isSelected = _selectedDate != null &&
            date.year == _selectedDate!.year &&
            date.month == _selectedDate!.month &&
            date.day == _selectedDate!.day;
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSelectable = _isDateSelectable(date);

        return _DayCell(
          day: dayOffset + 1,
          isSelected: isSelected,
          isToday: isToday,
          isSelectable: isSelectable,
          isDark: isDark,
          onTap: isSelectable ? () => _selectDate(date) : null,
        );
      },
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _NavigationButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDark
              ? Colors.white.withValues(alpha: isEnabled ? 0.08 : 0.03)
              : Colors.black.withValues(alpha: isEnabled ? 0.05 : 0.02),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isEnabled
              ? (isDark ? Colors.white : Colors.black)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isSelectable;
  final bool isDark;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isSelectable,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    FontWeight fontWeight;

    if (isSelected) {
      backgroundColor = isDark ? Colors.white : Colors.black;
      textColor = isDark ? Colors.black : Colors.white;
      fontWeight = FontWeight.w600;
    } else if (isToday) {
      backgroundColor = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.08);
      textColor = isDark ? Colors.white : Colors.black;
      fontWeight = FontWeight.w600;
    } else {
      backgroundColor = Colors.transparent;
      textColor = isSelectable
          ? (isDark ? AppTheme.white80 : AppTheme.black80)
          : (isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.2));
      fontWeight = FontWeight.normal;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
