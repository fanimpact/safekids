import 'package:flutter/material.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Théo et Noé participent à une activité',
      'text':
          'Deux enfants, deux besoins différents, un accompagnement adapté.',
    },
    {
      'title': 'Les parents partagent les informations',
      'text':
          'L’accompagnant reçoit un lien sécurisé. Il n’a rien à installer.',
    },
    {
      'title': 'Les recommandations s’adaptent',
      'text':
          'Les conseils changent selon l’activité et les besoins de chaque enfant.',
    },
    {
      'title': 'En cas d’urgence',
      'text':
          'L’accompagnant accède immédiatement aux conduites à tenir.',
    },
    {
      'title': 'Les informations sont transmises aux secours',
      'text':
          'La fiche de télétransmission facilite la prise en charge de l’enfant.',
    },
    {
      'title': 'À votre tour',
      'text':
          'Créez gratuitement la fiche de votre enfant.',
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Découvrir SafeKids'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final page = _pages[index];

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
  child: ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: Image.asset(
    'lib/assets/story_${index + 1}.png.png',
    fit: BoxFit.contain,
    width: double.infinity,
  ),
),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        page['title']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        page['text']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => Container(
                width: index == _currentPage ? 22 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: index == _currentPage
                      ? Colors.blue
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? () {}
                        : _nextPage,
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Créer gratuitement la fiche de mon enfant'
                          : 'Suivant',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}