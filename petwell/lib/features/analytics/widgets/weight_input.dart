import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class WeightInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const WeightInput({super.key, required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter Pet Weight (kg)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onSubmit,
          child: Row(
            mainAxisSize: MainAxisSize.min, 
            children: const [
              Text('Add My Weight '),
              SizedBox(width: 8),
              Icon(
                FontAwesomeIcons.paw, // Paw icon here
                size: 24, 
              ),
            ],
          ),
        )


      ],
    );
  }
}
