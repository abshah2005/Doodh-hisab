import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/enums.dart';
import '../data/models/customer.dart';
import '../data/models/daily_entry.dart';
import '../data/models/payment.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/entry_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/rate_repository.dart';
import '../l10n/strings.dart';
import '../state/settings_controller.dart';
import '../theme.dart';
import '../util/date_util.dart';
import '../widgets/customer_card.dart';
import '../widgets/sheets.dart';
import 'customer_detail_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _customers = CustomerRepository();
  final _entries = EntryRepository();
  final _payments = PaymentRepository();
  final _rates = RateRepository();

  final DateTime _date = DateUtil.today();
  Shift _shift = Shift.morning;

  List<Customer> _all = [];
  Map<int, DailyEntry> _entryByCustomer = {};
  double _looseTotal = 0;
  bool _loading = true;

  String get _dateKey => DateUtil.toKey(_date);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _customers.all();
    final entries = await _entries.entriesFor(_dateKey, _shift);
    final loose = await _entries.looseTotalOn(_dateKey);
    if (!mounted) return;
    setState(() {
      _all = all;
      _entryByCustomer = entries;
      _looseTotal = loose;
      _loading = false;
    });
  }

  /// Customers who have a fixed order on the current shift.
  List<Customer> get _onShift =>
      _all.where((c) => c.qtyForShift(_shift) > 0).toList();

  // ---- Footer totals ---------------------------------------------------

  Map<MilkUnit, double> _expectedByUnit() {
    final map = <MilkUnit, double>{};
    for (final c in _onShift) {
      final entry = _entryByCustomer[c.id];
      final qty = switch (entry?.status) {
        EntryStatus.naga => 0.0,
        null => c.qtyForShift(_shift), // not yet touched -> assume supplied
        _ => entry!.quantity,
      };
      map[c.unit] = (map[c.unit] ?? 0) + qty;
    }
    return map;
  }

  // ---- Actions ---------------------------------------------------------

  Future<void> _toggleNaga(Customer c) async {
    final entry = _entryByCustomer[c.id];
    if (entry?.status == EntryStatus.naga) {
      await _entries.deleteEntry(c.id!, _dateKey, _shift);
    } else {
      await _entries.markNaga(c, _dateKey, _shift, null);
    }
    await _load();
  }

  Future<void> _pickReason(Customer c) async {
    final s = context.read<SettingsController>().strings;
    final reason = await showNagaReasonSheet(context, s);
    if (reason == null) return;
    await _entries.markNaga(c, _dateKey, _shift, reason);
    await _load();
  }

  Future<void> _extra(Customer c) async {
    final s = context.read<SettingsController>().strings;
    final extra = await showExtraSheet(context, s, c);
    if (extra == null) return;
    final total = c.qtyForShift(_shift) + extra;
    await _entries.markExtra(c, _dateKey, _shift, total);
    await _load();
  }

  Future<void> _clearExtra(Customer c) async {
    await _entries.deleteEntry(c.id!, _dateKey, _shift);
    await _load();
  }

  Future<void> _khula() async {
    final s = context.read<SettingsController>().strings;
    final res = await showKhulaSheet(context, s, _all);
    if (res == null) return;
    // Rate: the tied customer's rate, else the default kg rate.
    MilkUnit unit = MilkUnit.kg;
    double rate;
    if (res.customerId != null) {
      final c = _all.firstWhere((x) => x.id == res.customerId);
      unit = c.unit;
      rate = await _rates.priceOn(c.id!, c.unit, _dateKey);
    } else {
      rate = await _rates.defaultPrice(MilkUnit.kg, _dateKey);
    }
    await _entries.addLooseSale(
      dateKey: _dateKey,
      shift: _shift,
      amountRs: res.amount,
      unit: unit,
      rateUsed: rate,
      customerId: res.customerId,
    );
    await _load();
  }

  Future<void> _quickActions(Customer c) async {
    final s = context.read<SettingsController>().strings;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(children: [
                Text(c.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(s.addPayment),
              onTap: () => Navigator.pop(context, 'pay'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(s.khata),
              onTap: () => Navigator.pop(context, 'khata'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'pay') {
      await _takePayment(c);
    } else if (choice == 'khata') {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customerId: c.id!),
      ));
      _load();
    }
  }

  Future<void> _takePayment(Customer c) async {
    final s = context.read<SettingsController>().strings;
    final res = await showPaymentSheet(context, s, c);
    if (res == null) return;
    await _payments.add(Payment(
      customerId: c.id!,
      date: _dateKey,
      amount: res.amount,
      method: res.method,
      createdAt: DateTime.now().toIso8601String(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${s.payment}: ${c.name}')),
    );
  }

  Future<void> _closeRound() async {
    final s = context.read<SettingsController>().strings;
    final filled = await _entries.closeRound(_onShift, _dateKey, _shift);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.roundClosed(filled))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final s = settings.strings;
    final onShift = _onShift;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.todayTitle),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                DateUtil.dayMonth(_date),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _khula,
        backgroundColor: AppTheme.seed,
        icon: const Icon(Icons.local_drink_outlined),
        label: Text(s.khula),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (settings.twoRounds) _shiftToggle(s),
                Expanded(
                  child: onShift.isEmpty
                      ? _emptyState(s)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                          itemCount: onShift.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final c = onShift[i];
                            return CustomerCard(
                              customer: c,
                              shift: _shift,
                              entry: _entryByCustomer[c.id],
                              s: s,
                              onToggleNaga: () => _toggleNaga(c),
                              onPickReason: () => _pickReason(c),
                              onExtra: () => _extra(c),
                              onClearExtra: () => _clearExtra(c),
                              onTapBody: () => _quickActions(c),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomSheet: _loading ? null : _footer(s),
    );
  }

  Widget _shiftToggle(Strings s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: SegmentedButton<Shift>(
        segments: [
          ButtonSegment(
              value: Shift.morning,
              label: Text(s.subah),
              icon: const Icon(Icons.wb_sunny_outlined)),
          ButtonSegment(
              value: Shift.evening,
              label: Text(s.shaam),
              icon: const Icon(Icons.nights_stay_outlined)),
        ],
        selected: {_shift},
        onSelectionChanged: (set) {
          setState(() => _shift = set.first);
          _load();
        },
      ),
    );
  }

  Widget _footer(Strings s) {
    final totals = footerTotals(_expectedByUnit(), _looseTotal, s);
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.todaysTotal,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.6))),
                    const SizedBox(height: 2),
                    Text(totals,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _closeRound,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(s.roundKhatam),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(Strings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          s.noCustomers,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}
