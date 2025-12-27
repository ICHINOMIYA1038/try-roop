import 'package:flutter/material.dart';

class MonthCalendar extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Set<DateTime> eventDates;
  final Function(DateTime) onMonthChanged;
  final Function(DateTime) onDateSelected;

  const MonthCalendar({
    super.key,
    required this.focusedMonth,
    this.selectedDate,
    required this.eventDates,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        _buildWeekdayLabels(),
        const SizedBox(height: 4),
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              final prevMonth = DateTime(focusedMonth.year, focusedMonth.month - 1);
              onMonthChanged(prevMonth);
            },
            icon: const Icon(Icons.chevron_left),
            color: const Color(0xFF433D39),
          ),
          Text(
            '${focusedMonth.year}年${focusedMonth.month}月',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF433D39),
            ),
          ),
          IconButton(
            onPressed: () {
              final nextMonth = DateTime(focusedMonth.year, focusedMonth.month + 1);
              onMonthChanged(nextMonth);
            },
            icon: const Icon(Icons.chevron_right),
            color: const Color(0xFF433D39),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        Color color;
        if (index == 0) {
          color = Colors.red.shade400;
        } else if (index == 6) {
          color = Colors.blue.shade400;
        } else {
          color = Colors.grey.shade600;
        }
        return SizedBox(
          width: 40,
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final List<Widget> rows = [];
    List<Widget> currentRow = [];

    // Empty cells before first day
    for (int i = 0; i < startingWeekday; i++) {
      currentRow.add(_buildEmptyCell());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      final isToday = dateOnly == todayDate;
      final isSelected = selectedDate != null &&
          DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day) == dateOnly;
      final hasEvent = eventDates.any((eventDate) =>
          eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day);

      final weekday = (startingWeekday + day - 1) % 7;
      Color textColor;
      if (weekday == 0) {
        textColor = Colors.red.shade400;
      } else if (weekday == 6) {
        textColor = Colors.blue.shade400;
      } else {
        textColor = const Color(0xFF433D39);
      }

      currentRow.add(
        Expanded(
          child: GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF8A3D)
                      : isToday
                          ? const Color(0xFFFFF3E0)
                          : null,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : textColor,
                      ),
                    ),
                    if (hasEvent && !isSelected)
                      Positioned(
                        bottom: 2,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF8A3D),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Create new row every 7 days
      if (currentRow.length == 7) {
        rows.add(Row(children: currentRow));
        currentRow = [];
      }
    }

    // Fill remaining cells in last row
    while (currentRow.isNotEmpty && currentRow.length < 7) {
      currentRow.add(_buildEmptyCell());
    }
    if (currentRow.isNotEmpty) {
      rows.add(Row(children: currentRow));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: rows),
    );
  }

  Widget _buildEmptyCell() {
    return const Expanded(
      child: SizedBox(height: 40),
    );
  }
}
