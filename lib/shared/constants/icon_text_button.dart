import 'package:flutter/material.dart';

class IconTextButton extends StatelessWidget {
  const IconTextButton(
    this.icon,
    this.text, {
    required this.onPressed,
    super.key,
  });

  final String text;
  final IconData? icon;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text, style: const TextStyle(fontSize: 18, color: Colors.black87)),
      style: ButtonStyle(
        iconSize: const WidgetStatePropertyAll(30),
        iconColor: const WidgetStatePropertyAll(Colors.black87),
        alignment: Alignment.centerLeft,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 60)),
      ),
    );
  }
}
