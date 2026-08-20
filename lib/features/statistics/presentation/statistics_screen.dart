import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluma/core/extensions/number_ext.dart';
import 'package:pluma/features/statistics/domain/daily_stats.dart';
import 'package:pluma/features/statistics/presentation/statistics_notifier.dart';

// ---------------------------------------------------------------------------
// Heatmap constants
// ---------------------------------------------------------------------------

const _kWeeks = 16;
const _kDays = _kWeeks * 7; // 112 days
const _kCellSize = 9.0;
const _kGap = 2.0;
const _kCellStep = _kCellSize + _kGap;
const _kMonthLabelHeight = 14.0;
const _kSpanishMonths = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => _StatsBody(stats: stats),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final WritingStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        _SectionLabel('Hoy'),
        const SizedBox(height: 12),
        _TodayCard(stats: stats),
        const SizedBox(height: 24),
        _SectionLabel('Racha'),
        const SizedBox(height: 12),
        _StreakCard(stats: stats),
        const SizedBox(height: 24),
        _SectionLabel('Actividad'),
        const SizedBox(height: 12),
        _HeatmapCard(stats: stats),
        const SizedBox(height: 24),
        _SectionLabel('Totales'),
        const SizedBox(height: 12),
        _StatsGrid(stats: stats),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today card — goal ring + word count
// ---------------------------------------------------------------------------

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.stats});

  final WritingStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = stats.dailyCompletionRatio;
    final reached = stats.dailyTargetReached;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          children: [
            _GoalRing(
              ratio: ratio,
              wordsToday: stats.dailyWordCount,
              target: stats.dailyTarget,
              reached: reached,
            ),
            const SizedBox(height: 16),
            Text(
              stats.todaySessions == 0
                  ? 'Sin sesiones hoy'
                  : '${stats.todaySessions} '
                      '${stats.todaySessions == 1 ? 'sesión' : 'sesiones'} hoy',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRing extends StatelessWidget {
  const _GoalRing({
    required this.ratio,
    required this.wordsToday,
    required this.target,
    required this.reached,
  });

  final double ratio;
  final int wordsToday;
  final int target;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ringColor =
        reached ? colorScheme.primary : colorScheme.primaryContainer;
    final size = 160.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              ratio: ratio,
              foreground: colorScheme.primary,
              background: colorScheme.surfaceContainerHighest,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$wordsToday',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
              Text(
                'de $target palabras',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              if (reached)
                Text(
                  '¡Meta alcanzada!',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: ringColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.ratio,
    required this.foreground,
    required this.background,
  });

  final double ratio;
  final Color foreground;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (ratio > 0) {
      final progressPaint = Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * ratio.clamp(0.0, 1.0),
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio ||
      old.foreground != foreground ||
      old.background != background;
}

// ---------------------------------------------------------------------------
// Streak card
// ---------------------------------------------------------------------------

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.stats});

  final WritingStats stats;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Text(
              '🔥',
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.currentStreak} '
                  '${stats.currentStreak == 1 ? 'día' : 'días'}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                ),
                Text(
                  'Racha actual',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stats.longestStreak}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  'Récord',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats grid
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final WritingStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Total escrito',
                value: stats.totalWords.formatAsWords(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Días activos',
                value: '${stats.totalDaysActive} días',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Mejor día',
                value: stats.bestDay.formatAsWords(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: 'Promedio diario',
                value: stats.averageDaily.formatAsWords(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatTile(
          label: 'Mejor sesión',
          value: stats.bestSession.formatAsWords(),
        ),
      ],
    );
  }

}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Heatmap card
// ---------------------------------------------------------------------------

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.stats});

  final WritingStats stats;

  /// Build the list of 112 dates (oldest → newest), starting on a Monday.
  ///
  /// We anchor to today and walk back so that the last column ends on today's
  /// weekday.  Weekday: Mon=1 … Sun=7 (DateTime convention).
  List<DateTime> _buildDates() {
    final today = DateTime.now();
    // How many days since Monday of today's week?
    final daysSinceMonday = today.weekday - 1; // Mon=0 … Sun=6
    // The Monday that ends the last column:
    final lastMonday = today.subtract(Duration(days: daysSinceMonday));
    // Start date: Monday 16 weeks ago.
    final firstMonday = lastMonday.subtract(const Duration(days: (_kWeeks - 1) * 7));

    final dates = <DateTime>[];
    for (var i = 0; i < _kDays; i++) {
      dates.add(firstMonday.add(Duration(days: i)));
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dates = _buildDates();

    // Total canvas size (excluding month labels row).
    final gridWidth = _kWeeks * _kCellStep - _kGap;
    final gridHeight = 7 * _kCellStep - _kGap;
    final totalHeight = _kMonthLabelHeight + _kGap + gridHeight;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: gridWidth,
                height: totalHeight,
                child: CustomPaint(
                  painter: _HeatmapPainter(
                    dates: dates,
                    heatmapData: stats.heatmapData,
                    emptyColor: colorScheme.surfaceContainerHighest,
                    activeColor: colorScheme.primary,
                    labelColor: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Últimas 16 semanas',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.dates,
    required this.heatmapData,
    required this.emptyColor,
    required this.activeColor,
    required this.labelColor,
  });

  final List<DateTime> dates; // 112 entries, Mon-anchored, oldest first
  final Map<String, int> heatmapData;
  final Color emptyColor;
  final Color activeColor;
  final Color labelColor;

  Color _cellColor(int words) {
    if (words <= 0) return emptyColor;
    if (words < 100) return activeColor.withAlpha(80);
    if (words < 300) return activeColor.withAlpha(140);
    return activeColor;
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  void paint(Canvas canvas, Size size) {
    final cellPaint = Paint()..style = PaintingStyle.fill;
    final textStyle = TextStyle(
      color: labelColor,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    // Track which columns have had their month label drawn already.
    int? lastMonthDrawn;

    for (var col = 0; col < _kWeeks; col++) {
      for (var row = 0; row < 7; row++) {
        final idx = col * 7 + row;
        if (idx >= dates.length) continue;

        final date = dates[idx];
        final key = _dateKey(date);
        final words = heatmapData[key] ?? 0;

        final x = col * _kCellStep;
        final y = _kMonthLabelHeight + _kGap + row * _kCellStep;

        // Month label on the first day of a new month (row == 0 of the column).
        if (row == 0 && date.month != lastMonthDrawn) {
          lastMonthDrawn = date.month;
          final label = _kSpanishMonths[date.month - 1];
          final tp = TextPainter(
            text: TextSpan(text: label, style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(x, 0));
        }

        cellPaint.color = _cellColor(words);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, _kCellSize, _kCellSize),
            const Radius.circular(2),
          ),
          cellPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.heatmapData != heatmapData ||
      old.emptyColor != emptyColor ||
      old.activeColor != activeColor ||
      old.labelColor != labelColor;
}
