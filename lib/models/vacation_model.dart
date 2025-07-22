
import 'package:cloud_firestore/cloud_firestore.dart';

class VacationModel {
  final String id;
  final String nom;
  final String description;
  final DateTime debut;
  final DateTime fin;
  final String couleur;

  VacationModel({
    required this.id,
    required this.nom,
    required this.description,
    required this.debut,
    required this.fin,
    required this.couleur,
  });

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
      'debut': debut,
      'fin': fin,
      'couleur': couleur,
    };
  }

  factory VacationModel.fromMap(String id, Map<String, dynamic> map) {
    return VacationModel(
      id: id,
      nom: map['nom'],
      description: map['description'],
      debut: (map['debut'] as Timestamp).toDate(),
      fin: (map['fin'] as Timestamp).toDate(),
      couleur: map['couleur'],
    );
  }
}
