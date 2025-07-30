import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_manager_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showVacationSheet(
  BuildContext context, {
  String? vacationId,
  Map<String, dynamic>? vacationData,
}) {
  final pageCtx = context; // contexte parent pour SnackBars après pop

  final formKey = GlobalKey<FormState>();
  final TextEditingController descriptionController = TextEditingController(
    text: vacationData?['description'] ?? '',
  );

  final List<String> personnes = ['Mika', 'Laura', 'Enfants', 'Famille'];
  final Map<String, String> couleurParNom = {
    'Mika': '#4A90E2',
    'Laura': '#F48FB1',
    'Enfants': '#81C784',
    'Famille': '#FFD54F',
  };

  String selectedNom = vacationData?['nom'] ?? 'Famille';
  DateTime? debutDate = (vacationData?['debut'] as Timestamp?)?.toDate();
  DateTime? finDate = (vacationData?['fin'] as Timestamp?)?.toDate();

  // petit helper
  Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // icône selon saison de la date de début
  IconData seasonIcon(DateTime? d) {
    if (d == null) return Icons.flight_takeoff;
    final m = d.month;
    if (m >= 6 && m <= 8) return Icons.beach_access;
    if (m == 12 || m <= 2) return Icons.ac_unit;
    if (m >= 3 && m <= 5) return Icons.local_florist;
    return Icons.terrain;
  }

  InputDecoration decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
    );
  }

  showModalBottomSheet(
    context: pageCtx,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) {
      bool saving = false;

      return StatefulBuilder(
        builder: (ctx, setModal) {
          final accent = fromHex(couleurParNom[selectedNom]!);
          final icon = seasonIcon(debutDate);
          final df = DateFormat('dd MMM', 'fr_FR');

          // Durée (si 2 dates valides)
          int? duration;
          if (debutDate != null && finDate != null) {
            duration = finDate!.difference(debutDate!).inDays + 1;
          }

          Future<void> pickStart() async {
            final picked = await CustomPickers.showCustomDatePicker(
              sheetCtx,
              initialDate: debutDate ?? DateTime.now(),
            );
            if (picked != null) {
              setModal(() {
                debutDate = picked;
                if (finDate != null && finDate!.isBefore(debutDate!)) {
                  finDate = debutDate; // aligne si fin < début
                }
              });
            }
          }

          Future<void> pickEnd() async {
            final base = finDate ?? (debutDate ?? DateTime.now());
            final picked = await CustomPickers.showCustomDatePicker(
              sheetCtx,
              initialDate: base,
            );
            if (picked != null) {
              setModal(() {
                if (debutDate != null && picked.isBefore(debutDate!)) {
                  finDate = debutDate;
                } else {
                  finDate = picked;
                }
              });
            }
          }

          Future<void> delete() async {
            if (vacationId == null || saving) return;
            setModal(() => saving = true);
            try {
              await FirebaseFirestore.instance
                  .collection('vacations')
                  .doc(vacationId)
                  .delete();
              if (pageCtx.mounted) {
                Navigator.of(sheetCtx).pop();
                ScaffoldMessenger.of(pageCtx).showSnackBar(
                  const SnackBar(content: Text('Vacances supprimées')),
                );
              }
            } catch (e) {
              if (pageCtx.mounted) {
                ScaffoldMessenger.of(
                  pageCtx,
                ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
              }
            } finally {
              if (pageCtx.mounted) setModal(() => saving = false);
            }
          }

          Future<void> save() async {
            if (saving) return;
            if (!formKey.currentState!.validate()) return;
            if (debutDate == null || finDate == null) {
              ScaffoldMessenger.of(sheetCtx).showSnackBar(
                const SnackBar(content: Text('Sélectionne les dates')),
              );
              return;
            }

            setModal(() => saving = true);
            try {
              final vacation = {
                'nom': selectedNom,
                'description': descriptionController.text.trim(),
                'debut': Timestamp.fromDate(
                  DateTime(
                    debutDate!.year,
                    debutDate!.month,
                    debutDate!.day,
                    0,
                    0,
                  ),
                ),
                'fin': Timestamp.fromDate(
                  DateTime(finDate!.year, finDate!.month, finDate!.day, 23, 59),
                ),
                'couleur': couleurParNom[selectedNom],
              };

              final col = FirebaseFirestore.instance.collection('vacations');
              if (vacationId == null) {
                await col.add(vacation);
              } else {
                await col.doc(vacationId).update(vacation);
              }

              if (pageCtx.mounted) {
                Navigator.of(sheetCtx).pop();
                ScaffoldMessenger.of(pageCtx).showSnackBar(
                  SnackBar(
                    content: Text(
                      vacationId == null
                          ? 'Vacances enregistrées'
                          : 'Vacances modifiées',
                    ),
                  ),
                );
              }
            } catch (e) {
              if (pageCtx.mounted) {
                ScaffoldMessenger.of(
                  pageCtx,
                ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
              }
            } finally {
              if (pageCtx.mounted) setModal(() => saving = false);
            }
          }

          Widget pillButton({
            required IconData i,
            required String label,
            required VoidCallback onTap,
          }) {
            return Material(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(i, color: accent, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header compact
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: accent),
                        ),
                        title: Text(
                          vacationId == null
                              ? 'Ajouter des vacances'
                              : 'Modifier les vacances',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: const Text(
                          'Renseigne les informations ci-dessous',
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Personne
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.group,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: personnes.map((p) {
                                  final selected = p == selectedNom;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(p),
                                      selected: selected,
                                      labelStyle: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: selected
                                            ? const Color(0xFF9A3412)
                                            : const Color(0xFF475569),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        side: BorderSide(
                                          color: selected
                                              ? const Color(0xFFFFD1B5)
                                              : const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      selectedColor: const Color(0xFFFFEDD5),
                                      backgroundColor: const Color(0xFFF8FAFC),
                                      onSelected: (_) =>
                                          setModal(() => selectedNom = p),
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
                      const SizedBox(height: 10),

                      // Description
                      TextFormField(
                        controller: descriptionController,
                        decoration: decoration(
                          'Description',
                          icon: Icons.description,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 12),

                      // Dates (pills)
                      Row(
                        children: [
                          Expanded(
                            child: pillButton(
                              i: Icons.calendar_today,
                              label: debutDate != null
                                  ? 'Début : ${df.format(debutDate!)}'
                                  : 'Date début',
                              onTap: pickStart,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: pillButton(
                              i: Icons.calendar_today_outlined,
                              label: finDate != null
                                  ? 'Fin : ${df.format(finDate!)}'
                                  : 'Date fin',
                              onTap: pickEnd,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Résumé dates + durée
                      if (debutDate != null && finDate != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${df.format(debutDate!)} → ${df.format(finDate!)}'
                                '${duration != null ? ' • $duration jours' : ''}',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        children: [
                          if (vacationId != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Supprimer'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(
                                    color: Color(0xFFFCA5A5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: saving ? null : delete,
                              ),
                            ),
                          if (vacationId != null) const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(
                                vacationId == null ? 'Enregistrer' : 'Modifier',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0EA5E9),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: saving ? null : save,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
