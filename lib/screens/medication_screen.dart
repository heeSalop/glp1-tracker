import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../widgets/body_map_widget.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medications', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Log'),
              Tab(text: 'Reminders'),
              Tab(text: 'Injection Map'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LogTab(),
            _RemindersTab(),
            _InjectionMapTab(),
          ],
        ),
      ),
    );
  }
}

// ─── LOG TAB ────────────────────────────────────────────────────────────────

void _showLogDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1A1A2E),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _LogMedSheet(),
  );
}

class _LogTab extends StatelessWidget {
  const _LogTab();

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<AppProvider>().medicationLogs;
    if (logs.isEmpty) {
      return Scaffold(
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vaccines_rounded, size: 48, color: Colors.white24),
              SizedBox(height: 12),
              Text('No doses logged yet.\nTap + to log your first dose!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (ctx) => FloatingActionButton.extended(
            onPressed: () => _showLogDialog(ctx),
            icon: const Icon(Icons.add),
            label: const Text('Log Dose'),
            backgroundColor: const Color(0xFF7C6EFA),
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          onPressed: () => _showLogDialog(ctx),
          icon: const Icon(Icons.add),
          label: const Text('Log Dose'),
          backgroundColor: const Color(0xFF7C6EFA),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (ctx, i) {
        final log = logs[i];
        final date = DateTime.parse(log['logged_at'] as String);
        return Dismissible(
          key: Key('med_${log['id']}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.red),
          ),
          onDismissed: (_) =>
              context.read<AppProvider>().deleteMedicationLog(log['id'] as int),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C6EFA).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    log['medication_type'] == 'injection'
                        ? Icons.vaccines_rounded
                        : Icons.medication_rounded,
                    color: const Color(0xFF7C6EFA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${log['medication_name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          '${log['dose']} ${log['dose_unit']}' +
                              (log['injection_site'] != null
                                  ? ' · ${log['injection_site']}'
                                  : ''),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white60)),
                      if (log['notes'] != null && log['notes'].isNotEmpty)
                        Text(log['notes'] as String,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                ),
                Text(DateFormat('MMM d\nh:mm a').format(date),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, color: Colors.white38)),
              ],
            ),
          ),
        );
      },
    ),
  );
  }
}

// ─── REMINDERS TAB ──────────────────────────────────────────────────────────

