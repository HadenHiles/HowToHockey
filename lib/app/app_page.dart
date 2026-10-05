import 'package:flutter/material.dart';

import '../design/tokens/app_spacing.dart';

class AppPage extends StatelessWidget {
  const AppPage({required this.title, required this.children, super.key, this.subtitle, this.action, this.actions, this.showAppBar = true});

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? action;
  final List<Widget>? actions;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          if (showAppBar)
            SliverAppBar.large(
              title: Text(title, style: theme.textTheme.headlineLarge),
              actions: actions,
            ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (subtitle != null) ...[const SizedBox(height: AppSpacing.md), Text(subtitle!, style: theme.textTheme.bodyLarge)],
                      const SizedBox(height: AppSpacing.xl),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: action == null ? null : SafeArea(top: false, minimum: const EdgeInsets.all(AppSpacing.screen), child: action!),
    );
  }
}

void showFeatureMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
