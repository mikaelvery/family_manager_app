import 'package:flutter/material.dart';

class HomeAddTaskButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool fullWidth;

  const HomeAddTaskButton({
    super.key,
    required this.onTap,
    this.label = 'Ajouter une tâche',
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    final button = Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5F6D), Color(0xFFFF8F5F)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33FF5F6D),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment:
                  fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 24,  // un peu plus petit
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add_rounded,
                    size: 16,  // plus petit
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8), // un peu moins d’espace
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,  // police réduite
                    ),
                  ),
                ),
                // Suppression de l'icône flèche
                // const SizedBox(width: 8),
                // const Icon(
                //   Icons.arrow_forward_rounded,
                //   size: 18,
                //   color: Colors.white,
                // ),
              ],
            ),
          ),
        ),
      ),
    );

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : Align(alignment: Alignment.centerLeft, child: button);
  }
}
