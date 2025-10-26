import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/calendar_provider.dart';
import 'add_event_screen.dart';
import 'event_detail_screen.dart';

class WeekTimelineScreen extends StatefulWidget {
  const WeekTimelineScreen({Key? key}) : super(key: key);

  @override
  State<WeekTimelineScreen> createState() => _WeekTimelineScreenState();
}

class _WeekTimelineScreenState extends State<WeekTimelineScreen> {
  late ScrollController _scrollController;
  late DateTime _weekStart;
  final double _hourHeight = 60.0; // Height of each hour slot
  final double _dayWidth = 120.0; // Width of each day column

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    _scrollController = ScrollController();

    // Auto-scroll to current time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final offset = now.hour * _hourHeight;
      _scrollController.animateTo(
        offset - 100,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  List<DateTime> _getWeekDays() {
    return List.generate(7, (index) => _weekStart.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Semanal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _weekStart = _getWeekStart(DateTime.now());
              });
              final now = DateTime.now();
              final offset = now.hour * _hourHeight;
              _scrollController.animateTo(
                offset - 100,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEventScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekNavigator(),
          _buildWeekHeader(),
          Expanded(
            child: _buildTimelineGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _weekStart = _weekStart.subtract(const Duration(days: 7));
              });
            },
          ),
          Text(
            '${DateFormat.MMMd().format(_weekStart)} - ${DateFormat.MMMd().format(_weekStart.add(const Duration(days: 6)))}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _weekStart = _weekStart.add(const Duration(days: 7));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    final weekDays = _getWeekDays();
    final today = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Time column header
          SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: Icon(
                Icons.access_time,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          // Day headers
          ...weekDays.map((day) {
            final isToday = day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;

            return Container(
              width: _dayWidth,
              height: 60,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E('es').format(day),
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineGrid() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final weekDays = _getWeekDays();

        return SingleChildScrollView(
          controller: _scrollController,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time labels column
              _buildTimeLabels(),
              // Day columns with events
              ...weekDays.map((day) => _buildDayColumn(day, provider)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeLabels() {
    return Container(
      width: 60,
      child: Column(
        children: List.generate(24, (hour) {
          return Container(
            height: _hourHeight,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(DateTime day, CalendarProvider provider) {
    final events = provider.getEventsForDay(day);
    final now = DateTime.now();
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;

    return Container(
      width: _dayWidth,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Hour grid lines
          Column(
            children: List.generate(24, (hour) {
              return Container(
                height: _hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                ),
              );
            }),
          ),
          // Half-hour grid lines
          Column(
            children: List.generate(24, (hour) {
              return Container(
                height: _hourHeight,
                padding: EdgeInsets.only(top: _hourHeight / 2),
                child: Container(
                  height: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.15),
                ),
              );
            }),
          ),
          // Current time indicator
          if (isToday) _buildCurrentTimeIndicator(),
          // Events
          ...events.where((e) => !e.isAllDay).map((event) {
            return _buildEventBlock(event, day);
          }).toList(),
          // All-day events banner at top
          if (events.any((e) => e.isAllDay))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildAllDayEventsBanner(events.where((e) => e.isAllDay).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final topPosition = (minutesSinceMidnight / 60) * _hourHeight;

    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDayEventsBanner(List<CalendarEvent> allDayEvents) {
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: allDayEvents.map((event) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              event.title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventBlock(CalendarEvent event, DateTime day) {
    final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
    final endMinutes = event.endTime.hour * 60 + event.endTime.minute;
    final durationMinutes = endMinutes - startMinutes;

    final topPosition = (startMinutes / 60) * _hourHeight;
    final height = (durationMinutes / 60) * _hourHeight;

    return Positioned(
      top: topPosition,
      left: 2,
      right: 2,
      height: height.clamp(20.0, double.infinity),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: event.color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (height > 30) ...[
                const SizedBox(height: 2),
                Text(
                  '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                  ),
                ),
              ],
              if (event.location != null && height > 50) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 9,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
