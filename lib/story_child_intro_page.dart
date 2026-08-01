import 'package:flutter/material.dart';
import 'story_activity_page.dart';

class StoryChildIntroPage extends StatelessWidget {
  const StoryChildIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                child: Image.asset(
                  'assets/story_1.png.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoryActivityPage(),
                      ),
                    );
                  },
                  child: const Text('Continuer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}