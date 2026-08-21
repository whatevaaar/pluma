import 'package:flutter/material.dart';

/// Small uppercase section label in the brand accent color.
///
/// Shared across the library, statistics, and settings screens so grouped
/// content is introduced consistently — and gives the otherwise-neutral UI a
/// few intentional moments of brand color.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.label, this.padding, super.key});

  final String label;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
