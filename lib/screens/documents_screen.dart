import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Téléchargement + ouverture du PDF
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

  IconData _iconFor(String description) {
    final d = (description).toLowerCase();
    if (d.contains('cni') || d.contains('identit')) return Icons.badge_outlined;
    if (d.contains('passeport')) return Icons.public;
    if (d.contains('mutuelle') || d.contains('sant')) return Icons.health_and_safety_outlined;
    if (d.contains('permis')) return Icons.directions_car_filled_outlined;
    if (d.contains('livret') && d.contains('fam')) return Icons.family_restroom;
    if (d.contains('denta') || d.contains('dentition') || d.contains('dent')) {
      return Icons.medical_services_outlined;
    }
    return Icons.picture_as_pdf;
  }

  Color _tintFor(String description) {
    final d = (description).toLowerCase();
    if (d.contains('cni') || d.contains('identit')) return const Color(0xFF4F46E5); 
    if (d.contains('passeport')) return const Color(0xFF0EA5E9);
    if (d.contains('mutuelle') || d.contains('sant')) return const Color(0xFF10B981);
    if (d.contains('permis')) return const Color(0xFFF59E0B); 
    if (d.contains('livret') && d.contains('fam')) return const Color(0xFF8B5CF6);
    if (d.contains('dent')) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  void _showDocActions({
    required BuildContext context,
    required String description,
    required String fileName,
    required String personName,
    required String dateStr,
    required String url,
    required String docId,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(_iconFor(description), color: _tintFor(description)),
                  title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('$personName • Ajouté le $dateStr'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                _ActionRow(
                  icon: Icons.open_in_new,
                  label: 'Ouvrir le document',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _downloadAndOpenPdf(url);
                  },
                ),
                const SizedBox(height: 8),
                _ActionRow(
                  icon: Icons.delete_outline,
                  label: 'Supprimer',
                  danger: true,
                  onTap: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('documents')
                          .doc(docId)
                          .delete();
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        Navigator.of(ctx).pop();
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Document supprimé')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        Navigator.of(ctx).pop();
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur : $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy', 'fr_FR');

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: Column(
        children: [
          // HEADER dégradé avec search bar
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5F6D), Color(0xFFFF8F5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Décors
                Positioned(
                  left: -50,
                  top: -120,
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Image.asset('assets/images/bg_liquid.png', width: 145),
                  ),
                ),
                Positioned(
                  right: -35,
                  top: -20,
                  child: Transform.rotate(
                    angle: 50,
                    child: Image.asset('assets/images/bg_liquid.png', width: 100),
                  ),
                ),

                // Contenu du header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Retour',
                        ),
                        const SizedBox(width: 32),
                        Text(
                          'Mes documents',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: const [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black26,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // >>> Barre de recherche intégrée dans le header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 12,
                            offset: Offset(0, 8),
                            color: Color(0x22000000),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Rechercher (nom, personne, type)…',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('documents')
                  .orderBy('description')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingState();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const _EmptyState();
                }

                final docs = snapshot.data!.docs;

                // Grouper par description
                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final description = (data['description'] as String?)?.trim().isNotEmpty == true
                      ? data['description'] as String
                      : 'Autres';
                  // Filtre de recherche simple
                  final personName = (data['personName'] ?? 'Famille').toString();
                  final fileName = (data['name'] ?? 'Nom inconnu').toString();
                  final hay = '$description $personName $fileName'.toLowerCase();
                  if (_query.isNotEmpty && !hay.contains(_query)) continue;

                  grouped.putIfAbsent(description, () => []).add(doc);
                }

                if (grouped.isEmpty) {
                  return const _EmptyState(message: 'Aucun résultat pour cette recherche');
                }

                final sections = grouped.keys.toList();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: sections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final description = sections[i];
                    final documents = grouped[description]!;
                    final tint = _tintFor(description);

                    return Theme(
                      data: theme.copyWith(
                        dividerColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEAECEF)),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 10,
                              offset: Offset(0, 6),
                              color: Color(0x0F000000),
                            ),
                          ],
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: tint.withValues(alpha: 0.12),
                            child: Icon(_iconFor(description), color: tint),
                          ),
                          title: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          trailing: _CountBadge(count: documents.length),
                          initiallyExpanded: i == 0,
                          children: [
                            // Grille de cartes blanches
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final twoColumns = constraints.maxWidth > 520;
                                final crossAxisCount = twoColumns ? 2 : 1;
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: documents.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: twoColumns ? 2.8 : 3.4,
                                  ),
                                  itemBuilder: (context, idx) {
                                    final doc = documents[idx];
                                    final data = doc.data() as Map<String, dynamic>;
                                    final personName = (data['personName']?.toString().trim().isNotEmpty == true)
                                        ? data['personName'].toString()
                                        : 'Famille';
                                    final fileName = (data['name'] ?? 'Nom inconnu').toString();
                                    final url = (data['url'] ?? '').toString();
                                    final Timestamp ts = data['uploadedAt'] ?? Timestamp.now();
                                    final dateStr = dateFmt.format(ts.toDate());

                                    return _DocumentCard(
                                      icon: _iconFor(description),
                                      accent: tint,
                                      title: fileName,
                                      subtitle: '$personName • $dateStr',
                                      onOpen: () => _downloadAndOpenPdf(url),
                                      onMore: () => _showDocActions(
                                        context: context,
                                        description: description,
                                        fileName: fileName,
                                        personName: personName,
                                        dateStr: dateStr,
                                        url: url,
                                        docId: doc.id,
                                      ),
                                      onLongPress: () => _showDocActions(
                                        context: context,
                                        description: description,
                                        fileName: fileName,
                                        personName: personName,
                                        dateStr: dateStr,
                                        url: url,
                                        docId: doc.id,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== Composants UI ===================== */

class _DocumentCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onOpen;
  final VoidCallback onMore;
  final VoidCallback? onLongPress;

  const _DocumentCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onOpen,
    required this.onMore,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAECEF)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 12,
                offset: Offset(0, 8),
                color: Color(0x0F000000),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: onMore,
                tooltip: 'Options',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFDC2626) : const Color(0xFF0F172A);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEAECEF)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(blurRadius: 10, offset: Offset(0, 6), color: Color(0x0F000000)),
          ],
        ),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Container(height: 12, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(height: 10, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? message;
  const _EmptyState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message ?? 'Aucun document',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
