import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddContentModal extends StatelessWidget {
  const AddContentModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.description_outlined, color: Colors.white),
            title: const Text('Create a Summary', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/summary');
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz_outlined, color: Colors.white),
            title: const Text('Create a Quiz', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/quiz');
            },
          ),
          ListTile(
            leading: const Icon(Icons.style_outlined, color: Colors.white),
            title: const Text('Create Flashcards', style: TextStyle(color: Colors.white)),
            onTap: () {
               Navigator.of(context).pop();
               context.push('/flashcards');
            },
          ),
        ],
      ),
    );
  }
}
