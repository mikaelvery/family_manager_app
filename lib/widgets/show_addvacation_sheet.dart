

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_manager_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showVacationSheet(
  BuildContext context, {
  String? vacationId,
  Map<String, dynamic>? vacationData,
}) {
  final formKey = GlobalKey<FormState>();
  final TextEditingController descriptionController =
    TextEditingController(text: vacationData?['description'] ?? '');
  final List<String> personnes = ['Mika', 'Laura', 'Enfants'];
  String selectedNom = vacationData?['nom'] ?? 'Mika';

  DateTime? debutDate =
      (vacationData?['debut'] as Timestamp?)?.toDate();
  DateTime? finDate =
      (vacationData?['fin'] as Timestamp?)?.toDate();

  final Map<String, String> couleurParNom = {
    'Mika': '#4A90E2',
    'Laura': '#F48FB1',
    'Enfants': '#81C784',
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: Colors.white,
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: formKey,
          child: Wrap(
            runSpacing: 16,
            children: [
              Text(
                vacationData == null
                    ? 'Ajouter des vacances'
                    : 'Modifier les vacances',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              DropdownButtonFormField<String>(
                value: selectedNom,
                items: personnes
                    .map((nom) => DropdownMenuItem(
                          value: nom,
                          child: Text(nom),
                        ))
                    .toList(),
                onChanged: (val) => selectedNom = val!,
                decoration: const InputDecoration(labelText: 'Pour'),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'), 
                textCapitalization: TextCapitalization.sentences,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requis' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date =
                            await CustomPickers.showCustomDatePicker(
                          context,
                          initialDate: debutDate ?? DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() {
                            debutDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today,
                          color: Colors.black87),
                      label: Text(
                        debutDate != null
                            ? 'Début : ${DateFormat('dd/MM').format(debutDate!)}'
                            : 'Date début',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        final date =
                            await CustomPickers.showCustomDatePicker(
                          context,
                          initialDate: finDate ?? DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() {
                            finDate = date;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined,
                          color: Colors.black87),
                      label: Text(
                        finDate != null
                            ? 'Fin : ${DateFormat('dd/MM').format(finDate!)}'
                            : 'Date fin',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (debutDate == null || finDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Sélectionne les dates.')),
                      );
                      return;
                    }

                    final vacation = {
                      'nom': selectedNom,
                      'description':
                          descriptionController.text.trim(),
                      'debut': Timestamp.fromDate(debutDate!),
                      'fin': Timestamp.fromDate(finDate!),
                      'couleur': couleurParNom[selectedNom],
                    };

                    final vacationsRef =
                        FirebaseFirestore.instance.collection('vacations');

                    if (vacationId == null) {
                      await vacationsRef.add(vacation);
                    } else {
                      await vacationsRef.doc(vacationId).update(vacation);
                    }

                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5F6D),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    vacationData == null ? 'Enregistrer' : 'Modifier',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

