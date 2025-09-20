import 'package:flutter/material.dart';

Widget styledButton({
  required IconData icon,
  required String text,
  required VoidCallback onPressed,
  Color iconColor = Colors.blueGrey,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    ),
  );
}
