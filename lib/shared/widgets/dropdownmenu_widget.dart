import 'package:flutter/material.dart';

class DropdownMenuWidget extends StatefulWidget {
  const DropdownMenuWidget({super.key});

  @override
  State<DropdownMenuWidget> createState() => _DropdownMenuWidgetState();
}

class _DropdownMenuWidgetState extends State<DropdownMenuWidget> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      dropdownMenuEntries: const [
        DropdownMenuEntry(label: 'Option 1', value: 'option1'),
        DropdownMenuEntry(label: 'Option 2', value: 'option2'),
        DropdownMenuEntry(label: 'Option 3', value: 'option3'),
      ],
      initialSelection: 'option1',
      label: const Text("Select A Tag"),
      onSelected: (value) {},
      width: double.infinity,
    );
  }
}
