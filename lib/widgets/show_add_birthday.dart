import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showAddBirthdaySheet(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  DateTime? selectedDate;
  bool saving = false;
  const accent = Color(0xFFFF5F6D);

  showModalBottomSheet(
    context: context,
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
            final picked = await showDatePicker(
              context: sheetCtx,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: accent,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setModal(() => selectedDate = picked);
            }
          }

          Future<void> save() async {
            if (saving) return;

            if (!formKey.currentState!.validate()) return;

            if (selectedDate == null) {
              ScaffoldMessenger.of(sheetCtx).showSnackBar(
                const SnackBar(content: Text('Choisis une date de naissance')),
              );
              return;
            }

            setModal(() => saving = true);
            try {
              final name = nameController.text.trim();

              await FirebaseFirestore.instance.collection('birthdays').add({
                'name': name,
                'birthday': Timestamp.fromDate(selectedDate!),
                'createdAt': Timestamp.now(),
              });

              if (context.mounted) {
                Navigator.of(sheetCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Anniversaire enregistré')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
              }
            } finally {
              if (context.mounted) setModal(() => saving = false);
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
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.cake_rounded, color: accent),
                        ),
                        title: const Text(
                          'Ajouter un anniversaire',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: const Text('Nom et date de naissance'),
                      ),
                      const SizedBox(height: 8),

                      // Nom
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          prefixIcon: Icon(Icons.person),
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
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nom requis'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // Date de naissance - bouton date picker
                      GestureDetector(
                        onTap: pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                selectedDate != null
                                    ? DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(selectedDate!)
                                    : 'Choisir une date de naissance',
                                style: TextStyle(
                                  color: selectedDate != null
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

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
                            backgroundColor: accent,
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
