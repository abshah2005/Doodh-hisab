import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/customer.dart';
import '../data/repositories/billing_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../l10n/strings.dart';
import '../services/bill.dart';
import '../services/bill_message.dart';
import '../state/settings_controller.dart';
import '../theme.dart';
import '../util/date_util.dart';
import '../util/format.dart';

class MonthlyBillScreen extends StatefulWidget {
  final int customerId;
  final DateTime month;
  const MonthlyBillScreen({
    super.key,
    required this.customerId,
    required this.month,
  });

  @override
  State<MonthlyBillScreen> createState() => _MonthlyBillScreenState();
}

class _MonthlyBillScreenState extends State<MonthlyBillScreen> {
  final _billing = BillingRepository();
  final _customers = CustomerRepository();
  final _shotController = ScreenshotController();

  Customer? _customer;
  BillResult? _bill;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _customers.byId(widget.customerId);
    if (c == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final bill = await _billing.monthlyBill(c, widget.month);
    if (!mounted) return;
    setState(() {
      _customer = c;
      _bill = bill;
      _loading = false;
    });
  }

  Future<void> _shareText() async {
    final settings = context.read<SettingsController>();
    final msg =
        BillMessage.build(_bill!, businessName: settings.businessName);
    await Share.share(msg);
  }

  Future<void> _shareImage() async {
    // Read context-bound state before any await.
    final businessName = context.read<SettingsController>().businessName;
    final caption = BillMessage.build(_bill!, businessName: businessName);

    final Uint8List? bytes = await _shotController.capture(
      delay: const Duration(milliseconds: 20),
      pixelRatio: 2.5,
    );
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/bill_${_customer!.id}_${DateUtil.toKey(widget.month)}.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: caption);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>().strings;
    if (_loading || _bill == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(s.billTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Screenshot(
            controller: _shotController,
            child: Container(
              color: Colors.white,
              child: _BillCard(bill: _bill!, s: s),
            ),
          ),
        ],
      ),
      bottomSheet: Material(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(s.shareImage),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareText,
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366)),
                    icon: const Icon(Icons.share),
                    label: Text(s.sendWhatsApp),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillResult bill;
  final Strings s;
  const _BillCard({required this.bill, required this.s});

  @override
  Widget build(BuildContext context) {
    final b = bill;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(b.customer.name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          Text(DateUtil.monthYear(b.from),
              style: TextStyle(
                  fontSize: 14, color: Colors.black.withValues(alpha: 0.6))),
          const Divider(height: 24),
          _row(s.daysSupplied, '${b.daysSupplied}'),
          _row(s.totalMilk, Fmt.qtyUnit(b.totalQty, b.unit)),
          if (b.extraQty > 0)
            _row(s.extraMilk, Fmt.qtyUnit(b.extraQty, b.unit), dim: true),
          _row(_rateLabel(b), ''),
          _row(s.milkCharges, Fmt.rs(b.milkCharges), bold: true),
          const Divider(height: 24),
          if (b.previousBalance != 0)
            _row(s.previousBalance, Fmt.rs(b.previousBalance)),
          if (b.paidInPeriod > 0)
            _row(s.paidThisMonth, '− ${Fmt.rs(b.paidInPeriod)}'),
          _row(s.balanceDue, Fmt.rs(b.balanceDue), bold: true, big: true),
          if (b.nagaDays.isNotEmpty) ...[
            const Divider(height: 24),
            Text('${s.nagaDates} (${b.nagaCount})',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(_nagaText(b),
                style: TextStyle(color: Colors.black.withValues(alpha: 0.75))),
          ],
        ],
      ),
    );
  }

  String _rateLabel(BillResult b) {
    if (b.rates.isEmpty) return s.rate;
    if (b.rates.length == 1) {
      return '${s.rate}: ${Fmt.rs(b.rates.first.price)}/${b.unit.code}';
    }
    final parts = b.rates.map((r) {
      final d = DateUtil.dayMonth(DateUtil.fromKey(r.fromKey));
      return '${Fmt.rs(r.price)} ($d)';
    }).join(', ');
    return '${s.rate}: $parts';
  }

  String _nagaText(BillResult b) {
    final away = b.nagaDays
        .where((n) => n.reason?.name == 'customerRefused')
        .map((n) => n.date.day)
        .toList();
    final missed = b.nagaDays
        .where((n) => n.reason?.name == 'supplierMissed')
        .map((n) => n.date.day)
        .toList();
    final other = b.nagaDays
        .where((n) =>
            n.reason == null ||
            (n.reason!.name != 'customerRefused' &&
                n.reason!.name != 'supplierMissed'))
        .map((n) => n.date.day)
        .toList();
    final parts = <String>[];
    if (away.isNotEmpty) {
      parts.add('${DateUtil.ordinalDays(away)} (${s.customerAway})');
    }
    if (missed.isNotEmpty) {
      parts.add('${DateUtil.ordinalDays(missed)} (${s.supplierMissed})');
    }
    if (other.isNotEmpty) parts.add(DateUtil.ordinalDays(other));
    return parts.join('\n');
  }

  Widget _row(String label, String value,
      {bool bold = false, bool big = false, bool dim = false}) {
    final style = TextStyle(
      fontSize: big ? 18 : 15,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: dim ? Colors.black.withValues(alpha: 0.55) : Colors.black,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          if (value.isNotEmpty)
            Text(value,
                style: style.copyWith(
                    color: big ? AppTheme.owe : style.color)),
        ],
      ),
    );
  }
}
