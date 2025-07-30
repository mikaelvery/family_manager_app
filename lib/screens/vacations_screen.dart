import 'package:family_manager_app/widgets/show_addvacation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VacationsScreen extends StatefulWidget {
  const VacationsScreen({super.key});

  @override
  State<VacationsScreen> createState() => _VacationsScreenState();
}

class _VacationsScreenState extends State<VacationsScreen> {
  int selectedYear = DateTime.now().year;
  final List<int> availableYears = List.generate(
    5,
    (i) => DateTime.now().year - 1 + i,
  );
  final DateFormat dateFormat = DateFormat('dd MMM', 'fr_FR');
  String selectedPerson = 'Tous';
  final List<String> availablePersons = [
    'Tous',
    'Laura',
    'Mika',
    'Enfants',
    'Famille',
  ];

  Stream<QuerySnapshot> getVacationsStream() {
    Query query = FirebaseFirestore.instance
        .collection('vacations')
        .where(
          'debut',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(selectedYear, 1, 1),
          ),
        )
        .where(
          'debut',
          isLessThan: Timestamp.fromDate(DateTime(selectedYear + 1, 1, 1)),
        );

    if (selectedPerson != 'Tous') {
      query = query.where('nom', isEqualTo: selectedPerson);
    }
    return query.orderBy('debut').snapshots();
  }

  Color _fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Couleur par saison
  Color _seasonTint(DateTime start) {
    final m = start.month;
    if (m >= 6 && m <= 8) return const Color(0xFFF59E0B); 
    if (m == 12 || m <= 2) return const Color(0xFF0EA5E9); 
    if (m >= 3 && m <= 5) {
      return const Color(0xFF10B981); 
    }
    return const Color(0xFF8B5CF6); // automne -> violet
  }

  IconData _seasonIcon(DateTime start) {
    final m = start.month;
    if (m >= 6 && m <= 8) return Icons.beach_access;
    if (m == 12 || m <= 2) return Icons.ac_unit;
    if (m >= 3 && m <= 5) return Icons.local_florist;
    return Icons.flight_takeoff;
  }

  String _monthLabel(DateTime d) =>
      DateFormat('MMMM yyyy', 'fr_FR').format(DateTime(d.year, d.month));

  void _openFiltersSheet() {
    final pageCtx = context; // sécurise le contexte parent

    showModalBottomSheet(
      context: pageCtx,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        int tempYear = selectedYear;
        String tempPerson = selectedPerson;

        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.tune, size: 20, color: Color(0xFF0F172A)),
                        SizedBox(width: 8),
                        Text(
                          'Filtres',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sélecteur Année (mini)
                    Row(
                      children: [
                        const Icon(
                          Icons.event,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        _MiniYearStepper(
                          selectedYear: tempYear,
                          availableYears: availableYears,
                          onChange: (y) => setLocal(() => tempYear = y),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Personne
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.group,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: availablePersons.map((p) {
                                final selected = p == tempPerson;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(p),
                                    selected: selected,
                                    labelStyle: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: selected
                                          ? const Color(0xFF9A3412)
                                          : const Color(0xFF475569),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                      side: BorderSide(
                                        color: selected
                                            ? const Color(0xFFFFD1B5)
                                            : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    selectedColor: const Color(0xFFFFEDD5),
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    onSelected: (_) =>
                                        setLocal(() => tempPerson = p),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: const VisualDensity(
                                      horizontal: -3,
                                      vertical: -3,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Appliquer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(sheetCtx).pop();
                          if (!pageCtx.mounted) return;
                          setState(() {
                            selectedYear = tempYear;
                            selectedPerson = tempPerson;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réinitialiser'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => setLocal(() {
                          tempYear = DateTime.now().year;
                          tempPerson = 'Tous';
                        }),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Column(
        children: [
          // HEADER dégradé — trigger de filtres 
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
                          'Mes vacances',
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
                        const Spacer(),
                        // --- Icône filtre ---
                        _HeaderFilterIcon(onTap: _openFiltersSheet),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== Liste groupée par mois =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getVacationsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const _EmptyState();
                }

                // Groupement par mois
                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final debut = (data['debut'] as Timestamp).toDate();
                  final key = _monthLabel(debut);
                  grouped.putIfAbsent(key, () => []).add(d);
                }
                final months = grouped.keys.toList()
                  ..sort((a, b) {
                    final pa = DateFormat('MMMM yyyy', 'fr_FR').parse(a);
                    final pb = DateFormat('MMMM yyyy', 'fr_FR').parse(b);
                    return pa.compareTo(pb);
                  });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: months.length,
                  itemBuilder: (context, i) {
                    final monthLabel = months[i];
                    final monthDocs = grouped[monthLabel]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: monthLabel,
                          count: monthDocs.length,
                        ),
                        const SizedBox(height: 10),
                        ...monthDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final nom = (data['nom'] ?? 'Vacances').toString();
                          final description = (data['description'] ?? '')
                              .toString();
                          final debut = (data['debut'] as Timestamp).toDate();
                          final fin = (data['fin'] as Timestamp).toDate();
                          final colorStr = data['couleur'] as String?;
                          final accent = colorStr != null
                              ? _fromHex(colorStr)
                              : _seasonTint(debut);
                          final icon = _seasonIcon(debut);
                          final durationDays = fin.difference(debut).inDays + 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _VacationCard(
                              id: doc.id,
                              title: nom,
                              description: description,
                              start: debut,
                              end: fin,
                              durationDays: durationDays,
                              accent: accent,
                              icon: icon,
                              onEdit: () async {
                                final snap = await FirebaseFirestore.instance
                                    .collection('vacations')
                                    .doc(doc.id)
                                    .get();
                                if (!context.mounted) return;
                                if (snap.exists) {
                                  // ignore: use_build_context_synchronously
                                  showVacationSheet(
                                    context,
                                    vacationId: doc.id,
                                    vacationData: snap.data()!,
                                  );
                                }
                              },
                              onDelete: () async {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('vacations')
                                      .doc(doc.id)
                                      .delete();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vacances supprimées'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erreur : $e')),
                                  );
                                }
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
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

/* ===================== UI Components ===================== */

class _HeaderFilterIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _HeaderFilterIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 3),
                color: Color(0x22000000),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.tune, size: 18, color: Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

class _MiniYearStepper extends StatelessWidget {
  final int selectedYear;
  final List<int> availableYears;
  final ValueChanged<int> onChange;

  const _MiniYearStepper({
    required this.selectedYear,
    required this.availableYears,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final idx = availableYears.indexOf(selectedYear);

    Widget btn(IconData icon, bool enabled, VoidCallback? onTap) {
      return InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
      );
    }

    return Row(
      children: [
        btn(Icons.remove, idx > 0, () => onChange(availableYears[idx - 1])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            '$selectedYear',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(width: 8),
        btn(
          Icons.add,
          idx < availableYears.length - 1,
          () => onChange(availableYears[idx + 1]),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title[0].toUpperCase() + title.substring(1),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15.5,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _VacationCard extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final int durationDays;
  final Color accent;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VacationCard({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.durationDays,
    required this.accent,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rangeLabel =
        '${DateFormat('dd MMM', 'fr_FR').format(start)} → ${DateFormat('dd MMM', 'fr_FR').format(end)}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showActions(context),
        child: Container(
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
                width: 4,
                height: 96,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: accent, size: 22),
                      ),
                      const SizedBox(width: 10),
                      // Contenu
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre + bouton options
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_horiz),
                                  onPressed: () => _showActions(context),
                                  tooltip: 'Options',
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            if (description.isNotEmpty)
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),

                            const SizedBox(height: 6),

                            // Date + durée
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
                                    rangeLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$durationDays jours',
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final cardContext = context;

    showModalBottomSheet(
      context: cardContext,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        final dateStr =
            '${DateFormat('dd MMM', 'fr_FR').format(start)} → ${DateFormat('dd MMM', 'fr_FR').format(end)}';
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
                    child: Icon(icon, color: accent),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(dateStr),
                ),
                const SizedBox(height: 8),

                _ActionRow(
                  icon: Icons.edit,
                  label: 'Modifier les vacances',
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    final snap = await FirebaseFirestore.instance
                        .collection('vacations')
                        .doc(id)
                        .get();
                    if (!cardContext.mounted) return;
                    if (snap.exists) {
                      // ignore: use_build_context_synchronously
                      showVacationSheet(
                        cardContext,
                        vacationId: id,
                        vacationData: snap.data()!,
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                _ActionRow(
                  icon: Icons.delete_outline,
                  label: 'Supprimer les vacances',
                  danger: true,
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    try {
                      await FirebaseFirestore.instance
                          .collection('vacations')
                          .doc(id)
                          .delete();
                      if (!cardContext.mounted) return;
                      ScaffoldMessenger.of(cardContext).showSnackBar(
                        const SnackBar(content: Text('Vacances supprimées')),
                      );
                    } catch (e) {
                      if (!cardContext.mounted) return;
                      ScaffoldMessenger.of(
                        cardContext,
                      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.beach_access, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'Aucune vacances trouvée',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
