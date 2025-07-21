import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

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
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? '';
    final isLaura = userEmail == 'machado.laura@live.fr';
    final avatarAsset =
        isLaura ? 'assets/avatar_femme.png' : 'assets/avatar_homme.png';
    int notificationCount = 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // App Bar arrondie
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
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
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
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
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('Aucun rendez-vous'));
      }

      final appointments = snapshot.data!.docs;

      return ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: appointments.length + 1, // +1 pour _seeMoreCard
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == appointments.length) return _seeMoreCard();

          final data = appointments[index];
          final String participant = data['participant'] ?? '';
          final String description = data['description'] ?? '';
          final DateTime datetime = (data['datetime'] as Timestamp).toDate();

          final String formattedDate =
              DateFormat('dd MMM • HH:mm', 'fr_FR').format(datetime);

          final iconData = _getIconForDescription(description);
          final iconColor = _getColorForDescription(description);

          return _appointmentCard(
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

                  const SizedBox(height: 24),
                  const Text(
                    'Liste de tâches, rappels',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _taskChecklist(),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.65,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildActionButton(
                        'Ajouter rendez-vous',
                        Icons.add,
                        [Color(0xFFFFC1C1), Color(0xFFFFB6A9)],
                        textColor: Colors.black87,
                        onTap: () => _showAddRendezVousSheet(context),
                      ),
                      _buildActionButton('Mes rendez-vous', Icons.calendar_today, [
                        Color(0xFFFF5F6D),
                        Color(0xFFFF8E53),
                      ]),
                      _buildActionButton('Ajouter document', Icons.add_to_drive, [
                        Color(0xFFB2F5EA),
                        Color(0xFFAFE9CE),
                      ], textColor: Colors.black87),
                      _buildActionButton('Mes documents', Icons.folder, [
                        Color(0xFF00C9A7),
                        Color(0xFF92FE9D),
                      ]),
                      _buildActionButton('Ajouter tâche', Icons.playlist_add_check, [
                        Color(0xFFFFE4B5),
                        Color(0xFFFFC897),
                      ], textColor: Colors.black87, onTap: () => _showAddTaskSheet(context)),
                      _buildActionButton('Voir mes tâches', Icons.list_alt, [
                        Color(0xFFFFC371),
                        Color(0xFFFFA751),
                      ]),
                      _buildActionButton('Ajouter vacances', Icons.beach_access, [
                        Color(0xFFB084F5),
                        Color(0xFFB79CF2),
                      ], textColor: Colors.black87),
                      _buildActionButton('Voir mes vacances', Icons.flight_takeoff, [
                        Color(0xFF8E2DE2),
                        Color(0xFF4A00E0),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 24),
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


  Widget _appointmentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _taskChecklist() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(tasks.length, (index) {
              final doc = tasks[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final done = data['done'] ?? false;
              final date = (data['date'] as Timestamp?)?.toDate();
              final formattedDate = date != null
                  ? DateFormat('dd/MM/yyyy').format(date)
                  : null;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ Checkbox
                        Theme(
                          data: ThemeData(
                            unselectedWidgetColor: Colors.green,
                          ),
                          child: Checkbox(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            activeColor: Colors.green,
                            checkColor: Colors.white,
                            value: done,
                            onChanged: (value) {
                              FirebaseFirestore.instance
                                  .collection('tasks')
                                  .doc(doc.id)
                                  .update({'done': value});
                            },
                          ),
                        ),

                        // ✅ Infos de la tâche (titre + date)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, size: 18),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          backgroundColor: Colors.white,
                                          title: const Text(
                                            'Détail de la tâche',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          content: Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor: Colors.redAccent,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Fermer',
                                                style: TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              if (formattedDate != null)
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        // ✅ Supprimer
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                          onPressed: () {
                            FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(doc.id)
                              .delete();
                          },
                        ),
                      ],
                    ),
                  ),

                  // ✅ Divider entre les tâches
                  if (index < tasks.length - 1)
                    const Divider(
                      color: Colors.black26,
                      thickness: 0.6,
                      height: 8,
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  static Widget _seeMoreCard() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigation vers la page de tous les rendez-vous
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF5F6D), Color(0xFFFF8E53)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              SizedBox(width: 6),
              Text(
                'Voir +',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bouton card personnalisé (Rendez-vous, Documents, Tâches, etc.)
  static Widget _buildActionButton(
    String title,
    IconData icon,
    List<Color> colors, {
    VoidCallback? onTap,
    Color? textColor,
  }) {
    final Color effectiveTextColor = textColor ?? Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.last.withAlpha(60),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: effectiveTextColor, size: 24),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Récupération de l'icône et de la couleur en fonction de la description des RDV
  IconData _getIconForDescription(String description) {
    final desc = description.toLowerCase();

    if (desc.contains('dentiste')) return Icons.medical_services;
    if (desc.contains('angiologue')) return Icons.healing;
    if (desc.contains('orthodontiste')) return Icons.masks;
    if (desc.contains('docteur') || desc.contains('médecin')) return Icons.local_hospital;
    if (desc.contains('kiné') || desc.contains('kine')) return Icons.accessibility_new;
    if (desc.contains('ophtalmologue')) return Icons.visibility;
    if (desc.contains('orthophoniste')) return Icons.record_voice_over;
    if (desc.contains('ergothérapeute') || desc.contains('ergo')) return Icons.psychology;
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
    if (desc.contains('docteur') || desc.contains('médecin')) return Colors.redAccent;
    if (desc.contains('kiné') || desc.contains('kine')) return Colors.orange;
    if (desc.contains('ophtalmologue')) return Colors.indigo;
    if (desc.contains('orthophoniste')) return Colors.teal;
    if (desc.contains('ergothérapeute') || desc.contains('ergo')) return Colors.pink;
    if (desc.contains('psychologue')) return Colors.amber;
    if (desc.contains('chirurgien')) return Colors.brown;
    if (desc.contains('hopital')) return Colors.blueGrey;
    return Colors.grey; 
  }

  // ajout d'un rendez-vous via une feuille modale
  void _showAddRendezVousSheet(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController participantController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 16,
            right: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ajouter un rendez-vous',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: participantController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la personne',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFFFF5F6D),
                              onPrimary: Colors.white,
                              surface: Color(0xFFFFE0E6),
                              onSurface: Colors.black87,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFFFF5F6D),
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE0E6),
                    foregroundColor: const Color(0xFFFF5F6D),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text(
                    "Choisir une date",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            timePickerTheme: TimePickerThemeData(
                              backgroundColor: const Color(0xFFFFE0E6),
                              hourMinuteColor: const Color(0xFFFF5F6D),
                              hourMinuteTextColor: Colors.white,
                              dialHandColor: const Color(0xFFFF5F6D),
                              dialBackgroundColor: const Color(0xFFFFB6C1),
                              entryModeIconColor: const Color(0xFFFF5F6D),
                            ),
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFFFF5F6D),
                              onPrimary: Colors.white,
                              onSurface: Colors.black87,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFFFF5F6D),
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      selectedTime = picked;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE0E6),
                    foregroundColor: const Color(0xFFFF5F6D),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.access_time),
                  label: const Text(
                    "Choisir une heure",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        selectedDate != null &&
                        selectedTime != null) {
                      final user = FirebaseAuth.instance.currentUser;
                      final datetime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );

                      await FirebaseFirestore.instance
                          .collection('rendezvous')
                          .add({
                        'userId': user?.uid,
                        'participant': participantController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'datetime': datetime,
                        'createdAt': Timestamp.now(),
                      });

                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5F6D),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text(
                    'Ajouter',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }


  // Ajout d'une tâche via une feuille modale
  void _showAddTaskSheet(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter une tâche',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFFF5F6D),      // Couleur principale (header / sélection)
                            onPrimary: Colors.white,        // Texte sur la couleur principale
                            surface: Color(0xFFFFE0E6),      // Fond des boîtes de dialogue
                            onSurface: Colors.black87,      // Texte normal
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: Color(0xFFFF5F6D), // Bouton "Annuler" / "OK"
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE0E6), // rose clair
                  foregroundColor: const Color(0xFFFF5F6D), // texte et icône rose foncé
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.calendar_today),
                label: const Text(
                  "Choisir une date",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('tasks').add({
                      'title': title,
                      'date': selectedDate,
                      'done': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5F6D),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
