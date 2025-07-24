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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          padding: const EdgeInsets.only(
            top: 38,
            left: 20,
            right: 20,
            bottom: 18,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Retour',
              ),
              const SizedBox(width: 8),
              Text(
                'Mes rendez-vous',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            itemCount: rendezvous.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = rendezvous[index];
              final participant = data['participant'] ?? '';
              final description = data['description'] ?? '';
              final datetime = (data['datetime'] as Timestamp).toDate();

              return AppointmentCard(
                id: data.id, 
                participant: participant,
                description: description,
                datetime: datetime,
                theme: theme,
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget séparé pour une carte rendez-vous
class AppointmentCard extends StatelessWidget {
  final String id;
  final String participant;
  final String description;
  final DateTime datetime;
  final ThemeData theme;

  const AppointmentCard({
    required this.id,
    required this.participant,
    required this.description,
    required this.datetime,
    required this.theme,
    super.key,
  });

  /// Maps descriptions to icons
  static const Map<String, IconData> _iconMap = {
    'dentiste': FontAwesomeIcons.tooth,
    'angiologue': Icons.healing,
    'orthodontiste': Icons.masks,
    'docteur': Icons.local_hospital,
    'médecin': Icons.local_hospital,
    'kiné': FontAwesomeIcons.personRunning,
    'kine': FontAwesomeIcons.personRunning,
    'ophtalmologue': Icons.visibility,
    'orthophoniste': Icons.record_voice_over,
    'ergothérapeute': Icons.psychology,
    'ergo': Icons.psychology,
    'psychologue': Icons.psychology,
    'chirurgien': Icons.health_and_safety,
    'hopital': Icons.medical_services,
    'hôpital': Icons.medical_services,
    'anesthésiste': Icons.medical_services,
    'neurologue': FontAwesomeIcons.brain,
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
    'ophtalmologue': Colors.indigo,
    'orthophoniste': Colors.teal,
    'ergothérapeute': Colors.pink,
    'ergo': Colors.pink,
    'psychologue': Colors.amber,
    'chirurgien': Colors.brown,
    'hopital': Colors.purple,
    'hôpital': Colors.purple,
    'anesthésiste': Colors.purple,
    'neurologue': Colors.cyan,
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
