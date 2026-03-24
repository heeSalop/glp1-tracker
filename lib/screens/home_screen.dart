import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import 'medication_screen.dart';
import 'weight_screen.dart';
import 'nutrition_screen.dart';
import 'med_level_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      _DashboardTab(onNavigate: _goToTab),
      const MedicationScreen(),
      const WeightScreen(),
      const NutritionScreen(),
      const MedLevelScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToTab,
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: const Color(0xFF7C6EFA).withOpacity(0.25),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.medication_rounded), label: 'Meds'),
          NavigationDestination(icon: Icon(Icons.monitor_weight_rounded), label: 'Body'),
          NavigationDestination(icon: Icon(Icons.restaurant_rounded), label: 'Nutrition'),
          NavigationDestination(icon: Icon(Icons.science_rounded), label: 'Levels'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _DashboardTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('GLP-1 Tracker',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(today,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => p.loadAll(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C6EFA), Color(0xFF4A90E2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Journey 💜',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    p.latestWeight != null
                        ? 'Current weight: ${p.latestWeight!.toStringAsFixed(1)} ${p.weightUnit}'
                        : 'Log your first weight to get started!',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section header
            Row(children: [
              const Text('Quick Stats',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('tap to log',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withOpacity(0.35))),
            ]),
            const SizedBox(height: 10),

            Row(children: [
              _StatCard(
                icon: Icons.water_drop_rounded,
                label: 'Water Today',
                value: '${p.todayWaterOz.toStringAsFixed(0)} oz',
                color: Colors.blue,
                progress: p.todayWaterOz / 64,
                onTap: () => onNavigate(3),
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Calories',
                value: '${p.todayCalories.toStringAsFixed(0)} kcal',
                color: Colors.orange,
                onTap: () => onNavigate(3),
              ),
            ]),
            const SizedBox(height: 12),

            Row(children: [
              _StatCard(
                icon: Icons.fitness_center_rounded,
                label: 'Protein',
                value: '${p.todayProtein.toStringAsFixed(0)}g',
                color: Colors.green,
                onTap: () => onNavigate(3),
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.monitor_weight_rounded,
                label: 'Weight',
                value: p.latestWeight != null
                    ? '${p.latestWeight!.toStringAsFixed(1)} ${p.weightUnit}'
                    : 'Log it!',
                color: const Color(0xFF7C6EFA),
                onTap: () => onNavigate(2),
              ),
            ]),
            const SizedBox(height: 12),

            Row(children: [
              _StatCard(
                icon: Icons.medication_rounded,
                label: 'Doses Today',
                value: p.medicationLogs
                    .where((l) =>
                        (l['logged_at'] as String).startsWith(p.todayPrefix))
                    .length
                    .toString(),
                color: Colors.teal,
                onTap: () => onNavigate(1),
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.science_rounded,
                label: 'Med Levels',
                value: p.medicationLogs.isNotEmpty ? 'View →' : 'Log meds',
                color: Colors.purpleAccent,
                onTap: () => onNavigate(4),
              ),
            ]),

            const SizedBox(height: 24),

            // Recent meds header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Medications',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => onNavigate(1),
                  child: const Text('See all',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C6EFA),
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (p.medicationLogs.isEmpty)
              _EmptyState(
                icon: Icons.medication_rounded,
                message: 'No medications logged yet',
                buttonLabel: 'Log a dose',
                onTap: () => onNavigate(1),
              )
            else
              ...p.medicationLogs.take(3).map((log) => _MedLogTile(log: log)),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Reminders',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => onNavigate(1),
                  child: const Text('Manage',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C6EFA),
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (p.medicationSettings.isEmpty)
              _EmptyState(
                icon: Icons.alarm_rounded,
                message: 'No reminders set up',
                buttonLabel: 'Add reminder',
                onTap: () => onNavigate(1),
              )
            else
              ...p.medicationSettings.map((s) => _ReminderTile(setting: s)),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double? progress;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  Icon(Icons.chevron_right_rounded,
                      color: color.withOpacity(0.5), size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5))),
              if (progress != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0),
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MedLogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _MedLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(log['logged_at'] as String);
    final isInjection = log['medication_type'] == 'injection';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C6EFA).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isInjection ? Icons.vaccines_rounded : Icons.medication_rounded,
              color: const Color(0xFF7C6EFA),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${log['medication_name']} — ${log['dose']}${log['dose_unit']}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (log['injection_site'] != null)
                  Text('Site: ${log['injection_site']}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5))),
              ],
            ),
          ),
          Text(DateFormat('MMM d, h:mm a').format(date),
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4))),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Map<String, dynamic> setting;
  const _ReminderTile({required this.setting});

  @override
  Widget build(BuildContext context) {
    final h = setting['reminder_hour'];
    final m = setting['reminder_minute'];
    final timeStr = (h != null && m != null)
        ? TimeOfDay(hour: h as int, minute: m as int).format(context)
        : 'No time set';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(setting['medication_name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${setting['frequency']} · $timeStr',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onTap;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 32,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4))),
          if (buttonLabel != null && onTap != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C6EFA),
                side: const BorderSide(color: Color(0xFF7C6EFA)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: Text(buttonLabel!, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}
