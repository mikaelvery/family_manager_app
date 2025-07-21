import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_manager_app/screens/appointments_screen.dart';
import 'package:family_manager_app/screens/documents_screen.dart';
import 'package:family_manager_app/widgets/pick__upload_document.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }
  // Chargement du nom de l'utilisateur depuis Firestore
  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userName = doc['name'] ?? '👤';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // récupération l’utilisateur connecté
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }
    // Détermination de l'avatar et du nombre de notifications
    final userEmail = user.email ?? '';
    final isLaura = userEmail == 'machado.laura@live.fr';
    final avatarAsset = isLaura
        ? 'assets/avatar_femme.png'
        : 'assets/avatar_homme.png';
    int notificationCount = 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: const EdgeInsets.only(
              top: 48,
              left: 20,
              right: 20,
              bottom: 28,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    Text(
                      '${_userName ?? ''} 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
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
                            color: Colors.black87,
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
                      backgroundColor: Colors.grey[200],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Corps scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Prochains rendez-vous',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('rendezvous')
                          .orderBy('datetime')
                          .snapshots(),
                      builder: (context, snapshot) {
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
                        final appointments = showAllAppointments ? allAppointments : allAppointments.take(4).toList();

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: appointments.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            if (index == appointments.length) {
                              return seeMoreCard(
                                onTap: () {
                                  setState(() {
                                    showAllAppointments = !showAllAppointments;
                                  });
                                },
                                label: showAllAppointments ? "Voir -" : "Voir +",
                              );
                            }

                            final data = appointments[index];
                            final String participant = data['participant'] ?? '';
                            final String description = data['description'] ?? '';
                            final DateTime datetime = (data['datetime'] as Timestamp).toDate();
                            final String formattedDate = DateFormat('dd MMM • HH:mm', 'fr_FR').format(datetime);
                            final iconData = _getIconForDescription(description);
                            final iconColor = _getColorForDescription(description);

                            return appointmentCard(
                              title: participant,
                              subtitle: "$description\n$formattedDate",
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
                    'Liste de tâches, rappels',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
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
                            MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
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
                        [
                          Color(0xFF00C9A7),
                          Color(0xFF92FE9D),
                        ],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                          );
                        },
                      ),
                      buildActionButton(
                        'Ajouter tâche',
                        Icons.playlist_add_check,
                        [Color(0xFFFFE4B5), Color(0xFFFFC897)],
                        textColor: Colors.black87,
                        onTap: () => showAddTaskSheet(context),
                      ),
                      buildActionButton('Voir mes tâches', Icons.list_alt, [
                        Color(0xFFFFC371),
                        Color(0xFFFFA751),
                      ]),
                      buildActionButton(
                        'Ajouter vacances',
                        Icons.beach_access,
                        [Color(0xFFB084F5), Color(0xFFB79CF2)],
                        textColor: Colors.black87,
                      ),
                      buildActionButton(
                        'Voir mes vacances',
                        Icons.flight_takeoff,
                        [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   selectedItemColor: Colors.pinkAccent,
      //   unselectedItemColor: Colors.grey,
      //   items: const [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
      //     BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendrier'),
      //     BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Documents'),
      //     BottomNavigationBarItem(icon: Icon(Icons.flight_takeoff), label: 'Vacances'),
      //   ],
      // ),
    );
  }

  // Récupération de l'icône et de la couleur en fonction de la description des RDV
  IconData _getIconForDescription(String description) {
    final desc = description.toLowerCase();

    if (desc.contains('dentiste')) return Icons.medical_services;
    if (desc.contains('angiologue')) return Icons.healing;
    if (desc.contains('orthodontiste')) return Icons.masks;
    if (desc.contains('docteur') || desc.contains('médecin')) {
      return Icons.local_hospital;
    }
    if (desc.contains('kiné') || desc.contains('kine')) {
      return Icons.accessibility_new;
    }
    if (desc.contains('ophtalmologue')) return Icons.visibility;
    if (desc.contains('orthophoniste')) return Icons.record_voice_over;
    if (desc.contains('ergothérapeute') || desc.contains('ergo')) {
      return Icons.psychology;
    }
    if (desc.contains('psychologue')) return Icons.psychology;
    if (desc.contains('chirurgien')) return Icons.health_and_safety;
    if (desc.contains('hopital')) return Icons.medical_services;

    return Icons.event;
  }

  Color _getColorForDescription(String description) {
    final desc = description.toLowerCase();

    if (desc.contains('dentiste')) return Colors.deepPurple;
    if (desc.contains('angiologue')) return Colors.green;
    if (desc.contains('orthodontiste')) return Colors.blue;
    if (desc.contains('docteur') || desc.contains('médecin')) {
      return Colors.redAccent;
    }
    if (desc.contains('kiné') || desc.contains('kine')) return Colors.orange;
    if (desc.contains('ophtalmologue')) return Colors.indigo;
    if (desc.contains('orthophoniste')) return Colors.teal;
    if (desc.contains('ergothérapeute') || desc.contains('ergo')) {
      return Colors.pink;
    }
    if (desc.contains('psychologue')) return Colors.amber;
    if (desc.contains('chirurgien')) return Colors.brown;
    if (desc.contains('hopital')) return Colors.blueGrey;
    return Colors.grey;
  }
}
