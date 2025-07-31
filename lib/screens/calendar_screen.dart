import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../widgets/show_add_birthday.dart';

class CalendarScreen extends StatefulWidget {
  final List<CalendarEvent> events;

  const CalendarScreen({super.key, required this.events});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Map date -> list of colors for vacation surlignage
  Map<DateTime, List<Color>> vacationColorMap = {};

  @override
  void initState() {
    super.initState();
    _initVacationDays();
  }

  void _initVacationDays() {
    for (var event in widget.events) {
      if (event.type == 'vacation' &&
          event.debut != null &&
          event.fin != null &&
          event.color != null) {
        final color = event.color!;
        DateTime current = DateTime(
          event.debut!.year,
          event.debut!.month,
          event.debut!.day,
        );
        DateTime end = DateTime(
          event.fin!.year,
          event.fin!.month,
          event.fin!.day,
        );

        while (!current.isAfter(end)) {
          vacationColorMap.putIfAbsent(current, () => []).add(color);
          current = current.add(const Duration(days: 1));
        }
      }
    }
  }

  List<CalendarEvent> getBirthdaysForDay(DateTime day) {
    return widget.events.where((e) {
      if ((e.type == 'birthday' || e.type == 'anniversaire') && e.date != null) {
        return e.date!.day == day.day && e.date!.month == day.month;
      }
      return false;
    }).toList();
  }

  // Regroupe les événements par date (pour TableCalendar)
  Map<DateTime, List<CalendarEvent>> get groupedEvents {
    final Map<DateTime, List<CalendarEvent>> data = {};

    for (final event in widget.events) {
      if (event.type == 'vacation' &&
          event.debut != null &&
          event.fin != null) {
        DateTime current = DateTime(
          event.debut!.year,
          event.debut!.month,
          event.debut!.day,
        );
        DateTime end = DateTime(
          event.fin!.year,
          event.fin!.month,
          event.fin!.day,
        );
        while (!current.isAfter(end)) {
          data.putIfAbsent(current, () => []).add(event);
          current = current.add(const Duration(days: 1));
        }
      } else if (event.date != null) {
        final day = DateTime(
          event.date!.year,
          event.date!.month,
          event.date!.day,
        );
        data.putIfAbsent(day, () => []).add(event);
      }
    }

    return data;
  }

