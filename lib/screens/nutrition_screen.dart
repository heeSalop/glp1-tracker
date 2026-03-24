import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition & Water', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: const _NutritionBody(),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          onPressed: () => _showLogMealDialog(ctx),
          icon: const Icon(Icons.add),
          label: const Text('Log Meal'),
          backgroundColor: const Color(0xFF7C6EFA),
        ),
      ),
    );
  }

  void _showLogMealDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _LogMealSheet(),
    );
  }
}

class _NutritionBody extends StatelessWidget {
  const _NutritionBody();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily macro summary
        _MacroSummaryCard(p: p),
        const SizedBox(height: 16),

        // Water tracker
        _WaterTrackerCard(p: p),
        const SizedBox(height: 24),

        // Today's meals
        const Text("Today's Meals",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (p.todayNutritionLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.restaurant_menu_rounded, size: 36, color: Colors.white24),
                SizedBox(height: 8),
                Text('No meals logged today. Tap + to add one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38)),
              ],
            ),
          )
        else
          ...p.todayNutritionLogs.map((log) => _MealTile(log: log)),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _MacroSummaryCard extends StatelessWidget {
  final AppProvider p;
  const _MacroSummaryCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Nutrition",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              _MacroTile('Calories', p.todayCalories, 'kcal', Colors.orange),
              _MacroTile('Protein', p.todayProtein, 'g', Colors.green),
              _MacroTile('Carbs', p.todayCarbs, 'g', Colors.blue),
              _MacroTile('Fat', p.todayFat, 'g', Colors.pink),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            _MacroTile('Fiber', p.todayFiber, 'g', const Color(0xFF7C6EFA)),
          ]),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;

  const _MacroTile(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(0)}$unit',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── WATER TRACKER ───────────────────────────────────────────────────────────

class _WaterTrackerCard extends StatelessWidget {
  final AppProvider p;
  const _WaterTrackerCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final oz = p.todayWaterOz;
    const goal = 64.0; // 8 cups = 64 oz
    final progress = (oz / goal).clamp(0.0, 1.0);
    final glasses = (oz / 8).floor(); // 1 glass = 8oz

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('💧 Water Intake',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${oz.toStringAsFixed(0)} / 64 oz',
                  style: const TextStyle(color: Colors.blue, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.blue.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          // Glass icons
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(8, (i) {
              final filled = i < glasses;
              return Icon(
                filled ? Icons.local_drink_rounded : Icons.local_drink_outlined,
                color: filled ? Colors.blue : Colors.white24,
                size: 28,
              );
            }),
          ),
          const SizedBox(height: 12),
          // Quick add buttons
          Row(
            children: [
              _WaterBtn('+ 8 oz', 8, context),
              const SizedBox(width: 8),
              _WaterBtn('+ 16 oz', 16, context),
              const SizedBox(width: 8),
              _WaterBtn('+ 20 oz', 20, context),
            ],
          ),
          if (p.todayWaterLogs.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showHistory(context, p),
              child: const Text('View log →',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      decoration: TextDecoration.underline)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _WaterBtn(String label, double amount, BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => context.read<AppProvider>().logWater(amount, 'oz'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          side: const BorderSide(color: Colors.blue, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _showHistory(BuildContext context, AppProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Water Log",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: p.todayWaterLogs.map((log) {
                  final t = DateTime.parse(log['logged_at'] as String);
                  return ListTile(
                    leading: const Icon(Icons.water_drop_rounded, color: Colors.blue),
                    title: Text('${log['amount']} ${log['unit']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('h:mm a').format(t),
                            style: const TextStyle(color: Colors.white38)),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded,
                              color: Colors.red, size: 18),
                          onPressed: () {
                            context
                                .read<AppProvider>()
                                .deleteWaterLog(log['id'] as int);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MEAL TILE ───────────────────────────────────────────────────────────────

class _MealTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _MealTile({required this.log});

  Color get _mealColor {
    switch (log['meal_type'] as String) {
      case 'breakfast': return Colors.orange;
      case 'lunch': return const Color(0xFF7C6EFA);
      case 'dinner': return Colors.blue;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateTime.parse(log['logged_at'] as String);
    return Dismissible(
      key: Key('nutrition_${log['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      onDismissed: (_) =>
          context.read<AppProvider>().deleteNutritionLog(log['id'] as int),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _mealColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                (log['meal_type'] as String).toUpperCase(),
                style:
                    TextStyle(color: _mealColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log['meal_name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${(log['calories'] as num).toStringAsFixed(0)} kcal · '
                    '${(log['protein'] as num).toStringAsFixed(0)}g protein · '
                    '${(log['carbs'] as num).toStringAsFixed(0)}g carbs',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Text(DateFormat('h:mm a').format(time),
                style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

// ─── LOG MEAL SHEET ──────────────────────────────────────────────────────────

class _LogMealSheet extends StatefulWidget {
  const _LogMealSheet();

  @override
  State<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<_LogMealSheet> {
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _fiberCtrl = TextEditingController();
  String _mealType = 'breakfast';

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
            const Text('Log a Meal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              decoration: _deco('Meal Name (e.g. Grilled Chicken)'),
            ),
            const SizedBox(height: 12),

            // Meal type selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['breakfast', 'lunch', 'dinner', 'snack'].map((t) {
                  final selected = _mealType == t;
                  return GestureDetector(
                    onTap: () => setState(() => _mealType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF7C6EFA).withOpacity(0.25)
                            : const Color(0xFF0F0F1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF7C6EFA)
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        t[0].toUpperCase() + t.substring(1),
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF7C6EFA)
                              : Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Macros row
            Row(children: [
              Expanded(child: _numField(_calCtrl, 'Calories')),
              const SizedBox(width: 8),
              Expanded(child: _numField(_proteinCtrl, 'Protein (g)')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _numField(_carbsCtrl, 'Carbs (g)')),
              const SizedBox(width: 8),
              Expanded(child: _numField(_fatCtrl, 'Fat (g)')),
            ]),
            const SizedBox(height: 8),
            _numField(_fiberCtrl, 'Fiber (g)'),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6EFA)),
                child: const Text('Save Meal'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label) => TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: _deco(label),
      );

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF0F0F1A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  void _submit() {
    if (_nameCtrl.text.isEmpty) return;
    context.read<AppProvider>().logMeal(
          name: _nameCtrl.text,
          type: _mealType,
          calories: double.tryParse(_calCtrl.text) ?? 0,
          protein: double.tryParse(_proteinCtrl.text) ?? 0,
          carbs: double.tryParse(_carbsCtrl.text) ?? 0,
          fat: double.tryParse(_fatCtrl.text) ?? 0,
          fiber: double.tryParse(_fiberCtrl.text) ?? 0,
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🍽️ Meal logged!'),
        backgroundColor: Color(0xFF7C6EFA),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _calCtrl, _proteinCtrl, _carbsCtrl, _fatCtrl, _fiberCtrl]) {
      c.dispose();
    }
    super.dispose();
  }
}
