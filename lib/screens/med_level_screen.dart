import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

const Map<String, double> kHalfLives = {
  'Ozempic': 168.0,
  'Wegovy': 168.0,
  'Compounded Semaglutide': 168.0,
  'Mounjaro': 120.0,
  'Zepbound': 120.0,
  'Compounded Tirzepatide': 120.0,
  'Saxenda': 13.0,
  'Rybelsus': 168.0,
  'Other': 168.0,
};

const Map<String, String> kMedDescriptions = {
  'Ozempic': 'Semaglutide · ~7 day half-life',
  'Wegovy': 'Semaglutide · ~7 day half-life',
  'Compounded Semaglutide': 'Semaglutide · ~7 day half-life',
  'Mounjaro': 'Tirzepatide · ~5 day half-life',
  'Zepbound': 'Tirzepatide · ~5 day half-life',
  'Compounded Tirzepatide': 'Tirzepatide · ~5 day half-life',
  'Saxenda': 'Liraglutide · ~13 hour half-life',
  'Rybelsus': 'Oral Semaglutide · ~7 day half-life',
  'Other': 'Custom · ~7 day half-life',
};

double _calcRemaining(double hoursElapsed, double halfLifeHours) {
  if (hoursElapsed <= 0) return 1.0;
  return math.pow(0.5, hoursElapsed / halfLifeHours).toDouble();
}

String _formatHours(double hours) {
  if (hours < 24) return '${hours.toStringAsFixed(1)}h';
  final days = (hours / 24).floor();
  final rem = (hours % 24).toStringAsFixed(0);
  return '${days}d ${rem}h';
}

Color _levelColor(double pct) {
  if (pct > 60) return const Color(0xFF2ECC71);
  if (pct > 30) return const Color(0xFFF1C40F);
  if (pct > 10) return const Color(0xFFE67E22);
  return const Color(0xFFE74C3C);
}

class MedLevelScreen extends StatefulWidget {
  const MedLevelScreen({super.key});

  @override
  State<MedLevelScreen> createState() => _MedLevelScreenState();
}

class _MedLevelScreenState extends State<MedLevelScreen> {
  Map<String, dynamic>? _selectedLog;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final logs = p.medicationLogs;
    if (_selectedLog == null && logs.isNotEmpty) {
      _selectedLog = logs.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Med Levels', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: logs.isEmpty
          ? const _EmptyMedLevel()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DisclaimerBanner(),
                const SizedBox(height: 16),
                const Text('Select a Dose',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _DoseSelector(
                  logs: logs,
                  selectedLog: _selectedLog,
                  onSelected: (log) => setState(() => _selectedLog = log),
                ),
                const SizedBox(height: 20),
                if (_selectedLog != null) ...[
                  _MedLevelCard(log: _selectedLog!),
                  const SizedBox(height: 16),
                  _MedLevelChart(log: _selectedLog!),
                  const SizedBox(height: 16),
                  _HalfLifeBreakdownCard(log: _selectedLog!),
                ],
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7C6EFA).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C6EFA).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_rounded, color: Color(0xFF7C6EFA), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estimates use pharmacokinetic half-life data. For informational purposes only — not medical advice.',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseSelector extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  final Map<String, dynamic>? selectedLog;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _DoseSelector({
    required this.logs,
    required this.selectedLog,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: logs.length,
        itemBuilder: (ctx, i) {
          final log = logs[i];
          final isSelected = selectedLog?['id'] == log['id'];
          final date = DateTime.parse(log['logged_at'] as String);
          return GestureDetector(
            onTap: () => onSelected(log),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7C6EFA).withOpacity(0.25)
                    : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF7C6EFA) : Colors.white24,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    log['medication_name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? const Color(0xFF7C6EFA) : Colors.white,
                    ),
                  ),
                  Text('${log['dose']}${log['dose_unit']}',
                      style: const TextStyle(fontSize: 11, color: Colors.white60)),
                  Text(DateFormat('MMM d, h:mm a').format(date),
                      style: const TextStyle(fontSize: 10, color: Colors.white38)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MedLevelCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _MedLevelCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final medName = log['medication_name'] as String;
    final dose = (log['dose'] as num).toDouble();
    final doseUnit = log['dose_unit'] as String;
    final loggedAt = DateTime.parse(log['logged_at'] as String);
    final halfLifeHours = kHalfLives[medName] ?? 168.0;
    final hoursElapsed = DateTime.now().difference(loggedAt).inMinutes / 60.0;
    final remaining = _calcRemaining(hoursElapsed, halfLifeHours);
    final currentLevel = dose * remaining;
    final pct = (remaining * 100).clamp(0.0, 100.0);
    final color = _levelColor(pct);
    final halfsPassed = (hoursElapsed / halfLifeHours).floor();
    final hoursUntilNext = halfLifeHours * (halfsPassed + 1) - hoursElapsed;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.22), const Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(kMedDescriptions[medName] ?? 'Custom medication',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text('${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _InfoChip(
                icon: Icons.vaccines_rounded,
                label: 'Original Dose',
                value: '$dose $doseUnit'),
            const SizedBox(width: 8),
            _InfoChip(
                icon: Icons.water_drop_rounded,
                label: 'Est. Active',
                value: '${currentLevel.toStringAsFixed(3)} $doseUnit',
                color: color),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _InfoChip(
                icon: Icons.access_time_rounded,
                label: 'Time Since Dose',
                value: _formatHours(hoursElapsed)),
            const SizedBox(width: 8),
            _InfoChip(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Next Half-Life In',
                value: _formatHours(hoursUntilNext)),
          ]),
        ],
      ),
    );
  }
}

