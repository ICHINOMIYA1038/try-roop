import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/event.dart';
import '../../providers/providers.dart';
import '../../widgets/event_card.dart';
import '../../widgets/month_calendar.dart';

class EventCalendarScreen extends ConsumerWidget {
  const EventCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final selectedDate = ref.watch(selectedEventDateProvider);
    final filterType = ref.watch(eventTypeFilterProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      appBar: AppBar(
        title: const Text('イベント'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF433D39),
        elevation: 0,
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
        data: (events) {
          // Get event dates for calendar dots
          final eventDates = events
              .map((e) => DateTime(e.startAt.year, e.startAt.month, e.startAt.day))
              .toSet();

          // Filter events
          List<Event> filteredEvents = events;

          // Filter by type
          if (filterType != null) {
            filteredEvents = filteredEvents
                .where((e) => e.eventType == filterType)
                .toList();
          }

          // Filter by selected date or month
          if (selectedDate != null) {
            filteredEvents = filteredEvents.where((e) {
              return e.startAt.year == selectedDate.year &&
                  e.startAt.month == selectedDate.month &&
                  e.startAt.day == selectedDate.day;
            }).toList();
          } else {
            filteredEvents = filteredEvents.where((e) {
              return e.startAt.year == focusedMonth.year &&
                  e.startAt.month == focusedMonth.month;
            }).toList();
          }

          // Sort by date
          filteredEvents.sort((a, b) => a.startAt.compareTo(b.startAt));

          return Column(
            children: [
              // Filter chips
              _buildFilterChips(ref, filterType),
              const Divider(height: 1),
              // Calendar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: MonthCalendar(
                  focusedMonth: focusedMonth,
                  selectedDate: selectedDate,
                  eventDates: eventDates,
                  onMonthChanged: (month) {
                    ref.read(focusedMonthProvider.notifier).state = month;
                    ref.read(selectedEventDateProvider.notifier).state = null;
                  },
                  onDateSelected: (date) {
                    final currentSelected = ref.read(selectedEventDateProvider);
                    if (currentSelected != null &&
                        currentSelected.year == date.year &&
                        currentSelected.month == date.month &&
                        currentSelected.day == date.day) {
                      // Deselect if same date
                      ref.read(selectedEventDateProvider.notifier).state = null;
                    } else {
                      ref.read(selectedEventDateProvider.notifier).state = date;
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              // Event list header
              _buildListHeader(focusedMonth, selectedDate, filteredEvents.length),
              // Event list
              Expanded(
                child: filteredEvents.isEmpty
                    ? _buildEmptyState(selectedDate)
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return EventCard(
                            event: event,
                            onTap: () => context.push('/event/${event.id}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, EventType? filterType) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'すべて',
            isSelected: filterType == null,
            onTap: () {
              ref.read(eventTypeFilterProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'オンライン',
            isSelected: filterType == EventType.online,
            onTap: () {
              ref.read(eventTypeFilterProvider.notifier).state = EventType.online;
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'オフライン',
            isSelected: filterType == EventType.offline,
            onTap: () {
              ref.read(eventTypeFilterProvider.notifier).state = EventType.offline;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8A3D) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildListHeader(DateTime focusedMonth, DateTime? selectedDate, int count) {
    String headerText;
    if (selectedDate != null) {
      headerText = '${selectedDate.month}月${selectedDate.day}日のイベント ($count件)';
    } else {
      headerText = '${focusedMonth.month}月のイベント ($count件)';
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      child: Text(
        headerText,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF433D39),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DateTime? selectedDate) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            selectedDate != null
                ? 'この日のイベントはありません'
                : 'この月のイベントはありません',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
