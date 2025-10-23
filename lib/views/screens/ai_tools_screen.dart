import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiToolsScreen extends StatelessWidget {
  const AiToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            expandedHeight: 120.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('AI Tools',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              centerTitle: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                // Determine the number of columns based on the available width.
                final crossAxisCount = (constraints.crossAxisExtent / 350).floor().clamp(1, 3);

                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20.0,
                    mainAxisSpacing: 20.0,
                    childAspectRatio: 1.5, // Adjust this ratio to fit your card content
                  ),
                  delegate: SliverChildListDelegate(
                    [
                      _buildFeatureCard(
                        context,
                        theme: theme,
                        icon: Icons.flash_on,
                        title: 'Generate Summary',
                        subtitle: 'Summarize any text, article, or document instantly.',
                        color: Colors.blueAccent,
                        onTap: () => context.push('/summary'),
                      ),
                      _buildFeatureCard(
                        context,
                        theme: theme,
                        icon: Icons.filter_none,
                        title: 'Flashcards',
                        subtitle: 'Create flashcards from any content to aid your learning.',
                        color: Colors.greenAccent,
                        onTap: () => context.push('/flashcards'),
                      ),
                      _buildFeatureCard(
                        context,
                        theme: theme,
                        icon: Icons.question_answer,
                        title: 'Generate Quiz',
                        subtitle: 'Create a quiz from any content to test your knowledge.',
                        color: Colors.purpleAccent,
                        onTap: () => context.push('/quiz'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required ThemeData theme,
      required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            Text(subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                )),
          ],
        ),
      ),
    );
  }
}
