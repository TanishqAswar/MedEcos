import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  int selectedDay = 21;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calender',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'December - 2021',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Week Days Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeekDayHeader('Sa'),
              _buildWeekDayHeader('Su'),
              _buildWeekDayHeader('Mo'),
              _buildWeekDayHeader('Tu'),
              _buildWeekDayHeader('We'),
              _buildWeekDayHeader('Th'),
              _buildWeekDayHeader('Fr'),
            ],
          ),
          const SizedBox(height: 12),
          // Calendar Grid
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildWeekDayHeader(String day) {
    return SizedBox(
      width: 32,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // December 2021 calendar data
    final List<List<int?>> weeks = [
      [null, null, null, null, 1, 2, 3],
      [4, 5, 6, 7, 8, 9, 10],
      [11, 12, 13, 14, 15, 16, 17],
      [18, 19, 20, 21, 22, 23, 24],
      [25, 26, 27, 28, 29, 30, 31],
      [null, null, null, null, null, null, null],
      [null, null, null, null, null, null, null],
    ];

    return Column(
      children: weeks.take(5).map((week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: week.map((day) {
              if (day == null) {
                return const SizedBox(width: 32, height: 32);
              }
              return _buildDayCell(day);
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(int day) {
    final isSelected = day == selectedDay;
    final isToday = day == 21;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDay = day;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          day.toString(),
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isToday
                    ? AppColors.primary
                    : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
