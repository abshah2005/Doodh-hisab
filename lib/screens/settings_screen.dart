import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../state/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _business;

  @override
  void initState() {
    super.initState();
    _business = TextEditingController(
        text: context.read<SettingsController>().businessName);
  }

  @override
  void dispose() {
    _business.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final s = settings.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Zuban / Language',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  SegmentedButton<AppLang>(
                    segments: const [
                      ButtonSegment(
                          value: AppLang.romanUrdu,
                          label: Text('Roman Urdu')),
                      ButtonSegment(
                          value: AppLang.english, label: Text('English')),
                    ],
                    selected: {settings.lang},
                    onSelectionChanged: (set) =>
                        settings.setLang(set.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Two rounds a day
          Card(
            child: SwitchListTile(
              title: Text('${s.subah} + ${s.shaam}'),
              subtitle: const Text('Do waqt supply (two rounds a day)'),
              value: settings.twoRounds,
              onChanged: settings.setTwoRounds,
            ),
          ),
          const SizedBox(height: 12),
          // Combined unit
          Card(
            child: SwitchListTile(
              title: const Text('Litre + Kg milaa ke dikhao'),
              subtitle: const Text(
                  'Combine litre and kg into one figure (1 L ≈ 1.03 kg)'),
              value: settings.combinedUnit,
              onChanged: settings.setCombinedUnit,
            ),
          ),
          const SizedBox(height: 12),
          // Business name (for bill footer)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Business ka naam (bill ke neeche)',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _business,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Rashid Dairy',
                    ),
                    onChanged: settings.setBusinessName,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Doodh Hisaab · v1.0.0',
                style:
                    TextStyle(color: Colors.black.withValues(alpha: 0.4))),
          ),
        ],
      ),
    );
  }
}
