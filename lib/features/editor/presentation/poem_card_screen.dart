import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/editor/domain/poem_card_style.dart';
import 'package:pluma/shared/widgets/poem_view.dart';
import 'package:share_plus/share_plus.dart';

/// Turns a poem into a shareable image: title + body centered and auto-fitted
/// (via [PoemView]) over a curated background, exported as a PNG.
class PoemCardScreen extends StatefulWidget {
  const PoemCardScreen({
    required this.document,
    this.fontFamily,
    super.key,
  });

  final Document document;
  final String? fontFamily;

  @override
  State<PoemCardScreen> createState() => _PoemCardScreenState();
}

class _PoemCardScreenState extends State<PoemCardScreen> {
  final GlobalKey _cardKey = GlobalKey();

  int _bgIndex = 0;
  CardAspect _aspect = CardAspect.portrait45;
  bool _showTitle = true;
  bool _exporting = false;

  CardBackground get _bg => kCardBackgrounds[_bgIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir como imagen')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: AspectRatio(
                  aspectRatio: _aspect.ratio,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _CardCanvas(
                        cardKey: _cardKey,
                        background: _bg,
                        document: widget.document,
                        fontFamily: widget.fontFamily,
                        showTitle: _showTitle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _Controls(
            backgrounds: kCardBackgrounds,
            selectedBg: _bgIndex,
            onBgSelected: (i) => setState(() => _bgIndex = i),
            aspect: _aspect,
            onAspectSelected: (a) => setState(() => _aspect = a),
            showTitle: _showTitle,
            onShowTitleChanged: (v) => setState(() => _showTitle = v),
            exporting: _exporting,
            onShare: _shareImage,
          ),
        ],
      ),
    );
  }

  Future<void> _shareImage() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      // Let the current frame settle so the boundary reflects the latest
      // background/aspect selection before we snapshot it.
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

      // Upscale the on-screen preview to ~1080px wide for a crisp export.
      // Text is vector, so re-rasterizing at a higher pixel ratio stays sharp.
      const targetWidth = 1080.0;
      final pixelRatio = (targetWidth / boundary.size.width).clamp(1.0, 4.0);

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('toByteData returned null');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_safeName()}.png');
      await file.writeAsBytes(data.buffer.asUint8List());

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar la imagen.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _safeName() {
    final safe = widget.document.displayTitle
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim();
    return safe.isEmpty ? 'poema' : safe;
  }
}

/// The rendered card surface — the exact pixels captured for export.
class _CardCanvas extends StatelessWidget {
  const _CardCanvas({
    required this.cardKey,
    required this.background,
    required this.document,
    required this.fontFamily,
    required this.showTitle,
  });

  final GlobalKey cardKey;
  final CardBackground background;
  final Document document;
  final String? fontFamily;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: cardKey,
      child: DecoratedBox(
        decoration: background.decoration,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth * 0.09;
            return PoemView(
              body: document.plainText.trim(),
              title: showTitle ? document.displayTitle : null,
              textColor: background.textColor,
              titleColor: background.titleColor,
              fontFamily: fontFamily,
              padding: EdgeInsets.all(pad),
            );
          },
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.backgrounds,
    required this.selectedBg,
    required this.onBgSelected,
    required this.aspect,
    required this.onAspectSelected,
    required this.showTitle,
    required this.onShowTitleChanged,
    required this.exporting,
    required this.onShare,
  });

  final List<CardBackground> backgrounds;
  final int selectedBg;
  final ValueChanged<int> onBgSelected;
  final CardAspect aspect;
  final ValueChanged<CardAspect> onAspectSelected;
  final bool showTitle;
  final ValueChanged<bool> onShowTitleChanged;
  final bool exporting;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: backgrounds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final bg = backgrounds[i];
                  final selected = i == selectedBg;
                  return GestureDetector(
                    onTap: () => onBgSelected(i),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: bg.decoration.gradient,
                        color: bg.decoration.color,
                        border: Border.all(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: selected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SegmentedButton<CardAspect>(
                  segments: [
                    for (final a in CardAspect.values)
                      ButtonSegment(value: a, label: Text(a.label)),
                  ],
                  selected: {aspect},
                  onSelectionChanged: (s) => onAspectSelected(s.first),
                  showSelectedIcon: false,
                ),
                const Spacer(),
                _TitleToggle(value: showTitle, onChanged: onShowTitleChanged),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: exporting ? null : onShare,
                icon: exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share),
                label: Text(exporting ? 'Generando…' : 'Compartir imagen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleToggle extends StatelessWidget {
  const _TitleToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Título'),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}
