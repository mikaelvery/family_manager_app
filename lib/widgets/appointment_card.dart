import 'package:flutter/material.dart';

Widget appointmentCard({
  required String title,
  required String description,
  required String formattedDate,
  required String medecin,
  required IconData icon,
  required Color iconColor,
}) {

  return Container(
    width: 180,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withAlpha(25),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  children: [
                    TextSpan(text: '$description\n'),
                    TextSpan(
                      text: '$formattedDate\n',
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: 'Dr $medecin',
                      style: const TextStyle(color: Color(0xFFFF5F6D), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ],
    ),
  );
}
