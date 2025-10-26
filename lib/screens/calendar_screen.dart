import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/calendar_provider.dart';
import '../services/theme_provider.dart';
import '../services/keyboard_shortcuts.dart';
import '../models/event_model.dart';
import '../widgets/event_list_item.dart';
import 'event_detail_screen.dart';
import 'add_event_screen.dart';
import 'search_screen.dart';
import 'agenda_screen.dart';
import 'year_view_screen.dart';
import 'statistics_screen.dart';
import 'filter_screen.dart';
import 'categories_screen.dart';
import 'tasks_screen.dart';
import 'templates_screen.dart';
import 'week_timeline_screen.dart';
import 'reminders_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return KeyboardShortcutsWidget(
      onNewEvent: () => _navigateToAddEvent(context),
      onSearch: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      onToday: () {
        final provider = context.read<CalendarProvider>();
        final today = DateTime.now();
        provider.selectDay(today);
        provider.setFocusedDay(today);
      },
      onNextDay: () {
        final provider = context.read<CalendarProvider>();
        final nextDay = provider.selectedDay.add(const Duration(days: 1));
        provider.selectDay(nextDay);
        provider.setFocusedDay(nextDay);
      },
      onPreviousDay: () {
        final provider = context.read<CalendarProvider>();
        final prevDay = provider.selectedDay.subtract(const Duration(days: 1));
        provider.selectDay(prevDay);
        provider.setFocusedDay(prevDay);
      },
      onNextWeek: () {
        final provider = context.read<CalendarProvider>();
        final nextWeek = provider.selectedDay.add(const Duration(days: 7));
        provider.selectDay(nextWeek);
        provider.setFocusedDay(nextWeek);
      },
      onPreviousWeek: () {
        final provider = context.read<CalendarProvider>();
        final prevWeek = provider.selectedDay.subtract(const Duration(days: 7));
        provider.selectDay(prevWeek);
        provider.setFocusedDay(prevWeek);
      },
      onNextMonth: () {
        final provider = context.read<CalendarProvider>();
        final nextMonth = DateTime(
          provider.selectedDay.year,
          provider.selectedDay.month + 1,
          provider.selectedDay.day,
        );
        provider.selectDay(nextMonth);
        provider.setFocusedDay(nextMonth);
      },
      onPreviousMonth: () {
        final provider = context.read<CalendarProvider>();
        final prevMonth = DateTime(
          provider.selectedDay.year,
          provider.selectedDay.month - 1,
          provider.selectedDay.day,
        );
        provider.selectDay(prevMonth);
        provider.setFocusedDay(prevMonth);
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Gero Neuro Kine - Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          Consumer<CalendarProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.isGoogleCalendarConnected
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                ),
                onPressed: () => _handleGoogleCalendarSync(context),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'day') {
                context.read<CalendarProvider>().setViewMode(CalendarViewMode.day);
                _calendarFormat = CalendarFormat.week;
              } else if (value == 'week') {
                context.read<CalendarProvider>().setViewMode(CalendarViewMode.week);
                _calendarFormat = CalendarFormat.week;
              } else if (value == 'month') {
                context.read<CalendarProvider>().setViewMode(CalendarViewMode.month);
                _calendarFormat = CalendarFormat.month;
              }
              setState(() {});
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'day', child: Text('Vista Diaria')),
              const PopupMenuItem(value: 'week', child: Text('Vista Semanal')),
              const PopupMenuItem(value: 'month', child: Text('Vista Mensual')),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.calendar_month, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Gero Neuro Kine',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendario'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_week),
              title: const Text('Vista Semanal'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WeekTimelineScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Agenda'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AgendaScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt),
              title: const Text('Tareas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TasksScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_month),
              title: const Text('Vista Anual'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const YearViewScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Estadísticas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Filtrar Eventos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FilterScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categorías'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoriesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text('Plantillas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplatesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Recordatorios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RemindersScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  secondary: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: const Text('Modo Oscuro'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.keyboard),
              title: const Text('Atajos de Teclado'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const KeyboardShortcutsHelp(),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Acerca de'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Gero Neuro Kine - Calendar',
                  applicationVersion: '1.4.0',
                  applicationIcon: const Icon(Icons.calendar_month, size: 48),
                  children: [
                    const Text(
                      'Una aplicación completa de calendario con sincronización '
                      'de Google Calendar, notificaciones, eventos recurrentes y más.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final selectedDayEvents = provider.getEventsForDay(provider.selectedDay);

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: provider.focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(provider.selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  provider.selectDay(selectedDay);
                  provider.setFocusedDay(focusedDay);
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  provider.setFocusedDay(focusedDay);
                },
                eventLoader: (day) {
                  return provider.getEventsForDay(day);
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: selectedDayEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay eventos para este día',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: selectedDayEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedDayEvents[index];
                          return EventListItem(
                            event: event,
                            onTap: () => _navigateToEventDetail(context, event),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEvent(context),
        child: const Icon(Icons.add),
      ),
      ),
    );
  }

  void _navigateToEventDetail(BuildContext context, CalendarEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  void _navigateToAddEvent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEventScreen(),
      ),
    );
  }

  Future<void> _handleGoogleCalendarSync(BuildContext context) async {
    final provider = context.read<CalendarProvider>();

    if (provider.isGoogleCalendarConnected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Google Calendar'),
          content: const Text('¿Qué deseas hacer?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                provider.syncWithGoogleCalendar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sincronizando con Google Calendar...')),
                );
              },
              child: const Text('Sincronizar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                provider.disconnectGoogleCalendar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Desconectado de Google Calendar')),
                );
              },
              child: const Text('Desconectar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
    } else {
      final success = await provider.connectGoogleCalendar();
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conectado a Google Calendar')),
        );
        provider.syncWithGoogleCalendar();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo conectar a Google Calendar')),
        );
      }
    }
  }
}