class _RemindersTab extends StatelessWidget {
  const _RemindersTab();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppProvider>().medicationSettings;
    return Scaffold(
      body: settings.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off_rounded, size: 48, color: Colors.white24),
                  SizedBox(height: 12),
                  Text('No reminders yet.\nTap + to add one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: settings.length,
              itemBuilder: (ctx, i) {
                final s = settings[i];
                final h = s['reminder_hour'] as int?;
                final m = s['reminder_minute'] as int?;
                final timeStr = (h != null && m != null)
                    ? TimeOfDay(hour: h, minute: m).format(ctx)
                    : 'No time';
                return Dismissible(
                  key: Key('reminder_${s['id']}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red.withOpacity(0.15),
                    child: const Icon(Icons.delete_rounded, color: Colors.red),
                  ),
                  onDismissed: (_) =>
                      context.read<AppProvider>().deleteMedicationSetting(s['id'] as int),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm_rounded, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${s['medication_name']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  '${s['dose']} ${s['dose_unit']} · ${s['frequency']} · $timeStr',
                                  style: const TextStyle(fontSize: 12, color: Colors.white60)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context),
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Add Reminder'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddReminderSheet(),
    );
  }
}

// ─── INJECTION MAP TAB ───────────────────────────────────────────────────────

class _InjectionMapTab extends StatelessWidget {
  const _InjectionMapTab();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7C6EFA).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7C6EFA).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF7C6EFA), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rotate injection sites to prevent lipohypertrophy. Green = safest to use.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: BodyMapWidget(
            siteLastUsed: p.siteLastUsed,
            onSiteTapped: (site) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selected: $site — log a dose to record this site!'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF7C6EFA),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── LOG MED BOTTOM SHEET ───────────────────────────────────────────────────

class _LogMedSheet extends StatefulWidget {
  const _LogMedSheet();

  @override
  State<_LogMedSheet> createState() => _LogMedSheetState();
}

class _LogMedSheetState extends State<_LogMedSheet> {
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  String _type = 'injection';
  String _doseUnit = 'mg';
  String? _selectedSite;
  final _notesCtrl = TextEditingController();

  final _glp1Meds = [
    'Ozempic', 'Wegovy', 'Mounjaro', 'Zepbound',
    'Saxenda', 'Rybelsus', 'Compounded Semaglutide',
    'Compounded Tirzepatide', 'Other'
  ];
  final _units = ['mg', 'mcg', 'mL', 'units'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Log a Dose',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Medication Name
            DropdownButtonFormField<String>(
              decoration: _inputDeco('Medication'),
              items: _glp1Meds
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => _nameCtrl.text = v ?? '',
            ),
            const SizedBox(height: 12),

            // Type toggle
            Row(
              children: [
                _TypeChip(
                    label: 'Injection',
                    icon: Icons.vaccines_rounded,
                    selected: _type == 'injection',
                    onTap: () => setState(() => _type = 'injection')),
                const SizedBox(width: 8),
                _TypeChip(
                    label: 'Pill / Oral',
                    icon: Icons.medication_rounded,
                    selected: _type == 'pill',
                    onTap: () => setState(() => _type = 'pill')),
              ],
            ),
            const SizedBox(height: 12),

            // Dose
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _doseCtrl,
                    decoration: _inputDeco('Dose Amount'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _doseUnit,
                  dropdownColor: const Color(0xFF2A2A4A),
                  items: _units
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => _doseUnit = v!),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Injection site (only for injections)
            if (_type == 'injection') ...[
              DropdownButtonFormField<String>(
                decoration: _inputDeco('Injection Site (optional)'),
                value: _selectedSite,
                items: kInjectionSites
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSite = v),
              ),
              const SizedBox(height: 12),
            ],

            // Notes
            TextField(
              controller: _notesCtrl,
              decoration: _inputDeco('Notes (optional)'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6EFA)),
                child: const Text('Log Dose'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_nameCtrl.text.isEmpty || _doseCtrl.text.isEmpty) return;
    context.read<AppProvider>().logMedication(
          name: _nameCtrl.text,
          type: _type,
          dose: double.tryParse(_doseCtrl.text) ?? 0,
          doseUnit: _doseUnit,
          site: _selectedSite,
          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Dose logged!'),
        backgroundColor: Color(0xFF2ECC71),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF0F0F1A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}

// ─── ADD REMINDER BOTTOM SHEET ──────────────────────────────────────────────

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  String _type = 'injection';
  String _doseUnit = 'mg';
  String _frequency = 'weekly';
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  int _weekday = DateTime.monday;

  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              decoration: _inputDeco('Medication Name'),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _doseCtrl,
                    decoration: _inputDeco('Dose'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _doseUnit,
                  dropdownColor: const Color(0xFF2A2A4A),
                  items: ['mg', 'mcg', 'mL', 'units']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setState(() => _doseUnit = v!),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Frequency
            Row(
              children: [
                _TypeChip(
                    label: 'Weekly',
                    icon: Icons.calendar_today_rounded,
                    selected: _frequency == 'weekly',
                    onTap: () => setState(() => _frequency = 'weekly')),
                const SizedBox(width: 8),
                _TypeChip(
                    label: 'Daily',
                    icon: Icons.today_rounded,
                    selected: _frequency == 'daily',
                    onTap: () => setState(() => _frequency = 'daily')),
              ],
            ),
            const SizedBox(height: 12),

            // Day picker (weekly only)
            if (_frequency == 'weekly') ...[
              const Text('Day of week:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _weekday = day),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _weekday == day
                            ? const Color(0xFF7C6EFA)
                            : const Color(0xFF0F0F1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text(_days[i], style: const TextStyle(fontSize: 11))),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],

            // Time picker
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                    context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.amber),
                    const SizedBox(width: 12),
                    Text('Reminder time: ${_time.format(context)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text('Save Reminder',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_nameCtrl.text.isEmpty) return;
    context.read<AppProvider>().addMedicationSetting(
          name: _nameCtrl.text,
          type: _type,
          dose: double.tryParse(_doseCtrl.text) ?? 0,
          doseUnit: _doseUnit,
          frequency: _frequency,
          reminderHour: _time.hour,
          reminderMinute: _time.minute,
          reminderDay: _frequency == 'weekly' ? _weekday : null,
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏰ Reminder set!'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF0F0F1A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7C6EFA).withOpacity(0.25)
              : const Color(0xFF0F0F1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF7C6EFA) : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? const Color(0xFF7C6EFA) : Colors.white54),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? const Color(0xFF7C6EFA) : Colors.white54,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
