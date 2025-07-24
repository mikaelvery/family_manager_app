import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AutoCompleteMedecin extends StatefulWidget {
  final TextEditingController controller;

  const AutoCompleteMedecin({super.key, required this.controller});

  @override
  State<AutoCompleteMedecin> createState() => _AutoCompleteMedecinState();
}

class _AutoCompleteMedecinState extends State<AutoCompleteMedecin> {
  List<String> options = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // détecte les changements de texte
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    _searchMedecins(query);
  }

  Future<void> _searchMedecins(String query) async {
    if (query.isEmpty) {
      setState(() => options = []);
      return;
    }

    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('medecins')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    setState(() {
      options = snapshot.docs.map((doc) => doc['name'] as String).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        // On ne fait plus la recherche ici !
        final input = textEditingValue.text.toLowerCase();
        return options.where((option) => option.toLowerCase().contains(input));
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        // Remplacer le controller local par le controller passé en paramètre
        return TextFormField(
          controller: widget.controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Nom du médecin',
            suffixIcon: isLoading ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Merci d\'indiquer le nom du médecin';
            }
            return null;
          },
          onEditingComplete: onEditingComplete,
        );
      },
      onSelected: (selection) {
        widget.controller.text = selection;
      },
    );
  }
}
