import 'package:family_manager_app/models/calendar_event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekDateTimeline extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime initialDate;
  final List<CalendarEvent> events;
  final VoidCallback onVoirToutPressed;

  const WeekDateTimeline({
    super.key,
    required this.onDateSelected,
    required this.initialDate,
    required this.events,
    required this.onVoirToutPressed,
  });

  @override
  WeekDateTimelineState createState() => WeekDateTimelineState();
}

class WeekDateTimelineState extends State<WeekDateTimeline> {
  late DateTime selectedDate;
  late List<DateTime> weekDays;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    final daysBefore = 2; 
    final totalDays = 6;  
    final today = DateTime.now();
    weekDays = List.generate(
      totalDays,
      (index) => today.subtract(Duration(days: daysBefore)).add(Duration(days: index)),
    );
  }

  void resetToToday() {
    final today = DateTime.now();
    setState(() {
      selectedDate = today;
    });
    widget.onDateSelected(today);
  }

  List<CalendarEvent> get eventsForSelectedDay {
    return widget.events.where((e) {
      final eventDate = e.date ?? e.debut;
      if (eventDate == null) return false;
      return eventDate.year == selectedDate.year &&
        eventDate.month == selectedDate.month &&
        eventDate.day == selectedDate.day;
    }).toList();
  }

  IconData getIconForEvent(CalendarEvent event) {
    switch (event.type) {
      case 'birthday':
        return Icons.cake;
      case 'vacation':
        return Icons.beach_access;
      case 'task':
        return Icons.check_circle;
      case 'rendezvous':
        return Icons.calendar_today;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Timeline horizontale
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weekDays.length + 1, 
            itemBuilder: (context, index) {
              if (index == weekDays.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 2,
                    ),
                    onPressed: widget.onVoirToutPressed,
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }

              final day = weekDays[index];
              final isSelected = day.year == selectedDate.year &&
                  day.month == selectedDate.month &&
                  day.day == selectedDate.day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = day;
                  });
                  widget.onDateSelected(day);
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pinkAccent : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat.E('fr_FR').format(day),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black54,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Liste des événements sous forme de cartes
        if (eventsForSelectedDay.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Aucun événement ce jour",
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ...eventsForSelectedDay.map((e) {
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
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          }),
      ],
    );
  }
}
