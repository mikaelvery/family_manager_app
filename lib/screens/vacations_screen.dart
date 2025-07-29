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
  final List<int> availableYears = List.generate(4, (i) => DateTime.now().year - 1 + i);
  final DateFormat dateFormat = DateFormat('dd MMM', 'fr_FR');
  String selectedPerson = 'Tous';
  final List<String> availablePersons = ['Tous', 'Laura', 'Mika', 'Enfants'];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          // HEADER dégradé avec images et arrondi comme les autres écrans
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
                      'Mes vacances',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Année',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    value: selectedYear,
                    items: availableYears
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedYear = val;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Personne',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    value: selectedPerson,
                    items: availablePersons
                        .map(
                          (person) => DropdownMenuItem(
                            value: person,
                            child: Text(person),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedPerson = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

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

                final vacations = snapshot.data!.docs;

                if (vacations.isEmpty) {
                  return const Center(child: Text('Aucune vacances trouvée'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: vacations.length,
                  itemBuilder: (context, index) {
                    final data =
                        vacations[index].data()! as Map<String, dynamic>;

                    final String nom = data['nom'] ?? 'Vacances';
                    final String description = data['description'] ?? '';
                    final Timestamp debutTs = data['debut'];
                    final Timestamp finTs = data['fin'];
                    final String? couleurStr = data['couleur'];
                    final Color couleur = couleurStr != null
                        ? _fromHex(couleurStr)
                        : Colors.deepPurple;

                    final debutDate = debutTs.toDate();
                    final finDate = finTs.toDate();

                    final durationDays =
                        finDate.difference(debutDate).inDays + 1;

                    // Icône selon la saison (exemple simple)
                    IconData getIcon() {
                      final month = debutDate.month;
                      if (month >= 6 && month <= 8) return Icons.beach_access;
                      if (month >= 12 || month <= 2) return Icons.ac_unit;
                      if (month >= 3 && month <= 5) return Icons.local_florist;
                      return Icons.flight_takeoff;
                    }

                    return Stack(
                      children: [
                        // Timeline verticale
                        Positioned(
                          left: 32,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            color: index == vacations.length - 1
                                ? Colors.transparent
                                : couleur.withValues(alpha: 0.3),
                          ),
                        ),

                        // Carte principale
                        Container(
                          margin: const EdgeInsets.only(left: 48, bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: couleur.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icône à gauche de la carte
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: couleur.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  getIcon(),
                                  size: 24,
                                  color: couleur,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Contenu
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nom + 3 points
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            nom,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, color: Colors.black54),
                                          onSelected: (value) {
                                            final doc = vacations[index]; 
                                            if (value == 'modifier') {
                                              showVacationSheet(
                                                context,
                                                vacationId: doc.id,
                                                vacationData: doc.data() as Map<String, dynamic>,
                                              );
                                            } else if (value == 'supprimer') {
                                              FirebaseFirestore.instance.collection('vacations').doc(doc.id).delete();
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(value: 'modifier', child: Text('Modifier')),
                                            PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
                                          ],
                                        ),
                                      ],
                                    ),                      
                                    const SizedBox(height: 4),

                                    // Description
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.black54),
                                    ),
                                    const SizedBox(height: 8),

                                    // Ligne date + badge aligné droite
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: couleur,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${dateFormat.format(debutDate)} → ${dateFormat.format(finDate)}',
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: couleur.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '$durationDays jours', 
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: couleur,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10.5,
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

                        // Point sur timeline
                        Positioned(
                          left: 18,
                          top: 24,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: couleur,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: couleur.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              getIcon(),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
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

  Color _fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
