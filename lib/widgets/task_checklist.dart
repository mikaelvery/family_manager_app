import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:family_manager_app/widgets/custom_pickers.dart';

Widget taskChecklist(BuildContext context) {
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

      if (tasks.isEmpty) {
        return const Center(
          child: Text(
            'Aucune tâche pour le moment.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        );
      }

      final now = DateTime.now();
      final filteredTasks = tasks.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final done = data['done'] ?? false;
        final reminder = data['reminder'] ?? false;
        final reminderTimestamp = data['reminderDateTime'] as Timestamp?;
        final taskTimestamp = data['date'] as Timestamp?;
        final reminderDateTime = reminderTimestamp?.toDate();
        final taskDate = taskTimestamp?.toDate();

        if (done) return true;

        if (reminder) {
          if (reminderDateTime != null) {
            return reminderDateTime.isAfter(now);
          } else {
            return false;
          }
        }

        if (taskDate != null) {
          return taskDate.isAfter(now);
        }

        return true;
      }).toList();

      if (filteredTasks.isEmpty) {
        return const Center(
          child: Text(
            'Aucune tâche pour aujourd\'hui.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(filteredTasks.length, (index) {
            final doc = filteredTasks[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final done = data['done'] ?? false;
            final date = (data['date'] as Timestamp?)?.toDate();

            String? formattedDate;
            if (date != null) {
              formattedDate = DateFormat('d MMMM', 'fr_FR').format(date);
            }

            String? formattedTime;
            if (data['reminderDateTime'] != null) {
              final reminderDateTime = (data['reminderDateTime'] as Timestamp)
                  .toDate();
              formattedTime = DateFormat('HH:mm').format(reminderDateTime);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      customCheckbox(done, (value) {
                        FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(doc.id)
                            .update({'done': value});
                      }),
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: done ? Colors.grey.shade500 : Colors.black87,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.blueGrey,
                        ),
                        tooltip: 'Détail',
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
                                  fontSize: 20,
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Fermer',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Supprimer',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: const Text(
                                'Souhaitez-vous vraiment supprimer cette tâche ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('tasks')
                                        .doc(doc.id)
                                        .delete();
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (data['reminder'] == true)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Rappel',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (formattedDate != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          if (formattedTime != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (index < filteredTasks.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Divider(color: Colors.black12, thickness: 1),
                    ),
                ],
              ),
            );
          }),
        ),
      );
    },
  );
}

// Checkbox custom amélioré aussi
Widget customCheckbox(bool value, void Function(bool?) onChanged) {
  return GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFFF5F6D) : Colors.transparent,
        border: Border.all(
          color: value ? const Color(0xFFFF5F6D) : Colors.grey.shade400,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: value
            ? [
                BoxShadow(
                  color: const Color(0xFFFF5F6D).withValues(alpha: 0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: value
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    ),
  );
}

// Fonction pour afficher la feuille modale d'ajout de tâche
void showAddTaskSheet(BuildContext context) {
  final pageCtx = context; // Contexte parent pour SnackBars après pop

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool isReminder = false;
  bool saving = false;

  const accent = Color(0xFFFF5F6D);

  showModalBottomSheet(
    context: pageCtx,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> pickDate() async {
            final picked = await CustomPickers.showCustomDatePicker(
              sheetCtx,
              initialDate: selectedDate ?? DateTime.now(),
              accent: accent,
            );
            if (picked != null) {
              setModal(() => selectedDate = picked);
              // si on a l’heure mais pas la date, on garde l’heure ; sinon rien à faire
            }
          }

          Future<void> pickTime() async {
            final picked = await CustomPickers.showCustomTimePicker(
              sheetCtx,
              initialTime: selectedTime ?? TimeOfDay.now(),
              accent: accent,
            );
            if (picked != null) setModal(() => selectedTime = picked);
          }

          Future<void> save() async {
            if (saving) return;

            if (!formKey.currentState!.validate()) return;

            if (isReminder) {
              // Rappel = nécessite date + heure
              if (selectedDate == null || selectedTime == null) {
                ScaffoldMessenger.of(sheetCtx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Choisis une date et une heure pour le rappel',
                    ),
                  ),
                );
                return;
              }
            }

            setModal(() => saving = true);
            try {
              final title = titleController.text.trim();

              DateTime? reminderLocal;
              if (isReminder && selectedDate != null && selectedTime != null) {
                reminderLocal = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );
              }

              // Participants via .env
              final mikaUid = dotenv.env['MIKA_UID'] ?? '';
              final lauraUid = dotenv.env['LAURA_UID'] ?? '';
              final participants = [
                mikaUid,
                lauraUid,
              ].where((e) => e.isNotEmpty).toList();

              // Tokens FCM
              final tokens = <String>[];
              for (final uid in participants) {
                final doc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get();
                final fcm = doc.data()?['fcmToken'];
                if (fcm != null && !tokens.contains(fcm)) tokens.add(fcm);
              }

              await FirebaseFirestore.instance.collection('tasks').add({
                'title': title,
                'date': selectedDate != null
                    ? Timestamp.fromDate(selectedDate!)
                    : null,
                'done': false,
                'createdAt': FieldValue.serverTimestamp(),
                'reminder': isReminder,
                'reminderDateTime': reminderLocal != null
                    ? Timestamp.fromDate(reminderLocal.toUtc())
                    : null,
                'tokens': tokens,
                'reminderSent': false,
              });

              if (pageCtx.mounted) {
                Navigator.of(sheetCtx).pop(); // ferme la sheet
                ScaffoldMessenger.of(pageCtx).showSnackBar(
                  const SnackBar(content: Text('Tâche enregistrée')),
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
                            // ignore: deprecated_member_use
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.checklist, color: accent),
                        ),
                        title: const Text(
                          'Ajouter une tâche / rappel',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: const Text(
                          'Décris la tâche et, si besoin, planifie un rappel',
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Titre (obligatoire)
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre',
                          prefixIcon: Icon(Icons.title_rounded),
                          filled: true,
                          fillColor: Color(0xFFF9FAFB),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Titre requis'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Date (facultative) — utile même sans rappel
                      _TaskPillButton(
                        icon: Icons.calendar_today,
                        label: selectedDate != null
                            ? 'Date : ${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
                            : 'Choisir une date',
                        accent: accent,
                        onTap: pickDate,
                      ),
                      const SizedBox(height: 8),

                      // Switch "Ceci est un rappel"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              color: accent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Ceci est un rappel',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Switch.adaptive(
                              value: isReminder,
                              activeColor: accent,
                              onChanged: (val) {
                                setModal(() {
                                  isReminder = val;
                                  // On ne force pas la remise à zéro des dates/heures
                                  // mais on exigera date+heure à la sauvegarde.
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      if (isReminder) ...[
                        const SizedBox(height: 8),
                        _TaskPillButton(
                          icon: Icons.access_time,
                          label: selectedTime != null
                              ? 'Heure : ${selectedTime!.format(sheetCtx)}'
                              : 'Choisir une heure',
                          accent: accent,
                          onTap: pickTime,
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Actions
                      SizedBox(
                        width: double.infinity,
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
                          label: const Text('Enregistrer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: saving ? null : save,
                        ),
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

/* -------------------------------------------------------------------------- */
/*                               UI helper pill                               */
/* -------------------------------------------------------------------------- */

class _TaskPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _TaskPillButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      // ignore: deprecated_member_use
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
