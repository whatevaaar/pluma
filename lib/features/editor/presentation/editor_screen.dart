import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Placeholder — implemented in Fase 1
class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor')),
      body: const Center(child: Text('Editor — próximamente')),
    );
  }
}
