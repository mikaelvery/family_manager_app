import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

Future<void> pickAndUploadDocument(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result != null && result.files.single.path != null) {
    final file = File(result.files.single.path!);
    final fileName = path.basename(file.path);

    // Demande à l'utilisateur la description et le prénom
    // ignore: use_build_context_synchronously
    final data = await _askForDescriptionAndPersonName(context);
    if (data == null || data['description'] == null || data['description']!.isEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description obligatoire')),
      );
      return;
    }

    final description = data['description']!;
    final personName = data['personName'] ?? '';

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('documents/$fileName');

    try {
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Sauvegarde dans Firestore avec description et prénom
      await FirebaseFirestore.instance
          .collection('documents')
          .add({
        'name': fileName,
        'url': downloadUrl,
        'uploadedAt': Timestamp.now(),
        'userId': user.uid,
        'description': description,
        'personName': personName,
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document ajouté avec succès !')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'ajout du document')),
      );
    }
  }
}

Future<Map<String, String>?> _askForDescriptionAndPersonName(BuildContext context) async {
  final descriptionController = TextEditingController();
  final personNameController = TextEditingController();

  return await showDialog<Map<String, String>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFF7F7F7),
        title: const Text(
          'Infos du document',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Ex: CNI, Passeport, Mutuelle',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: personNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom de la personne liée',
                hintText: 'Ex: Mika',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final description = descriptionController.text.trim();
              final personName = personNameController.text.trim();

              if (description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Description obligatoire')),
                );
                return;
              }
              Navigator.of(context).pop({
                'description': description,
                'personName': personName,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAFE9CE),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Valider'),
          ),
        ],
      );
    },
  );
}
