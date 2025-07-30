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
      backgroundColor: const Color(0xFFF6F7FB),
      body: Column(
        children: [
          // ======== HEADER ========
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

          // ======== LISTE ========
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
                  return const _LoadingState();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const _EmptyState(message: 'Aucun rendez-vous prévu');
                }

                final items = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final doc = items[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final participant = (data['participant'] ?? '').toString();
                    final description = (data['description'] ?? '').toString();
                    final medecin = (data['medecin'] ?? '').toString();
                    final dt = (data['datetime'] as Timestamp).toDate();

                    return AppointmentCard(
                      id: doc.id,
                      participant: participant,
                      description: description,
                      datetime: dt,
                      medecin: medecin,
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

/* ===================== Carte Rendez-vous ===================== */

class AppointmentCard extends StatelessWidget {
  final String id;
  final String participant;
  final String description;
  final DateTime datetime;
  final String medecin;

  const AppointmentCard({
    super.key,
    required this.id,
    required this.participant,
    required this.description,
    required this.datetime,
    required this.medecin,
  });

  Color _tintFor(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('dent')) return const Color(0xFFEF4444); 
    if (d.contains('opht') || d.contains('orthopt')) {
      return const Color(0xFF0EA5E9); 
    }
    if (d.contains('kin')) return const Color(0xFFF59E0B); 
    if (d.contains('psy')) return const Color(0xFF8B5CF6); 
    if (d.contains('derm')) return const Color(0xFF10B981); 
    if (d.contains('cardio')) return const Color(0xFFDC2626); 
    if (d.contains('orl')) return const Color(0xFF06B6D4); 
    if (d.contains('gyn')) return const Color(0xFFF472B6);
    if (d.contains('pédi') || d.contains('pedi')) {
      return const Color(0xFF22C55E);
    }
    return const Color(0xFF4F46E5);
  }

  IconData _iconFor(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('dent') || d.contains('orthod')) {
      return FontAwesomeIcons.tooth;
    }
    if (d.contains('opht') || d.contains('orthopt')) return Icons.visibility;
    if (d.contains('kin')) return FontAwesomeIcons.personRunning;
    if (d.contains('psy')) return Icons.psychology;
    if (d.contains('derm')) return Icons.spa;
    if (d.contains('cardio')) return FontAwesomeIcons.heartPulse;
    if (d.contains('orl')) return Icons.hearing;
    if (d.contains('gyn')) return Icons.female;
    if (d.contains('sage-femme')) return FontAwesomeIcons.baby;
    if (d.contains('neuro')) return FontAwesomeIcons.brain;
    return Icons.event; // fallback
  }

  String _capitalizeSentence(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _tintFor(description);
    final icon = _iconFor(description);

    final formattedDate = _capitalizeSentence(
      DateFormat('EEEE dd MMMM', 'fr_FR').format(datetime),
    );
    final formattedTime = DateFormat('HH:mm').format(datetime);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showActions(context, accent),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEAECEF)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                blurRadius: 12,
                offset: Offset(0, 8),
                color: Color(0x0F000000),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne 1 : Participant + badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            participant.isEmpty ? 'Famille' : participant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            description.isEmpty ? 'Rendez-vous' : description,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Ligne 2 : date + heure
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            formattedDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedTime,
                          style: const TextStyle(color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Ligne 3 : praticien
                    if (medecin.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Dr $medecin',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _showActions(context, accent),
                tooltip: 'Options',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, Color accent) async {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final dateStr = DateFormat(
          'dd MMM yyyy • HH:mm',
          'fr_FR',
        ).format(datetime);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconFor(description), color: accent),
                  ),
                  title: Text(
                    (description.isEmpty ? 'Rendez-vous' : description),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${participant.isEmpty ? "Famille" : participant} • $dateStr',
                  ),
                ),
                const SizedBox(height: 8),

                // Modifier
                _ActionRow(
                  icon: Icons.edit,
                  label: 'Modifier le rendez-vous',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final snap = await FirebaseFirestore.instance
                        .collection('rendezvous')
                        .doc(id)
                        .get();
                    if (snap.exists && ctx.mounted) {
                      // ignore: use_build_context_synchronously
                      showEditRendezVousSheet(context, id, snap.data()!);
                    }
                  },
                ),

                const SizedBox(height: 8),

                // Supprimer
                _ActionRow(
                  icon: Icons.delete_outline,
                  label: 'Supprimer le rendez-vous',
                  danger: true,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      await FirebaseFirestore.instance
                          .collection('rendezvous')
                          .doc(id)
                          .delete();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rendez-vous supprimé')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur lors de la suppression : $e'),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ===================== Composants UI réutilisables ===================== */

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFDC2626) : const Color(0xFF0F172A);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEAECEF)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 6),
              color: Color(0x0F000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? message;
  const _EmptyState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message ?? 'Aucun rendez-vous',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
