import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';

class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Body', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Weight'),
              Tab(text: 'Measurements'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _WeightTab(),
            _MeasurementsTab(),
          ],
        ),
      ),
    );
  }
}

// ─── WEIGHT TAB ─────────────────────────────────────────────────────────────

class _WeightTab extends StatelessWidget {
  const _WeightTab();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final logs = p.weightLogs;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          if (logs.isNotEmpty) ...[
            _WeightSummaryCard(logs: logs),
            const SizedBox(height: 16),
            // Chart
            _WeightChart(logs: logs),
            const SizedBox(height: 24),
            const Text('History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ],
          if (logs.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 80),
                  Icon(Icons.monitor_weight_rounded, size: 56, color: Colors.white24),
                  SizedBox(height: 12),
                  Text('No weight logs yet.\nTap + to log your weight!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38)),
                ],
              ),
            ),
          // History list (reversed for newest first)
          ...logs.reversed.map((log) {
            final date = DateTime.parse(log['logged_at'] as String);
            return Dismissible(
              key: Key('weight_${log['id']}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete_rounded, color: Colors.red),
              ),
              onDismissed: (_) =>
                  context.read<AppProvider>().deleteWeightLog(log['id'] as int),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monitor_weight_rounded,
                        color: Color(0xFF7C6EFA)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${(log['weight'] as num).toStringAsFixed(1)} ${log['weight_unit']}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(DateFormat('MMM d, yyyy').format(date),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogDialog(context, p.weightUnit),
        icon: const Icon(Icons.add),
        label: const Text('Log Weight'),
        backgroundColor: const Color(0xFF7C6EFA),
      ),
    );
  }

  void _showLogDialog(BuildContext context, String currentUnit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LogWeightSheet(currentUnit: currentUnit),
    );
  }
}

class _WeightSummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  const _WeightSummaryCard({required this.logs});

  @override
  Widget build(BuildContext context) {
    final latest = (logs.last['weight'] as num).toDouble();
    final unit = logs.last['weight_unit'] as String;
    final first = (logs.first['weight'] as num).toDouble();
    final diff = latest - first;
    final isLoss = diff < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLoss
              ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
              : [const Color(0xFF7C6EFA), const Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Weight',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${latest.toStringAsFixed(1)} $unit',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total Change',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  color: isLoss ? Colors.white : Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<Map<String, dynamic>> logs;
  const _WeightChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.length < 2) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Log at least 2 entries to see your trend',
              style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    final spots = logs.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['weight'] as num).toDouble());
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            drawHorizontalLine: true,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white12,
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (val, _) => Text(
                  val.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF7C6EFA),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF7C6EFA).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MEASUREMENTS TAB ────────────────────────────────────────────────────────

class _MeasurementsTab extends StatelessWidget {
  const _MeasurementsTab();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<AppProvider>().measurementLogs;

    return Scaffold(
      body: logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.straighten_rounded, size: 56, color: Colors.white24),
                  SizedBox(height: 12),
                  Text('No measurements yet.\nTap + to log your measurements!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (ctx, i) {
                final log = logs[i];
                final date = DateTime.parse(log['logged_at'] as String);
                final unit = log['unit'] as String;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('MMM d, yyyy').format(date),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(unit, style: const TextStyle(color: Colors.white60)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (log['waist'] != null)
                            _MeasureChip('Waist', log['waist'], unit),
                          if (log['hips'] != null)
                            _MeasureChip('Hips', log['hips'], unit),
                          if (log['chest'] != null)
                            _MeasureChip('Chest', log['chest'], unit),
                          if (log['left_arm'] != null)
                            _MeasureChip('L Arm', log['left_arm'], unit),
                          if (log['right_arm'] != null)
                            _MeasureChip('R Arm', log['right_arm'], unit),
                          if (log['left_thigh'] != null)
                            _MeasureChip('L Thigh', log['left_thigh'], unit),
                          if (log['right_thigh'] != null)
                            _MeasureChip('R Thigh', log['right_thigh'], unit),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Measurements'),
        backgroundColor: const Color(0xFF7C6EFA),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _LogMeasurementsSheet(),
    );
  }
}

class _MeasureChip extends StatelessWidget {
  final String label;
  final dynamic value;
  final String unit;
  const _MeasureChip(this.label, this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7C6EFA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7C6EFA).withOpacity(0.3)),
      ),
      child: Text(
        '$label: ${(value as num).toStringAsFixed(1)} $unit',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

// ─── LOG WEIGHT SHEET ────────────────────────────────────────────────────────

class _LogWeightSheet extends StatefulWidget {
  final String currentUnit;
  const _LogWeightSheet({required this.currentUnit});

  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends State<_LogWeightSheet> {
  final _ctrl = TextEditingController();
  late String _unit;

  @override
  void initState() {
    super.initState();
    _unit = widget.currentUnit;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Log Weight',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Weight',
                    filled: true,
                    fillColor: const Color(0xFF0F0F1A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _unit,
                dropdownColor: const Color(0xFF2A2A4A),
                items: ['lbs', 'kg', 'stone']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setState(() => _unit = v!),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final val = double.tryParse(_ctrl.text);
                if (val == null) return;
                context.read<AppProvider>().logWeight(val, _unit);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6EFA)),
              child: const Text('Save'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// ─── LOG MEASUREMENTS SHEET ──────────────────────────────────────────────────

class _LogMeasurementsSheet extends StatefulWidget {
  const _LogMeasurementsSheet();

  @override
  State<_LogMeasurementsSheet> createState() => _LogMeasurementsSheetState();
}

class _LogMeasurementsSheetState extends State<_LogMeasurementsSheet> {
  final _waist = TextEditingController();
  final _hips = TextEditingController();
  final _chest = TextEditingController();
  final _lArm = TextEditingController();
  final _rArm = TextEditingController();
  final _lThigh = TextEditingController();
  final _rThigh = TextEditingController();
  String _unit = 'in';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Log Measurements',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _unit,
                  dropdownColor: const Color(0xFF2A2A4A),
                  items: ['in', 'cm']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => _unit = v!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field(_waist, 'Waist ($_unit)'),
            _field(_hips, 'Hips ($_unit)'),
            _field(_chest, 'Chest ($_unit)'),
            _field(_lArm, 'Left Arm ($_unit)'),
            _field(_rArm, 'Right Arm ($_unit)'),
            _field(_lThigh, 'Left Thigh ($_unit)'),
            _field(_rThigh, 'Right Thigh ($_unit)'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6EFA)),
                child: const Text('Save Measurements'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: const Color(0xFF0F0F1A),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      );

  void _submit() {
    double? parse(TextEditingController c) =>
        c.text.isEmpty ? null : double.tryParse(c.text);
    context.read<AppProvider>().logMeasurements({
      'waist': parse(_waist),
      'hips': parse(_hips),
      'chest': parse(_chest),
      'left_arm': parse(_lArm),
      'right_arm': parse(_rArm),
      'left_thigh': parse(_lThigh),
      'right_thigh': parse(_rThigh),
      'unit': _unit,
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final c in [_waist, _hips, _chest, _lArm, _rArm, _lThigh, _rThigh]) {
      c.dispose();
    }
    super.dispose();
  }
}
