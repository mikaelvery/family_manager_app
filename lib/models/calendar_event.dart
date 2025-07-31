import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime? date;
  final DateTime? debut;
  final DateTime? fin;
  final String type;
  final String participant;
  final String medecin;
  final Color? color;
  final String? name;
  String get displayTitle {
  if (type == 'birthday' || type == 'anniversaire') {
    return (name != null && name!.isNotEmpty) ? name! : 'Anniversaire';
  }
  return title.isNotEmpty ? title : 'Événement';
}


  CalendarEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.participant,
    required this.medecin,
    this.date,
    this.debut,
    this.fin,
    this.description,
    this.color,
    this.name,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return CalendarEvent(
      id: id,
      title: data['title'] ?? data['nom'] ?? '',
      type: data['type'] ?? 'tâche',
      participant: data['participant'] ?? '',
      medecin: data['medecin'] ?? '',
      description: data['description'],
      date: parseDate(data['birthday'] ?? data['date'] ?? data['datetime']),
      debut: parseDate(data['debut']),
      fin: parseDate(data['fin']),
      color: data['couleur'] != null ? _parseHexColor(data['couleur']) : null,
      name: data['name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'participant': participant,
      'medecin': medecin,
      'description': description,
      'date': date?.toIso8601String(),
      'debut': debut?.toIso8601String(),
      'fin': fin?.toIso8601String(),
      // ignore: deprecated_member_use
      'couleur': color != null
          // ignore: deprecated_member_use
          ? '#${color!.value.toRadixString(16).substring(2)}'
          : null,
      'name': name,
    };
  }

  static Color _parseHexColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    return Color(int.parse("0x$hex"));
  }
}