class _MedLevelChart extends StatelessWidget {
  final Map<String, dynamic> log;
  const _MedLevelChart({required this.log});

  @override
  Widget build(BuildContext context) {
    final medName = log['medication_name'] as String;
    final dose = (log['dose'] as num).toDouble();
    final loggedAt = DateTime.parse(log['logged_at'] as String);
    final halfLifeHours = kHalfLives[medName] ?? 168.0;
    final totalHours = halfLifeHours * 3;
    final hoursElapsed = DateTime.now().difference(loggedAt).inMinutes / 60.0;
    final interval = halfLifeHours > 24 ? 12.0 : 1.0;

    final spots = <FlSpot>[];
    for (double h = 0; h <= totalHours; h += interval) {
      spots.add(FlSpot(h, dose * _calcRemaining(h, halfLifeHours)));
    }

    final currentX = hoursElapsed.clamp(0.0, totalHours);
    final currentY = dose * _calcRemaining(currentX, halfLifeHours);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Drug Level Over Time',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            'Showing ${(totalHours / 24).toStringAsFixed(0)} days  ·  dashed line = now',
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: dose * 1.1,
              minX: 0,
              maxX: totalHours,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 9, color: Colors.white38)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: halfLifeHours,
                    getTitlesWidget: (v, _) => Text(
                        '${(v / 24).toStringAsFixed(0)}d',
                        style: const TextStyle(fontSize: 9, color: Colors.white38)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(verticalLines: [
                VerticalLine(
                  x: currentX,
                  color: Colors.white54,
                  strokeWidth: 1.5,
                  dashArray: [5, 5],
                  label: VerticalLineLabel(
                    show: true,
                    labelResolver: (_) => 'NOW',
                    style: const TextStyle(
                        fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold),
                    alignment: Alignment.topRight,
                  ),
                ),
              ]),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF7C6EFA),
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF7C6EFA).withOpacity(0.08)),
                ),
                LineChartBarData(
                  spots: [FlSpot(currentX, currentY)],
                  barWidth: 0,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 6,
                      color: const Color(0xFF7C6EFA),
                      strokeWidth: 2.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

class _HalfLifeBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _HalfLifeBreakdownCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final medName = log['medication_name'] as String;
    final dose = (log['dose'] as num).toDouble();
    final doseUnit = log['dose_unit'] as String;
    final halfLifeHours = kHalfLives[medName] ?? 168.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Half-Life Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...List.generate(5, (i) {
            final n = i + 1;
            final hoursAt = halfLifeHours * n;
            final remaining = dose * math.pow(0.5, n).toDouble();
            final pct = math.pow(0.5, n).toDouble() * 100;
            final color = _levelColor(pct);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Text('$n',
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_formatHours(hoursAt),
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ),
                  Text('${remaining.toStringAsFixed(3)} $doseUnit',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text('(${pct.toStringAsFixed(1)}%)',
                      style: TextStyle(color: color, fontSize: 11)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoChip(
      {required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color ?? Colors.white54),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 9, color: Colors.white38)),
                  Text(value,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color ?? Colors.white),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMedLevel extends StatelessWidget {
  const _EmptyMedLevel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_rounded, size: 56, color: Colors.white24),
          SizedBox(height: 12),
          Text(
            'No medication doses logged yet.\nLog a dose first to see your\nestimated drug levels!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
