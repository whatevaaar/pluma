import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/documents/presentation/library_screen.dart';
import '../../features/editor/presentation/editor_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/trash/presentation/trash_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/library',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/library',
            name: 'library',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: '/statistics',
            name: 'statistics',
            builder: (context, state) => const StatisticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/editor/:documentId',
        name: 'editor',
        builder: (context, state) {
          final documentId = state.pathParameters['documentId']!;
          return EditorScreen(documentId: documentId);
        },
      ),
      GoRoute(
        path: '/trash',
        name: 'trash',
        builder: (context, state) => const TrashScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(currentPath: GoRouterState.of(context).uri.path),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentPath});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final index = switch (currentPath) {
      String p when p.startsWith('/library') => 0,
      String p when p.startsWith('/statistics') => 1,
      String p when p.startsWith('/settings') => 2,
      _ => 0,
    };

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.goNamed('library');
          case 1:
            context.goNamed('statistics');
          case 2:
            context.goNamed('settings');
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Escritos'),
        NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Estadísticas'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
      ],
    );
  }
}
