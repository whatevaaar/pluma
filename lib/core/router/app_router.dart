import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pluma/features/documents/presentation/library_screen.dart';
import 'package:pluma/features/documents/presentation/project_screen.dart';
import 'package:pluma/features/editor/presentation/editor_screen.dart';
import 'package:pluma/features/settings/presentation/settings_screen.dart';
import 'package:pluma/features/statistics/presentation/statistics_screen.dart';
import 'package:pluma/features/trash/presentation/trash_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/library',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          // NoTransitionPage on each tab: the directional shared-axis
          // animation is owned by _AppShell so it can pick the slide direction
          // from the relative tab index. A per-route transition here would
          // fight it.
          GoRoute(
            path: '/library',
            name: 'library',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LibraryScreen()),
          ),
          GoRoute(
            path: '/statistics',
            name: 'statistics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StatisticsScreen()),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
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
        path: '/project/:projectId',
        name: 'project',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId']!;
          return ProjectScreen(projectId: projectId);
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

int _tabIndexForPath(String path) => switch (path) {
      final p when p.startsWith('/statistics') => 1,
      final p when p.startsWith('/settings') => 2,
      _ => 0,
    };

class _AppShell extends StatefulWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _previousIndex = 0;

  @override
  Widget build(BuildContext context) {
    final index = _tabIndexForPath(GoRouterState.of(context).uri.path);
    // Slide direction follows the tab bar's spatial layout: moving to a
    // higher-index tab enters from the right, a lower-index tab from the left.
    final reverse = index < _previousIndex;
    _previousIndex = index;

    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 280),
        reverse: reverse,
        transitionBuilder: (child, primary, secondary) => SharedAxisTransition(
          animation: primary,
          secondaryAnimation: secondary,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: Colors.transparent,
          child: child,
        ),
        // Key by tab index so the switcher animates only on tab changes, not
        // on in-tab rebuilds.
        child: KeyedSubtree(
          key: ValueKey(index),
          child: widget.child,
        ),
      ),
      bottomNavigationBar: _BottomNav(currentIndex: index),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
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
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Escritos',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Estadísticas',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Ajustes',
        ),
      ],
    );
  }
}
