import 'package:flutter/material.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date block
              _buildDateBlock(),
              const SizedBox(width: 12),
              // Event info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event type badge
                    _buildEventTypeBadge(),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF433D39),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.timeFormatted,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Capacity info
                    _buildCapacityInfo(),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBlock() {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${event.startAt.month}/${event.startAt.day}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8A3D),
            ),
          ),
          Text(
            _weekdayLabel(event.startAt.weekday),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFF8A3D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeBadge() {
    final isOnline = event.isOnline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.videocam : Icons.location_on,
            size: 12,
            color: isOnline ? const Color(0xFF1976D2) : const Color(0xFF388E3C),
          ),
          const SizedBox(width: 4),
          Text(
            event.eventTypeLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isOnline ? const Color(0xFF1976D2) : const Color(0xFF388E3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityInfo() {
    if (event.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '満席',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
      );
    }

    return Row(
      children: [
        Icon(
          Icons.people_outline,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          '残り${event.availableSpots}席',
          style: TextStyle(
            fontSize: 12,
            color: event.availableSpots <= 5
                ? Colors.orange.shade700
                : Colors.grey.shade600,
            fontWeight: event.availableSpots <= 5 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['月', '火', '水', '木', '金', '土', '日'];
    return labels[weekday - 1];
  }
}
