import 'package:flutter/material.dart';

import 'package:pluma/core/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.subtitle,
    super.key,
    this.icon,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 56, color: colorScheme.primary.withAlpha(140)),
              const SizedBox(height: 20),
            ],
            Text(
              title,
              style: AppTextStyles.uiTitle.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.uiBody.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: action,
                child: Text(actionLabel!, style: AppTextStyles.uiButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
