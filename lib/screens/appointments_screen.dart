import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_manager_app/widgets/show_rendezvous_form.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // HEADER
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
              bottom: 12,
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Retour',
                    ),
                    const SizedBox(width: 32),
                    Text(
                      'Mes rendez-vous',
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
          ),

          // LISTE DES RENDEZ-VOUS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rendezvous')
                  .where(
                    'datetime',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
                  )
                  .orderBy('datetime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun rendez-vous prévu',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  );
                }

                final rendezvous = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  itemCount: rendezvous.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final data = rendezvous[index];
                    final participant = data['participant'] ?? '';
                    final description = data['description'] ?? '';
                    final datetime = (data['datetime'] as Timestamp).toDate();
                    final medecin = data['medecin'] ?? '';

                    return AppointmentCard(
                      id: data.id,
                      participant: participant,
                      description: description,
                      datetime: datetime,
                      medecin: medecin,
                      theme: theme,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget séparé pour une carte rendez-vous
class AppointmentCard extends StatelessWidget {
  final String id;
  final String participant;
  final String description;
  final DateTime datetime;
  final String medecin;
  final ThemeData theme;

  const AppointmentCard({
    required this.id,
    required this.participant,
    required this.description,
    required this.datetime,
    required this.medecin,
    required this.theme,
    super.key,
  });

  /// Maps descriptions to icons
  static const Map<String, IconData> _iconMap = {
    'dentiste': FontAwesomeIcons.tooth,
    'angiologue': Icons.healing,
    'orthodontiste': FontAwesomeIcons.tooth,
    'docteur': FontAwesomeIcons.userDoctor,
    'médecin': FontAwesomeIcons.userDoctor,
    'kiné': FontAwesomeIcons.personRunning,
    'kine': FontAwesomeIcons.personRunning,
    'kinésithérapeute': FontAwesomeIcons.personRunning,
    'ophtalmologue': Icons.visibility,
    'orthophoniste': Icons.record_voice_over,
    'ortho': Icons.record_voice_over,
    'ergothérapeute': Icons.psychology,
    'ergo': Icons.psychology,
    'psychologue': Icons.psychology,
    'psy': Icons.psychology,
    'chirurgien': Icons.health_and_safety,
    'hopital': Icons.medical_services,
    'hôpital': Icons.medical_services,
    'anesthésiste': Icons.medical_services,
    'neurologue': FontAwesomeIcons.brain,
    'gynécologue': Icons.female,
    'gynéco': Icons.female,
    'sage-femme': FontAwesomeIcons.baby,
    'dermatologue': Icons.spa,
    'dermato': Icons.spa,
    'cardiologue': FontAwesomeIcons.heartPulse,
    'urologue': FontAwesomeIcons.person,
    'orl': Icons.hearing,
    'rhumatologue': FontAwesomeIcons.bone,
    'pédiatre': FontAwesomeIcons.child,
    'gastro-entérologue': Icons.local_dining,
    'pneumologue': FontAwesomeIcons.lungs,
    'endocrinologue': FontAwesomeIcons.dna,
    'infirmier': FontAwesomeIcons.syringe,
    'infirmière': FontAwesomeIcons.syringe,
    'ostéopathe': Icons.self_improvement,
    'ostéo': Icons.self_improvement,
    'podologue': FontAwesomeIcons.shoePrints,
    'diététicien': Icons.restaurant,
    'diét': Icons.restaurant,
    'orthoptiste': Icons.remove_red_eye,
    'psychomotricien': Icons.psychology,
    'assistant social': Icons.group,
  };

  /// Maps descriptions to colors
  static const Map<String, Color> _colorMap = {
    'dentiste': Colors.deepPurple,
    'angiologue': Colors.green,
    'orthodontiste': Colors.blue,
    'docteur': Colors.redAccent,
    'médecin': Colors.redAccent,
    'kiné': Colors.orange,
    'kine': Colors.orange,
    'kinésithérapeute': Colors.orange,
    'ophtalmologue': Colors.indigo,
    'orthophoniste': Colors.teal,
    'ortho': Colors.teal,
    'ergothérapeute': Colors.pink,
    'ergo': Colors.pink,
    'psychologue': Colors.amber,
    'psy': Colors.amber,
    'chirurgien': Colors.brown,
    'hopital': Colors.purple,
    'hôpital': Colors.purple,
    'anesthésiste': Colors.purple,
    'neurologue': Colors.cyan,
    'gynécologue': Colors.pinkAccent,
    'gynéco': Colors.pinkAccent,
    'sage-femme': Colors.lightBlue,
    'dermatologue': Colors.brown,
    'dermato': Colors.brown,
    'cardiologue': Colors.red,
    'urologue': Colors.blueGrey,
    'orl': Colors.cyan,
    'rhumatologue': Colors.deepOrange,
    'pédiatre': Colors.greenAccent,
    'gastro-entérologue': Colors.indigoAccent,
    'pneumologue': Colors.teal,
    'endocrinologue': Colors.deepPurple,
    'infirmier': Colors.lightGreen,
    'infirmière': Colors.lightGreen,
    'ostéopathe': Colors.orangeAccent,
    'ostéo': Colors.orangeAccent,
    'podologue': Colors.brown,
    'diététicien': Colors.lime,
    'diét': Colors.lime,
    'orthoptiste': Colors.blueGrey,
    'psychomotricien': Colors.amber,
    'assistant social': Colors.grey,
  };

  IconData _getIcon() {
    final desc = description.toLowerCase();
    for (final key in _iconMap.keys) {
      if (desc.contains(key)) {
        return _iconMap[key]!;
      }
    }
    return Icons.event;
  }

  Color _getColor() {
    final desc = description.toLowerCase();
    for (final key in _colorMap.keys) {
      if (desc.contains(key)) {
        return _colorMap[key]!;
      }
    }
    return Colors.grey;
  }

  String _capitalizeSentence(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getColor();
    final icon = _getIcon();

    // Date format
    final formattedDate = _capitalizeSentence(
      DateFormat('EEEE dd MMMM', 'fr_FR').format(datetime),
    );
    final formattedTime = DateFormat('HH:mm').format(datetime);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withValues(alpha: 0.2),
        onTap: () async {
          final action = await showModalBottomSheet<String>(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.edit, color: iconColor),
                    title: const Text('Modifier le rendez-vous'),
                    onTap: () => Navigator.pop(context, 'edit'),
                  ),
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: const Text('Supprimer le rendez-vous'),
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                  ListTile(
                    leading: Icon(Icons.close),
                    title: const Text('Annuler'),
                    onTap: () => Navigator.pop(context, null),
                  ),
                ],
              ),
            ),
          );

          if (action == 'delete') {
            try {
              await FirebaseFirestore.instance
                  .collection('rendezvous')
                  .doc(id)
                  .delete();
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rendez-vous supprimé')),
              );
            } catch (e) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur lors de la suppression: $e')),
              );
            }
          } else if (action == 'edit') {
            final docSnapshot = await FirebaseFirestore.instance
                .collection('rendezvous')
                .doc(id)
                .get();
            if (docSnapshot.exists) {
              // ignore: use_build_context_synchronously
              showEditRendezVousSheet(context, id, docSnapshot.data()!);
            }
          }
        },

        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icone dans cercle avec accessibilité
              Semantics(
                label: 'Type de rendez-vous: $description',
                child: Container(
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
              ),
              const SizedBox(width: 20),
              // Infos rendez-vous
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Participant + badge description
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            participant,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: iconColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Date et heure
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black87.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedTime,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black87.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Nom du médecin
                    Row(
                      children: [
                        const Icon(Icons.person, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "Dr $medecin",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black87.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
