import 'package:family_manager_app/widgets/auto_complete_medicine.dart';
import 'package:family_manager_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ShowRendezVousForm extends StatefulWidget {
  final Map<String, dynamic>? rendezVousData;
  final String? rendezVousId;

  const ShowRendezVousForm({super.key, this.rendezVousData, this.rendezVousId});

  @override
  State<ShowRendezVousForm> createState() => _ShowRendezVousFormState();
}

class _ShowRendezVousFormState extends State<ShowRendezVousForm> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController participantController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController medecinController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool _isSubmitting = false; //

  @override
  void initState() {
    super.initState();

    if (widget.rendezVousData != null) {
      participantController.text = widget.rendezVousData!['participant'] ?? '';
      descriptionController.text = widget.rendezVousData!['description'] ?? '';
      medecinController.text = widget.rendezVousData!['medecin'] ?? '';

      Timestamp timestamp = widget.rendezVousData!['datetime'];
      DateTime dateTime = timestamp.toDate();
      selectedDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      selectedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    }
  }

  @override
  void dispose() {
    participantController.dispose();
    descriptionController.dispose();
    medecinController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await CustomPickers.showCustomDatePicker(
      context,
      initialDate: selectedDate ?? DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await CustomPickers.showCustomTimePicker(
      context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    if (formKey.currentState!.validate() &&
        selectedDate != null &&
        selectedTime != null) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;

        final datetime = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        );

        // Ajout automatique du nouveau médecin s'il n'existe pas
        final nameMedecin = medecinController.text.trim();

        final medecinsCollection = FirebaseFirestore.instance.collection('medecins');
        final querySnapshot = await medecinsCollection
            .where('nameLower', isEqualTo: nameMedecin.toLowerCase())
            .get();

        if (querySnapshot.docs.isEmpty && nameMedecin.isNotEmpty) {
          await medecinsCollection.add({
            'name': nameMedecin,
            'nameLower': nameMedecin.toLowerCase(),
          });
        }


        // Préparation des participants
        final mikaUid = dotenv.env['MIKA_UID'] ?? '';
        final lauraUid = dotenv.env['LAURA_UID'] ?? '';
        final participants = [
          mikaUid,
          lauraUid,
        ].where((uid) => uid.isNotEmpty).toList();

        // Récupération des tokens FCM pour les participants
        final tokens = <String>[];
        for (final uid in participants) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          final fcmToken = doc.data()?['fcmToken'];
          if (fcmToken != null && !tokens.contains(fcmToken)) {
            tokens.add(fcmToken);
          }
        }

        final dataToSave = {
          'userId': user?.uid,
          'participant': participantController.text.trim(),
          'description': descriptionController.text.trim(),
          'medecin': nameMedecin,
          'datetime': Timestamp.fromDate(datetime),
          'participants': participants,
          'tokens': tokens,
          'notificationSent24h': false,
        };

        // Ajout uniquement à la création
        if (widget.rendezVousId == null) {
          dataToSave['createdAt'] = Timestamp.now();
          await FirebaseFirestore.instance
              .collection('rendezvous')
              .add(dataToSave);
        } else {
          await FirebaseFirestore.instance
              .collection('rendezvous')
              .doc(widget.rendezVousId)
              .update(dataToSave);
        }

        if (context.mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        // Gestion d'erreur si nécessaire, par exemple un SnackBar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // On choisit le titre selon si on modifie ou ajoute
    final bool isEditing = widget.rendezVousId != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 16,
        right: 16,
      ),
        child: Form(
          key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing
                      ? 'Modifier un rendez-vous'
                      : 'Ajouter un rendez-vous',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: participantController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la personne',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
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
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
                AutoCompleteMedecin(controller: medecinController),
            const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickDate,
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
                    selectedDate != null
                        ? "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}"
                        : "Choisir une date",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _pickTime,
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
                    selectedTime != null
                        ? selectedTime!.format(context)
                        : "Choisir une heure",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5F6D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Modifier' : 'Ajouter',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
        ),
      ),
    );
  }
}

// Fonction pour afficher la feuille modale d'ajout de rendez-vous
void showAddRendezVousSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const ShowRendezVousForm(),
  );
}

// Fonction pour afficher la feuille modale d'édition de rendez-vous
void showEditRendezVousSheet(BuildContext context, String id, Map<String, dynamic> rendezVousData) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ShowRendezVousForm(
      rendezVousData: rendezVousData,
      rendezVousId: id,
    ),
  );
}

void addMissingNameLower() async {
  final docs = await FirebaseFirestore.instance.collection('medecins').get();
  for (final doc in docs.docs) {
    final data = doc.data();
    if (!data.containsKey('nameLower') && data['name'] != null) {
      await doc.reference.update({
        'nameLower': (data['name'] as String).toLowerCase(),
      });
    }
  }
}

