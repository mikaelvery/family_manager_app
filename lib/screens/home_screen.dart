import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_manager_app/models/calendar_event.dart';
import 'package:family_manager_app/screens/calendar_screen.dart';
import 'package:family_manager_app/screens/appointments_screen.dart';
import 'package:family_manager_app/screens/documents_screen.dart';
import 'package:family_manager_app/screens/vacations_screen.dart';
import 'package:family_manager_app/widgets/add_task_button.dart';
import 'package:family_manager_app/widgets/icon_data.dart';
import 'package:family_manager_app/widgets/pick__upload_document.dart';
import 'package:family_manager_app/widgets/show_addvacation_sheet.dart';
import 'package:family_manager_app/widgets/timeline_week.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/appointment_card.dart';
import '../widgets/task_checklist.dart';
import '../widgets/see_more_card.dart';
import '../widgets/action_button.dart';
import '../widgets/show_rendezvous_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;
  bool showAllAppointments = false;
  Timer? _greetingTimer;
  DateTime selectedDate = DateTime.now();
  List<CalendarEvent> events = [];
  bool loading = true;
  final GlobalKey<WeekDateTimelineState> timelineKey = GlobalKey();

  String greetingForNow() {
    final h = DateTime.now().hour;
    return (h >= 18 || h < 5) ? 'Bonsoir' : 'Bonjour';
  }

  void scheduleGreetingRefresh() {
    final now = DateTime.now();
    DateTime next;
    if (now.hour < 5) {
      next = DateTime(now.year, now.month, now.day, 5);
    } else if (now.hour < 18) {
      next = DateTime(now.year, now.month, now.day, 18);
    } else {
      final t = now.add(const Duration(days: 1));
      next = DateTime(t.year, t.month, t.day, 5);
    }

    _greetingTimer?.cancel();
    _greetingTimer = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() {});
      loadEvents();
      scheduleGreetingRefresh();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
    scheduleGreetingRefresh();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    final allEvents = await fetchEventsFromFirebase(); 
    setState(() {
      events = allEvents;
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void deleteExpiredTasks() {
    final now = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();

    FirebaseFirestore.instance.collection('tasks').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (data['done'] == true) continue;

        final dueDateTimestamp = data['dueDate'] as Timestamp?;
        final reminderTimestamp = data['reminderDateTime'] as Timestamp?;

        final dueDate = dueDateTimestamp?.toDate();
        final reminderDateTime = reminderTimestamp?.toDate();

        if (reminderDateTime != null) {
          if (reminderDateTime.isBefore(now)) {
            batch.delete(doc.reference);
          }
        } else if (dueDate != null) {
          final dueDateOnly = DateTime(
            dueDate.year,
            dueDate.month,
            dueDate.day,
          );
          final todayOnly = DateTime(now.year, now.month, now.day);
          if (dueDateOnly.isBefore(todayOnly)) {
            batch.delete(doc.reference);
          }
        }
      }
      batch.commit();
    });
  }

  Future<void> loadEvents() async {
    final loadedEvents = await fetchEventsFromFirebase();
    setState(() {
      events = loadedEvents;
      loading = false;
    });
  }

  // Chargement du nom de l'utilisateur depuis Firestore
  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          _userName = doc.data()?['name'] ?? '👤';
        });
      } else {
        setState(() {
          _userName = '👤';
        });
      }
    }
  }

  Future<List<CalendarEvent>> fetchEventsFromFirebase() async {
    final List<CalendarEvent> events = [];

    // Récupérer les rendezvous
    final rendezvousSnapshot = await FirebaseFirestore.instance
        .collection('rendezvous')
        .get();
    for (var doc in rendezvousSnapshot.docs) {
      final data = doc.data();
      data['type'] = 'rendezvous';
      events.add(CalendarEvent.fromMap(data, doc.id));
    }

    // Récupérer les tasks
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .get();
    for (var doc in tasksSnapshot.docs) {
      final data = doc.data();
      data['type'] = 'task';
      events.add(CalendarEvent.fromMap(data, doc.id));
    }

    // Récupérer les vacances
    final vacationsSnapshot = await FirebaseFirestore.instance
        .collection('vacations')
        .get();
    for (var doc in vacationsSnapshot.docs) {
      final data = doc.data();
      data['type'] = 'vacation';
      events.add(CalendarEvent.fromMap(data, doc.id));
    }

    final birthdaySnapshot = await FirebaseFirestore.instance
        .collection('birthdays')
        .get();
    for (var doc in birthdaySnapshot.docs) {
      final data = doc.data();
      data['type'] = 'birthday';
      events.add(CalendarEvent.fromMap(data, doc.id));
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text("Utilisateur non connecté")));
    }

    final userEmail = user.email ?? '';
    final isLaura = userEmail == 'machado.laura@live.fr';
    final avatarAsset = isLaura
        ? 'assets/avatar_femme.png'
        : 'assets/avatar_homme.png';
    int notificationCount = 3;
    final greeting = greetingForNow();

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Column(
        children: [
          // HEADER
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5F6D), Color(0xFFFF8F5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -70,
                  top: -120,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Image.asset(
                      'assets/images/bg_liquid.png',
                      width: 160,
                    ),
                  ),
                ),
                Positioned(
                  right: -35,
                  top: -50,
                  child: Transform.rotate(
                    angle: 50,
                    child: Image.asset(
                      'assets/images/bg_liquid.png',
                      width: 120,
                    ),
                  ),
                ),
                // Texte + avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting ${_userName ?? ''} 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Que voulez-vous faire aujourd’hui ?',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                size: 26,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),
                            if (notificationCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$notificationCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage(avatarAsset),
                          backgroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prochains rendez-vous',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 100),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('rendezvous')
                          .where(
                            'datetime',
                            isGreaterThanOrEqualTo: Timestamp.fromDate(
                              DateTime.now(),
                            ),
                          )
                          .orderBy('datetime')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Erreur lors du chargement des rendez-vous',
                            ),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('Aucun rendez-vous'));
                        }

                        final allAppointments = snapshot.data!.docs;
                        final appointments = showAllAppointments
                            ? allAppointments
                            : allAppointments.take(4).toList();

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: appointments.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            if (index == appointments.length) {
                              return seeMoreCard(
                                onTap: () {
                                  setState(() {
                                    showAllAppointments = !showAllAppointments;
                                  });
                                },
                                label: showAllAppointments
                                    ? "Voir -"
                                    : "Voir +",
                              );
                            }

                            final data = appointments[index];
                            final String participant =
                                data['participant'] ?? '';
                            final String description =
                                data['description'] ?? '';
                            final DateTime datetime =
                                (data['datetime'] as Timestamp)
                                    .toDate()
                                    .toLocal();
                            final String medecin = data['medecin'] ?? '';
                            final String formattedDate = DateFormat(
                              'dd MMM • HH:mm',
                              'fr_FR',
                            ).format(datetime);
                            final iconData = getIconForDescription(description);
                            final iconColor = getColorForDescription(
                              description,
                            );

                            return appointmentCard(
                              title: participant,
                              description: description,
                              formattedDate: formattedDate,
                              medecin: medecin,
                              icon: iconData,
                              iconColor: iconColor,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Agenda Hebdomadaire',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                 WeekDateTimeline(
                    key: timelineKey,
                    initialDate: selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        selectedDate = date;
                      });
                    },
                    events: events,
                    onVoirToutPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalendarScreen(events: events),
                        ),
                      );

                      // 👇 On revient ici : reset la timeline sur aujourd'hui
                      timelineKey.currentState?.resetToToday();
                    },
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'Liste de tâches, rappels',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  HomeAddTaskButton(onTap: () => showAddTaskSheet(context)),
                  const SizedBox(height: 12),
                  taskChecklist(context),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.55,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      buildActionButton(
                        'Ajouter rendez-vous',
                        Icons.add,
                        [Color(0xFFFFC1C1), Color(0xFFFFB6A9)],
                        textColor: Colors.black87,
                        onTap: () => showAddRendezVousSheet(context),
                      ),
                      buildActionButton(
                        'Mes rendez-vous',
                        Icons.calendar_today,
                        [Color(0xFFFF5F6D), Color(0xFFFF8E53)],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MyAppointmentsScreen(),
                            ),
                          );
                        },
                      ),
                      buildActionButton(
                        'Ajouter document',
                        Icons.add_to_drive,
                        [Color(0xFFB2F5EA), Color(0xFFAFE9CE)],
                        textColor: Colors.black87,
                        onTap: () async {
                          await pickAndUploadDocument(context);
                        },
                      ),
                      buildActionButton(
                        'Mes documents',
                        Icons.folder,
                        [Color(0xFF00C9A7), Color(0xFF92FE9D)],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DocumentsScreen(),
                            ),
                          );
                        },
                      ),
                      buildActionButton(
                        'Ajouter vacances',
                        Icons.beach_access,
                        [Color(0xFFB084F5), Color(0xFFB79CF2)],
                        textColor: Colors.black87,
                        onTap: () => showVacationSheet(context),
                      ),
                      buildActionButton(
                        'Voir mes vacances',
                        Icons.flight_takeoff,
                        [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const VacationsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
