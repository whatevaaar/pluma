import 'package:flutter/material.dart';

import 'package:pluma/features/documents/domain/project.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    required this.project,
    super.key,
    this.onTap,
    this.documentCount,
  });

  final Project project;
  final VoidCallback? onTap;
  final int? documentCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = project.color != null
        ? Color(
            int.parse(
              'FF${project.color!.replaceFirst('#', '')}',
              radix: 16,
            ),
          )
        : colorScheme.primaryContainer;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withAlpha(30),
          border: Border.all(color: accentColor.withAlpha(60)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.folder_outlined, color: accentColor, size: 22),
            const SizedBox(height: 4),
            Text(
              project.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (documentCount != null)
              Text(
                '$documentCount doc${documentCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
