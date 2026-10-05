import 'package:flutter/material.dart';

import '../design/tokens/app_colors.dart';
import '../design/tokens/app_spacing.dart';

class PreviewPage extends StatelessWidget {
  const PreviewPage({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.action,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? action;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(title, style: theme.textTheme.headlineLarge), actions: actions),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PreviewNotice(),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(subtitle!, style: theme.textTheme.bodyLarge),
                      ],
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
      bottomNavigationBar: action == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.all(AppSpacing.screen),
              child: action!,
            ),
    );
  }
}

class PreviewNotice extends StatelessWidget {
  const PreviewNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.science_outlined, size: 16, color: theme.extension<AppColors>()!.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'UX PREVIEW · SAMPLE DATA · NOTHING IS SAVED',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.extension<AppColors>()!.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

void showPreviewMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
