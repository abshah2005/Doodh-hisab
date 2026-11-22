import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/billing_repository.dart';
import '../l10n/strings.dart';
import '../state/settings_controller.dart';
import '../theme.dart';
import '../util/date_util.dart';
import '../util/format.dart';
import 'settings_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _billing = BillingRepository();
  ReportSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final summary = await _billing.reportSummary(DateTime.now());
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>().strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.hisaabTitle),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SettingsScreen()));
              _load();
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: s.settings,
          ),
        ],
      ),
      body: _loading || _summary == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  Text(DateUtil.monthYear(DateTime.now()),
                      style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _bigStat(s.todaySales,
                            Fmt.rs(_summary!.todaySales), AppTheme.seed),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _bigStat(s.monthSales,
                            Fmt.rs(_summary!.monthSales), AppTheme.extra),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _statTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: s.totalOutstanding,
                    value: Fmt.rs(_summary!.totalOutstanding),
                    color: AppTheme.owe,
                  ),
                  _statTile(
                    icon: Icons.south_west,
                    label: s.totalPayments,
                    value: Fmt.rs(_summary!.monthPayments),
                    color: AppTheme.delivered,
                  ),
                  const SizedBox(height: 12),
                  _nagaCard(s),
                ],
              ),
            ),
    );
  }

  Widget _bigStat(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.6))),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }

  Widget _nagaCard(Strings s) {
    final sm = _summary!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.totalNaga,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text('${sm.monthNagaCount}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.naga)),
              ],
            ),
            const Divider(height: 20),
            _nagaRow(s.customerAway, sm.monthNagaCustomerAway),
            const SizedBox(height: 6),
            _nagaRow(s.supplierMissed, sm.monthNagaSupplierMissed,
                highlight: true),
          ],
        ),
      ),
    );
  }

  Widget _nagaRow(String label, int count, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: highlight
                    ? AppTheme.naga
                    : Colors.black.withValues(alpha: 0.75),
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500)),
        Text('$count',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
