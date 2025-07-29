import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AutoCompleteMedecin extends StatefulWidget {
  final TextEditingController controller;

  const AutoCompleteMedecin({super.key, required this.controller});

  @override
  AutoCompleteMedecinState createState() => AutoCompleteMedecinState();
}

class AutoCompleteMedecinState extends State<AutoCompleteMedecin> {
  List<String> suggestions = [];
  bool isLoading = false;
  OverlayEntry? overlayEntry;

  final LayerLink layerLink = LayerLink();

  void fetchSuggestions(String input) async {
    final lowerInput = input.toLowerCase();

    if (lowerInput.isEmpty) {
      hideOverlay();
      setState(() => suggestions = []);
      return;
    }

    setState(() => isLoading = true);

    final query = FirebaseFirestore.instance
        .collection('medecins')
        .orderBy('nameLower')
        .startAt([lowerInput])
        .endAt(['$lowerInput\uf8ff']);

    final snapshot = await query.get();

    final names = snapshot.docs
        .map((doc) => doc['name'] as String)
        .toList();

    setState(() {
      suggestions = names;
      isLoading = false;
    });

    showOverlay();
  }

  void showOverlay() {
    overlayEntry?.remove();

    if (suggestions.isEmpty) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: layerLink,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  title: Text(suggestion),
                  onTap: () {
                    widget.controller.text = suggestion;
                    widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: suggestion.length),
                    );
                    suggestions = [];
                    hideOverlay();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry!);
  }

  void hideOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  @override
  void dispose() {
    hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: 'Nom du médecin',
          suffixIcon: isLoading ? const Padding(
            padding: EdgeInsets.all(10.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ) : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => fetchSuggestions(value),
        onEditingComplete: () {
          hideOverlay();
          FocusScope.of(context).unfocus();
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'Champ requis' : null,
      ),
    );
  }
}
