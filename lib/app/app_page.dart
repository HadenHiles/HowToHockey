import 'package:flutter/material.dart';

import '../design/tokens/app_spacing.dart';

class AppPage extends StatelessWidget {
  const AppPage({required this.title, required this.children, super.key, this.subtitle, this.action, this.actions, this.appBarTitle, this.centerAppBarTitle = false, this.showAppBar = true});

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? action;
  final List<Widget>? actions;
  final Widget? appBarTitle;
  final bool centerAppBarTitle;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scroll = CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        if (showAppBar)
          if (centerAppBarTitle)
            SliverAppBar(
              pinned: true,
              toolbarHeight: 88,
              title: appBarTitle ?? Text(title, style: theme.textTheme.headlineLarge),
              centerTitle: true,
              actions: actions,
            )
          else
            _LargeTitleBar(title: title, actions: actions),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (subtitle != null) ...[Text(subtitle!, style: theme.textTheme.bodyLarge), const SizedBox(height: AppSpacing.xl)] else const SizedBox(height: AppSpacing.md),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    // The action lives in the body, not bottomNavigationBar, so the on-screen keyboard can't cover it.
    return Scaffold(
      body: action == null
          ? scroll
          : Column(
              children: [
                Expanded(child: scroll),
                SafeArea(top: false, minimum: const EdgeInsets.all(AppSpacing.screen), child: action!),
              ],
            ),
    );
  }
}

/// The large collapsing title, kept compact: the title sits right under the toolbar row instead of
/// in a tall empty header, and it folds into the toolbar when the page scrolls.
class _LargeTitleBar extends StatelessWidget {
  const _LargeTitleBar({required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    // Tab pages have no back or close button, so the toolbar row only needs to hold the folded title.
    final toolbarHeight = actions == null && !canPop ? 40.0 : 56.0;
    final large = theme.textTheme.headlineLarge!;
    final small = theme.textTheme.titleLarge!;
    final titleBlock = MediaQuery.textScalerOf(context).scale(large.fontSize! * (large.height ?? 1)) + AppSpacing.sm + AppSpacing.xxs;
    return SliverAppBar(
      pinned: true,
      toolbarHeight: toolbarHeight,
      expandedHeight: toolbarHeight + titleBlock,
      actions: actions,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()!;
          final range = settings.maxExtent - settings.minExtent;
          final collapsed = range <= 0 ? 1.0 : ((settings.maxExtent - constraints.maxHeight) / range).clamp(0.0, 1.0);
          final top = MediaQuery.paddingOf(context).top;
          return Stack(
            children: [
              Positioned(
                left: AppSpacing.screen,
                right: AppSpacing.screen,
                bottom: AppSpacing.sm,
                child: Opacity(
                  opacity: (1 - collapsed * 1.6).clamp(0.0, 1.0),
                  child: Semantics(
                    header: true,
                    child: Text(title, style: large, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              Positioned(
                left: canPop ? 64 : AppSpacing.screen,
                right: AppSpacing.screen + (actions == null ? 0 : 48.0 * actions!.length),
                top: top,
                height: toolbarHeight,
                child: Opacity(
                  opacity: ((collapsed - 0.5) * 2).clamp(0.0, 1.0),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ExcludeSemantics(
                      child: Text(title, style: small, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void showFeatureMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
