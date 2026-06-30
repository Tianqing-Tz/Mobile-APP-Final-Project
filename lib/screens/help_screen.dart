import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Frequently Asked Questions (FAQ)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 12),
          const ExpansionTile(
            title: Text('How to complete a meetup transaction?'),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'As a campus-based platform, it is highly recommended that both parties arrange to meet at safe, public areas covered by surveillance, such as the Student Activity Centre, library entrance, or cafeterias to inspect the item and complete the transfer.',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('How do I edit an incorrect item description?'),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'On the main market screen, tap on your own item card. On the details page, tap the "Edit Information" button at the bottom right to update the price and description.',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('How do I take down an item after it is sold?'),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Go to the item details page, tap the trash bin delete icon at the top right corner, and confirm to completely remove the listing from the market.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Feedback & Suggestions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Encountered any bugs or have any suggestions? Write them here...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Thank you for your feedback! We will improve as soon as possible.',
                  ),
                ),
              );
            },
            child: const Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }
}
