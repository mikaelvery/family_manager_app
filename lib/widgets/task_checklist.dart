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
            style: TextStyle(color: Colors.grey),
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
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            final reminderDateTime = (data['reminderDateTime'] as Timestamp).toDate();
            formattedTime = DateFormat('HH:mm').format(reminderDateTime);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne titre + checkbox + icônes
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  customCheckbox(done, (value) {
                    FirebaseFirestore.instance
                        .collection('tasks')
                        .doc(doc.id)
                        .update({'done': value});
                  }),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 16,
                        color: done ? Colors.grey : Colors.black87,
                        decoration:
                            done ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
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
                              child: const Text('Fermer'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirmer la suppression'),
                          content: const Text('Souhaitez-vous vraiment supprimer cette tâche ?'),
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

              // Ligne rappel + date + heure
              if (data['reminder'] == true)
                Padding(
                  padding: const EdgeInsets.only(left: 40, right: 8, top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Rappel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Date (si présente)
                      if (formattedDate != null)
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),

                      // Heure si présente
                      if (formattedTime != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 14,
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
                  padding: EdgeInsets.only(top: 12),
                  child: Divider(
                    color: Colors.black26,
                    thickness: 0.6,
                    height: 8,
                  ),
                ),
              ],
            );
          }),
        ),
      );
    },
  );
}

// Fonction pour créer un checkbox personnalisé
Widget customCheckbox(bool value, void Function(bool?) onChanged) {
  return GestureDetector(
    onTap: () => onChanged(!value),
    child: Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFFF5F6D) : Colors.white,
        border: Border.all(
          color: value ? const Color(0xFFFF5F6D) : Colors.black26,
          width: value ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: value
      ? const Center(
          child: Icon(Icons.check, size: 14, color: Colors.white),
        )
      : null,
    ),
  );
}


// Fonction pour afficher la feuille modale d'ajout de tâche
void showAddTaskSheet(BuildContext context) {
  final TextEditingController titleController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime; 
  bool isReminder = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
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
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final DateTime? picked =
                        await CustomPickers.showCustomDatePicker(
                          context,
                          initialDate: DateTime.now(),
                        );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE0E6),
                    foregroundColor: const Color(0xFFFF5F6D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedDate == null
                        ? "Choisir une date"
                        : "Date : ${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isReminder = !isReminder;
                          if (isReminder && selectedDate != null && selectedTime != null) {
                            selectedTime = null;
                          }
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isReminder
                              ? const Color(0xFFFF5F6D)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isReminder
                                ? const Color(0xFFFF5F6D)
                                : Colors.black26,
                            width: isReminder ? 2 : 1,
                          ),
                        ),
                        child: isReminder
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Ceci est un rappel'),
                  ],
                ),
                if (isReminder) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final TimeOfDay? pickedTime =
                          await CustomPickers.showCustomTimePicker(
                            context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                      if (pickedTime != null) {
                        setState(() {
                          selectedTime = pickedTime;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE0E6),
                      foregroundColor: const Color(0xFFFF5F6D),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      selectedTime == null
                          ? "Choisir une heure"
                          : "Heure : ${selectedTime!.format(context)}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isNotEmpty) {
                      DateTime? reminderDateTime;
                      if (isReminder &&
                          selectedDate != null &&
                          selectedTime != null) {
                          reminderDateTime = DateTime(
                          selectedDate!.year,
                          selectedDate!.month,
                          selectedDate!.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );
                      }
                      // Récupérer les UIDs des participants
                      final mikaUid = dotenv.env['MIKA_UID']!;
                      final lauraUid = dotenv.env['LAURA_UID']!;

                      final participants = [mikaUid, lauraUid];
                      final tokens = <String>[];
                      // Récupérer les tokens depuis la collection users pour les participants
                      for (final uid in participants) {
                        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                        final fcmToken = doc.data()?['fcmToken'];
                        if (fcmToken != null && !tokens.contains(fcmToken)) {
                          tokens.add(fcmToken);
                        }
                      }

                      await FirebaseFirestore.instance.collection('tasks').add({
                        'title': title,
                        'date': selectedDate,
                        'done': false,
                        'createdAt': FieldValue.serverTimestamp(),
                        'reminder': isReminder,
                        'reminderDateTime': reminderDateTime,
                        'tokens': tokens,  
                        'notificationSent24h': false,
                      });

                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5F6D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    },
  );
}