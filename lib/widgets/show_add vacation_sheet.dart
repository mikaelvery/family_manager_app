

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_manager_app/widgets/custom_pickers.dart';
import 'package:flutter/material.dart';

void showAddVacationSheet(BuildContext context) {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> personnes = ['Mika', 'Laura', 'Enfants'];
  String selectedNom = 'Mika';

  DateTime? debutDate;
  DateTime? finDate;

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
    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 16,
          children: [
            const Text(
              'Ajouter des vacances',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),

            // Sélecteur de membre
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

            // Champ description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Requis' : null,
            ),

            // Dates
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await CustomPickers.showCustomDatePicker(
                        context,
                        initialDate: DateTime.now(),
                      );
                      if (date != null) {
                        debutDate = date;
                      }
                    },
                    icon: const Icon(Icons.calendar_today, color: Colors.black87),
                    label: Text(
                      debutDate != null
                          ? 'Début : ${debutDate!.day}/${debutDate!.month}/${debutDate!.year}'
                          : 'Date début',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await CustomPickers.showCustomDatePicker(
                        context,
                        initialDate: DateTime.now(),
                      );
                      if (date != null) {
                        finDate = date;
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined,
                        color: Colors.black87),
                    label: Text(
                      finDate != null
                          ? 'Fin : ${finDate!.day}/${finDate!.month}/${finDate!.year}'
                          : 'Date fin',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),

            // Bouton enregistrer
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (debutDate == null || finDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sélectionne les dates.')),
                    );
                    return;
                  }

                  final vacation = {
                    'nom': selectedNom,
                    'description': _descriptionController.text.trim(),
                    'debut': Timestamp.fromDate(debutDate!),
                    'fin': Timestamp.fromDate(finDate!),
                    'couleur': couleurParNom[selectedNom],
                  };

                  await FirebaseFirestore.instance
                      .collection('vacations')
                      .add(vacation);

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF5F6D),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
