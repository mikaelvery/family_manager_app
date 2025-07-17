import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF866E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tableau de bord', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Partie gauche - Créer une tâche
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Créer une tâche',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        child: const Text('Ajouter un rendez-vous'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        child: const Text('Ajouter des vacances'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                        child: const Text('Ajouter un document'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Partie droite - À venir
            Expanded(
              child: Column(
                children: [
                  _UpcomingCard(
                    title: 'Prochain RDV',
                    subtitle: 'Dentiste pour Léo - 18 Juillet à 10h',
                    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                  ),
                  const SizedBox(height: 16),
                  _UpcomingCard(
                    title: 'Vacances',
                    subtitle: 'Espagne - du 1 au 15 Août',
                    colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
                  ),
                  const SizedBox(height: 16),
                  _UpcomingCard(
                    title: 'Document expirant',
                    subtitle: 'CNI de Mila - expire le 20 Juillet',
                    colors: [Color(0xFFFFA17F), Color(0xFFFFE259)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> colors;

  const _UpcomingCard({
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(subtitle, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
