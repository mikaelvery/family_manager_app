import 'package:family_manager_app/widgets/auto_complete_medicine.dart';
import 'package:family_manager_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

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
  bool _isSubmitting = false;

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
    return const Color(0xFF4F46E5);
  }

  IconData _iconFor(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('dent') || d.contains('orthod')) {
      return Icons.medical_services_outlined;
    }
    if (d.contains('opht') || d.contains('orthopt')) return Icons.visibility;
    if (d.contains('kin')) return Icons.directions_run;
    if (d.contains('psy')) return Icons.psychology;
    if (d.contains('derm')) return Icons.spa;
    if (d.contains('cardio')) return Icons.favorite;
    if (d.contains('orl')) return Icons.hearing;
    if (d.contains('gyn')) return Icons.female;
    return Icons.event;
  }

  InputDecoration _inputDeco({required String label, IconData? icon}) {
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

  @override
  void initState() {
    super.initState();

    if (widget.rendezVousData != null) {
      participantController.text = widget.rendezVousData!['participant'] ?? '';
      descriptionController.text = widget.rendezVousData!['description'] ?? '';
      medecinController.text = widget.rendezVousData!['medecin'] ?? '';

      final ts = widget.rendezVousData!['datetime'] as Timestamp?;
      final dt = ts?.toDate();
      if (dt != null) {
        selectedDate = DateTime(dt.year, dt.month, dt.day);
        selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
    }
  }

  @override
  void dispose() {
    participantController.dispose();
    descriptionController.dispose();
    medecinController.dispose();
    super.dispose();
  }

  /* --------------------------------- Pickers --------------------------------- */

  Future<void> _pickDate() async {
    final picked = await CustomPickers.showCustomDatePicker(
      context,
      initialDate: selectedDate ?? DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await CustomPickers.showCustomTimePicker(
      context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => selectedTime = picked);
    }
  }

  DateTime? _mergeDateTime() {
    if (selectedDate == null || selectedTime == null) return null;
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  /* ----------------------------- Create / Update ----------------------------- */

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    if (!formKey.currentState!.validate() ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseigne tous les champs, la date et l’heure'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final datetime = _mergeDateTime()!;

      // Ajout automatique du médecin si absent
      final nameMedecin = medecinController.text.trim();
      final medecinsCollection = FirebaseFirestore.instance.collection(
        'medecins',
      );
      final querySnapshot = await medecinsCollection
          .where('nameLower', isEqualTo: nameMedecin.toLowerCase())
          .get();
      if (querySnapshot.docs.isEmpty && nameMedecin.isNotEmpty) {
        await medecinsCollection.add({
          'name': nameMedecin,
          'nameLower': nameMedecin.toLowerCase(),
        });
      }

      // Participants via .env
      final mikaUid = dotenv.env['MIKA_UID'] ?? '';
      final lauraUid = dotenv.env['LAURA_UID'] ?? '';
      final participants = [
        mikaUid,
        lauraUid,
      ].where((uid) => uid.isNotEmpty).toList();

      // Tokens FCM des participants
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
        'notificationSent2h': false,
      };

      final col = FirebaseFirestore.instance.collection('rendezvous');
      if (widget.rendezVousId == null) {
        dataToSave['createdAt'] = Timestamp.now();
        await col.add(dataToSave);
      } else {
        await col.doc(widget.rendezVousId).update(dataToSave);
      }

      if (!mounted) return;
      Navigator.pop(context); // ferme la sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.rendezVousId == null
                ? 'Rendez-vous ajouté'
                : 'Rendez-vous modifié',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteAppointment() async {
    if (widget.rendezVousId == null) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('rendezvous')
          .doc(widget.rendezVousId!)
          .delete();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rendez-vous supprimé')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /* ----------------------------------- UI ----------------------------------- */

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.rendezVousId != null;

    final accent = _tintFor(descriptionController.text);
    final icon = _iconFor(descriptionController.text);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    isEditing
                        ? 'Modifier un rendez-vous'
                        : 'Ajouter un rendez-vous',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text('Renseigne les informations ci-dessous'),
                ),
                const SizedBox(height: 8),

                // Nom personne
                TextFormField(
                  controller: participantController,
                  decoration: _inputDeco(
                    label: 'Nom de la personne',
                    icon: Icons.person,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Champ requis'
                      : null,
                ),
                const SizedBox(height: 10),

                // Description (dentiste, ORL, …)
                TextFormField(
                  controller: descriptionController,
                  decoration: _inputDeco(
                    label: 'Description (Dentiste, ORL, …)',
                    icon: Icons.description,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Champ requis'
                      : null,
                ),
                const SizedBox(height: 10),

                // Médecin
                AutoCompleteMedecin(controller: medecinController),
                const SizedBox(height: 12),

                // Date + Heure en "pills"
                Row(
                  children: [
                    Expanded(
                      child: _PillButton(
                        icon: Icons.calendar_today,
                        label: selectedDate != null
                            ? DateFormat(
                                'EEEE dd MMM',
                                'fr_FR',
                              ).format(selectedDate!)
                            : 'Choisir une date',
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PillButton(
                        icon: Icons.access_time,
                        label: selectedTime != null
                            ? selectedTime!.format(context)
                            : 'Choisir une heure',
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Boutons d'action
                Row(
                  children: [
                    if (isEditing)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Supprimer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _deleteAppointment,
                        ),
                      ),
                    if (isEditing) const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitForm,
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
  }
}

/* ---------------------------- Composants UI ---------------------------- */

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE0E6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFC2CF)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFF5F6D), size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF5F6D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------- Fonctions d'ouverture ----------------------- */

void showAddRendezVousSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const ShowRendezVousForm(),
  );
}

void showEditRendezVousSheet(
  BuildContext context,
  String id,
  Map<String, dynamic> rendezVousData,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) =>
        ShowRendezVousForm(rendezVousData: rendezVousData, rendezVousId: id),
  );
}

/* ----------------------- Utilitaire ponctuel ------------------------ */

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