  // Récupère les événements du jour triés du plus tôt au plus tard
  List<CalendarEvent> _getEventsForDay(DateTime day) {
  final filtered = widget.events.where((e) {
    if (e.type == 'birthday' || e.type == 'anniversaire') {
      return e.date != null &&
             e.date!.day == day.day &&
             e.date!.month == day.month;
    } else {
      return e.date != null &&
             e.date!.year == day.year &&
             e.date!.month == day.month &&
             e.date!.day == day.day;
    }
  }).toList();

  return filtered;
}



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddBirthdaySheet(context),
        backgroundColor: const Color(0xFFFF5F6D),
        child: const Icon(
          Icons.add,
          color: Colors.white, // icône blanche
        ),
      ),
      body: Column(
        children: [
          // Header dégradé
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5F6D), Color(0xFFFF8F5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              left: 24,
              right: 24,
              bottom: 14,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -50,
                  top: -120,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Image.asset(
                      'assets/images/bg_liquid.png',
                      width: 145,
                    ),
                  ),
                ),
                Positioned(
                  right: -35,
                  top: -20,
                  child: Transform.rotate(
                    angle: 50,
                    child: Image.asset(
                      'assets/images/bg_liquid.png',
                      width: 100,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Retour',
                        ),
                        const SizedBox(width: 32),
                        Text(
                          'Calendrier',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: const [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black26,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
              icon: const Icon(Icons.today, size: 20),
              label: const Text(
                "Aujourd’hui",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5F6D),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),

          Expanded(
            child: Column(
              children: [
                TableCalendar<CalendarEvent>(
                  locale: 'fr_FR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  eventLoader: _getEventsForDay,
                  calendarFormat: _calendarFormat,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mois',
                    CalendarFormat.week: 'Semaine',
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  availableGestures: AvailableGestures.all, // swipe horizontal + vertical

                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontFamily: 'Montserrat',
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.deepPurple),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.deepPurple),
                    formatButtonVisible: false,
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: const Color(0xFFFF5F6D),
                      fontWeight: FontWeight.bold,
                    ),
                    weekendStyle: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: const Color(0xFFFF5F6D),
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(color: Colors.red),
                    outsideDaysVisible: false,
                  ),
                  // builder du calendar
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                        final events = _getEventsForDay(day);

                          final birthdays = events.where((e) {
                            if ((e.type == 'birthday' || e.type == 'anniversaire') && e.date != null) {
                              return e.date!.day == day.day && e.date!.month == day.month;
                            }
                            return false;
                          }).toList();

                          if (birthdays.isNotEmpty) {
                            return Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF5F6D),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 1),

                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // icône gâteau en haut à droite, légèrement en dehors du cercle
                              Positioned(
                                top: -10,
                                right: -10,
                                child: Container(
                                  width: 25,
                                  height: 25,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                                    color: const Color.fromARGB(255, 255, 255, 255),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/cake.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final todayVacations = events.where((e) => e.type == 'vacation').toList();

                      if (todayVacations.isEmpty) {
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        );
                      }

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          for (final vac in todayVacations)
                            buildVacationLayer(day, vac),
                          for (final vac in todayVacations)
                            if (isSameDay(vac.debut, day) || isSameDay(vac.fin, day))
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: vac.color ?? Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          if (!todayVacations.any(
                            (e) => isSameDay(e.debut, day) || isSameDay(e.fin, day)))
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      );
                    },

                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return const SizedBox.shrink();
                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.map((event) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: event.color?.withValues(alpha: 0.9) ?? const Color(0xFFFF5F6D),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 1),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: buildEventList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVacationLayer(DateTime day, CalendarEvent vac) {
    final isStart = isSameDay(vac.debut, day);
    final isEnd = isSameDay(vac.fin, day);
    final mainColor = vac.color ?? Colors.orange;

    // largeur du fond selon position dans la plage
    double width;
    if (isStart && isEnd) {
      width = 36;
    } else if (isStart || isEnd) {
      width = 54;
    } else {
      width = 80;
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        maxWidth: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isStart)
              const SizedBox(width: 18)
            else
              const SizedBox(width: 0),
            Container(
              width: width,
              height: 36,
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            if (isEnd) const SizedBox(width: 18) else const SizedBox(width: 0),
          ],
        ),
      ),
    );
  }

  Widget buildEventList() {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);

    if (events.isEmpty) {
      return const Center(
        child: Text(
          'Aucun événement ce jour.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final e = events[index];
        final heure = e.debut != null
            ? DateFormat('HH:mm').format(e.debut!)
            : (e.date != null ? DateFormat('HH:mm').format(e.date!) : '');

        IconData icon;
        Color bgColor;

        switch (e.type) {
          case 'rendezvous':
            icon = Icons.medical_services_outlined;
            bgColor = Colors.blueAccent;
            break;
          case 'vacation':
            icon = Icons.beach_access_outlined;
            bgColor = e.color ?? Colors.orange.shade700;
            break;
          case 'birthday':
          case 'anniversaire':
            icon = Icons.cake_outlined;
            bgColor = Colors.pinkAccent.shade200;
            break;
          default:
            icon = Icons.task_outlined;
            bgColor = Colors.grey.shade600;
        }

        Widget content;

        if (e.type == 'rendezvous') {
          content = SizedBox(
            height: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.participant.isNotEmpty ? e.participant : e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                if (e.description != null && e.description!.isNotEmpty)
                  Text(
                    e.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                const Spacer(),
                if (e.medecin.isNotEmpty)
                  Text(
                    'Dr ${e.medecin}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFF5F6D),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          );
        } else {
          content = SizedBox(
            height: (e.type == 'birthday' || e.type == 'anniversaire') ? 64 : 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                if (e.description != null && e.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      e.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ),
                if (e.type == 'birthday' || e.type == 'anniversaire') ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Souhaitez lui un joyeux anniversaire !',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.pinkAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                if (e.medecin.isNotEmpty)
                  Text(
                    'Dr ${e.medecin}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFF5F6D),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: content),
              if (heure.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    heure,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
