import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

IconData getIconForDescription(String description) {
  final desc = description.toLowerCase();

  if (desc.contains('dentiste')) return FontAwesomeIcons.tooth;
  if (desc.contains('angiologue')) return Icons.healing;
  if (desc.contains('orthodontiste')) return FontAwesomeIcons.tooth;
  if (desc.contains('docteur') || desc.contains('médecin')) {
    return FontAwesomeIcons.userDoctor;
  }
  if (desc.contains('kiné') ||
      desc.contains('kine') ||
      desc.contains('kinésithérapeute')) {
    return FontAwesomeIcons.personRunning;
  }
  if (desc.contains('ophtalmologue')) return Icons.visibility;
  if (desc.contains('orthophoniste') || desc.contains('ortho')) {
    return Icons.record_voice_over;
  }
  if (desc.contains('ergothérapeute') || desc.contains('ergo')) {
    return Icons.psychology;
  }
  if (desc.contains('psychologue') || desc.contains('psy')) {
    return Icons.psychology;
  }
  if (desc.contains('chirurgien')) return Icons.health_and_safety;
  if (desc.contains('hopital') || desc.contains('hôpital')) {
    return Icons.medical_services;
  }
  if (desc.contains('anesthésiste')) return Icons.medical_services;
  if (desc.contains('neurologue')) return FontAwesomeIcons.brain;
  if (desc.contains('gynécologue') || desc.contains('gynéco')) {
    return Icons.female;
  }
  if (desc.contains('sage-femme')) return FontAwesomeIcons.baby;
  if (desc.contains('dermatologue') || desc.contains('dermato')) {
    return Icons.spa;
  }
  if (desc.contains('cardiologue')) return FontAwesomeIcons.heartPulse;
  if (desc.contains('urologue')) return FontAwesomeIcons.person;
  if (desc.contains('orl')) return Icons.hearing;
  if (desc.contains('rhumatologue')) return FontAwesomeIcons.bone;
  if (desc.contains('pédiatre')) return FontAwesomeIcons.child;
  if (desc.contains('gastro-entérologue')) return Icons.local_dining;
  if (desc.contains('pneumologue')) return FontAwesomeIcons.lungs;
  if (desc.contains('endocrinologue')) return FontAwesomeIcons.dna;
  if (desc.contains('infirmier') || desc.contains('infirmière')) {
    return FontAwesomeIcons.syringe;
  }
  if (desc.contains('ostéopathe') || desc.contains('ostéo')) {
    return Icons.self_improvement;
  }
  if (desc.contains('podologue')) return FontAwesomeIcons.shoePrints;
  if (desc.contains('diététicien') || desc.contains('diét')) {
    return Icons.restaurant;
  }
  if (desc.contains('orthoptiste')) return Icons.remove_red_eye;
  if (desc.contains('psychomotricien')) return Icons.psychology;
  if (desc.contains('assistant social')) return Icons.group;
  return Icons.event;
}

Color getColorForDescription(String description) {
  final desc = description.toLowerCase();

  if (desc.contains('dentiste')) return Colors.deepPurple;
  if (desc.contains('angiologue')) return Colors.green;
  if (desc.contains('orthodontiste')) return Colors.blue;

  if (desc.contains('docteur') || desc.contains('médecin')) {
    return Colors.redAccent;
  }

  if (desc.contains('kiné') ||
      desc.contains('kine') ||
      desc.contains('kinésithérapeute')) {
    return Colors.orange;
  }

  if (desc.contains('ophtalmologue')) return Colors.indigo;
  if (desc.contains('orthophoniste') || desc.contains('ortho')) {
    return Colors.teal;
  }
  if (desc.contains('ergothérapeute') || desc.contains('ergo')) {
    return Colors.pink;
  }
  if (desc.contains('psychologue') || desc.contains('psy')) {
    return Colors.amber;
  }
  if (desc.contains('chirurgien')) return Colors.brown;
  if (desc.contains('hopital') || desc.contains('hôpital')) {
    return Colors.purple;
  }
  if (desc.contains('anesthésiste')) return Colors.purple;
  if (desc.contains('neurologue')) return Colors.cyan;
  if (desc.contains('gynécologue') || desc.contains('gynéco')) {
    return Colors.pinkAccent;
  }
  if (desc.contains('sage-femme')) return Colors.lightBlue;
  if (desc.contains('dermatologue') || desc.contains('dermato')) {
    return Colors.brown;
  }
  if (desc.contains('cardiologue')) return Colors.red;
  if (desc.contains('urologue')) return Colors.blueGrey;
  if (desc.contains('orl')) return Colors.cyan;
  if (desc.contains('rhumatologue')) return Colors.deepOrange;
  if (desc.contains('pédiatre')) return Colors.greenAccent;
  if (desc.contains('gastro-entérologue')) return Colors.indigoAccent;
  if (desc.contains('pneumologue')) return Colors.teal;
  if (desc.contains('endocrinologue')) return Colors.deepPurple;
  if (desc.contains('infirmier') || desc.contains('infirmière')) {
    return Colors.lightGreen;
  }
  if (desc.contains('ostéopathe') || desc.contains('ostéo')) {
    return Colors.orangeAccent;
  }
  if (desc.contains('podologue')) return Colors.brown;
  if (desc.contains('diététicien') || desc.contains('diét')) {
    return Colors.lime;
  }
  if (desc.contains('orthoptiste')) return Colors.blueGrey;
  if (desc.contains('psychomotricien')) return Colors.amber;
  if (desc.contains('assistant social')) return Colors.grey;
  return Colors.grey;
}
