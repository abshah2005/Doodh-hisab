import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/enums.dart';
import '../data/models/customer.dart';
import '../data/models/daily_entry.dart';
import '../data/models/payment.dart';
import '../data/repositories/billing_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../l10n/strings.dart';
import '../state/settings_controller.dart';
import '../theme.dart';
import '../util/date_util.dart';
import '../util/format.dart';
import '../widgets/sheets.dart';
import 'add_edit_customer_screen.dart';
import 'monthly_bill_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _customers = CustomerRepository();
  final _billing = BillingRepository();
  final _payments = PaymentRepository();

  Customer? _customer;
  DateTime _month = DateUtil.firstOfMonth(DateUtil.today());
  Map<String, List<DailyEntry>> _entriesByDate = {};
  List<Payment> _monthPayments = [];
  double _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await _customers.byId(widget.customerId);
    if (c == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final entries = await _billing.monthEntriesByDate(c, _month);
    final pays = await _payments.forCustomerRange(
      c.id!,
      DateUtil.toKey(DateUtil.firstOfMonth(_month)),
      DateUtil.toKey(DateUtil.lastOfMonth(_month)),
    );
    final balance = await _billing.currentBalance(c);
    if (!mounted) return;
    setState(() {
      _customer = c;
      _entriesByDate = entries;
      _monthPayments = pays;
      _balance = balance;
      _loading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
    _load();
  }

  Future<void> _addPayment() async {
    final s = context.read<SettingsController>().strings;
    final c = _customer!;
    final res = await showPaymentSheet(context, s, c);
    if (res == null) return;
    await _payments.add(Payment(
      customerId: c.id!,
      date: DateUtil.toKey(DateUtil.today()),
      amount: res.amount,
      method: res.method,
      createdAt: DateTime.now().toIso8601String(),
    ));
    _load();
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditCustomerScreen(existing: _customer),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _viewBill() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          MonthlyBillScreen(customerId: _customer!.id!, month: _month),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>().strings;
    if (_loading || _customer == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    final c = _customer!;
    final owes = _balance > 0.5;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          IconButton(
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: s.edit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          _balanceCard(s, owes),
          const SizedBox(height: 16),
          _monthHeader(s),
          const SizedBox(height: 8),
          _calendar(s),
          const SizedBox(height: 8),
          _legend(s),
          const SizedBox(height: 20),
          Text(s.payments,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_monthPayments.isEmpty)
            Text('—',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.5)))
          else
            ..._monthPayments.map((p) => _paymentTile(p, s)),
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
                    onPressed: _addPayment,
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(s.addPayment),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _viewBill,
                    icon: const Icon(Icons.receipt_long),
                    label: Text(s.viewBill),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(Strings s, bool owes) {
    return Card(
      color: owes ? const Color(0xFFFCF4E2) : const Color(0xFFE8F1EE),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(owes ? Icons.account_balance_wallet : Icons.check_circle,
                color: owes ? AppTheme.owe : AppTheme.delivered),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.balance,
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.6))),
                Text(Fmt.rs(_balance.abs()),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthHeader(Strings s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left)),
        Text(DateUtil.monthYear(_month),
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  Widget _calendar(Strings s) {
    final first = DateUtil.firstOfMonth(_month);
    final daysInMonth = DateUtil.lastOfMonth(_month).day;
    // weekday: Mon=1..Sun=7; grid starts on Monday.
    final leading = first.weekday - 1;
    final cells = <Widget>[];
    for (int i = 0; i < leading; i++) {
      cells.add(const SizedBox());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final key = DateUtil.toKey(DateTime(_month.year, _month.month, day));
      cells.add(_dayCell(day, _entriesByDate[key] ?? const []));
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: cells,
    );
  }

  Widget _dayCell(int day, List<DailyEntry> entries) {
    bool hasExtra = entries.any((e) => e.status == EntryStatus.extra);
    bool hasDelivered =
        entries.any((e) => e.status == EntryStatus.delivered) || hasExtra;
    bool hasNaga = entries.any((e) => e.status == EntryStatus.naga);

    Color bg = const Color(0xFFF0F1EF);
    Widget? mark;
    if (hasExtra) {
      bg = const Color(0xFFE7EEFC);
      mark = const Icon(Icons.add, size: 16, color: AppTheme.extra);
    } else if (hasNaga && !hasDelivered) {
      bg = const Color(0xFFF7E3E3);
      mark = const Text('N',
          style: TextStyle(
              color: AppTheme.naga, fontWeight: FontWeight.w800));
    } else if (hasDelivered) {
      bg = const Color(0xFFE2EFE9);
      mark = const Icon(Icons.check, size: 16, color: AppTheme.delivered);
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$day',
              style: TextStyle(
                  fontSize: 11, color: Colors.black.withValues(alpha: 0.55))),
          SizedBox(height: 16, child: Center(child: mark ?? const SizedBox())),
        ],
      ),
    );
  }

  Widget _legend(Strings s) {
    Widget item(Widget mark, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.6))),
          ],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        item(const Icon(Icons.check, size: 15, color: AppTheme.delivered),
            s.delivered),
        item(
            const Text('N',
                style: TextStyle(
                    color: AppTheme.naga,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            s.naga),
        item(const Icon(Icons.add, size: 15, color: AppTheme.extra),
            s.extraMilk),
      ],
    );
  }

  Widget _paymentTile(Payment p, Strings s) {
    final methodLabel = switch (p.method) {
      PaymentMethod.cash => s.methodCash,
      PaymentMethod.jazzcash => s.methodJazzCash,
      PaymentMethod.easypaisa => s.methodEasypaisa,
      PaymentMethod.bank => s.methodBank,
    };
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.south_west, color: AppTheme.delivered),
      title: Text(Fmt.rs(p.amount),
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$methodLabel · ${DateUtil.pretty(DateUtil.fromKey(p.date))}'),
    );
  }
}
