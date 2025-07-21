import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});
  
  // Méthode pour télécharger et ouvrir le PDF
  Future<void> _downloadAndOpenPdf(String url) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/document.pdf';

      final response = await Dio().download(url, filePath);

      if (response.statusCode == 200) {
        final result = await OpenFilex.open(filePath);
        debugPrint('Résultat ouverture fichier : ${result.message}');
      } else {
        debugPrint('Échec du téléchargement');
      }
    } catch (e) {
      debugPrint('Erreur ouverture PDF : $e');
    }
  }
  Future<void> _sendEmail(String url, String description, String personName) async {
    final subject = Uri.encodeComponent('Document : $description');
    final body = Uri.encodeComponent('Bonjour,\n\nVoici le document lié à $personName :\n$url');
    final mailtoLink = Uri.parse('mailto:?subject=$subject&body=$body');

    if (await canLaunchUrl(mailtoLink)) {
      await launchUrl(mailtoLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 48, left: 20, right: 20, bottom: 28),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Mes documents',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('documents')
            .orderBy('description')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucun document'));
          }

          final docs = snapshot.data!.docs;

          // Grouper les documents par description
          final Map<String, List<QueryDocumentSnapshot>> groupedDocs = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final description = data['description'] ?? 'Sans description';
            groupedDocs.putIfAbsent(description, () => []).add(doc);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedDocs.length,
            itemBuilder: (context, index) {
              final description = groupedDocs.keys.elementAt(index);
              final documents = groupedDocs[description]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...documents.map((doc) {
                    final docData = doc.data() as Map<String, dynamic>;
                    final String personName = docData.containsKey('personName') &&
                      docData['personName'] != null &&
                      docData['personName'].toString().isNotEmpty
                      ? docData['personName']
                      : 'Famille';
                    final String fileName = docData['name'] ?? 'Nom inconnu';
                    final String url = docData['url'] ?? '';
                    final Timestamp timestamp = docData['uploadedAt'] ?? Timestamp.now();
                    final DateTime date = timestamp.toDate();
                    final String formattedDate =
                      DateFormat('dd MMM yyyy', 'fr_FR').format(date);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFF5F6D),
                            child:
                                Icon(Icons.picture_as_pdf, color: Colors.white),
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(personName),
                              Text('Ajouté le $formattedDate'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFFF7F7F7),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  title: Text(
                                    description,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Document: $fileName'),
                                      const SizedBox(height: 8),
                                      Text('Prénom lié: $personName'),
                                      Text('Ajouté le $formattedDate'),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.open_in_new),
                                        label: const Text('Ouvrir le document'),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          _downloadAndOpenPdf(url);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFAFE9CE),
                                          foregroundColor: Colors.black87,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.email),
                                        label: const Text('Envoyer par mail'),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          _sendEmail(url, description,
                                              personName);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFE0E0E0),
                                          foregroundColor: Colors.black87,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Supprimer'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[400],
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () async {
                                          try {
                                            await FirebaseFirestore.instance
                                              .collection('documents')
                                              .doc(doc.id)
                                              .delete();
                                            Navigator.of(ctx).pop();
                                            ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                            'Document supprimé')));
                                          } catch (e) {
                                            Navigator.of(ctx).pop();
                                            ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                              content: Text(
                                            'Erreur : $e')));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
