import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/billing_repository.dart';
import '../l10n/strings.dart';
import '../state/settings_controller.dart';
import '../theme.dart';
import '../util/format.dart';
import 'add_edit_customer_screen.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _billing = BillingRepository();
  List<CustomerBalance> _all = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final balances = await _billing.allBalances();
    if (!mounted) return;
    setState(() {
      _all = balances;
      _loading = false;
    });
  }

  List<CustomerBalance> get _filtered {
    if (_query.trim().isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all
        .where((b) =>
            b.customer.name.toLowerCase().contains(q) ||
            (b.customer.phone ?? '').contains(q))
        .toList();
  }

  Future<void> _openAdd() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
    );
    if (changed == true) _load();
  }

  Future<void> _openDetail(int id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: id)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>().strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.customersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.person_add_alt),
        label: Text(s.addCustomer),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: s.searchHint,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(s.noCustomers,
                              style: TextStyle(
                                  color:
                                      Colors.black.withValues(alpha: 0.6))))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) =>
                              _tile(_filtered[i], s),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _tile(CustomerBalance b, Strings s) {
    final owes = b.balance > 0.5;
    final credit = b.balance < -0.5;
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.seed.withValues(alpha: 0.12),
          child: Text(
            b.customer.name.isNotEmpty
                ? b.customer.name.characters.first
                : '?',
            style: const TextStyle(
                color: AppTheme.seed, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(b.customer.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(_orderLine(b)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Fmt.rs(b.balance.abs()),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: owes
                    ? AppTheme.owe
                    : (credit ? AppTheme.delivered : Colors.black54),
              ),
            ),
            Text(
              owes
                  ? s.balance
                  : (credit ? 'Advance' : '—'),
              style: TextStyle(
                  fontSize: 11, color: Colors.black.withValues(alpha: 0.55)),
            ),
          ],
        ),
        onTap: () => _openDetail(b.customer.id!),
      ),
    );
  }

  String _orderLine(CustomerBalance b) {
    final c = b.customer;
    final parts = <String>[];
    if (c.morningQty > 0) {
      parts.add('${Fmt.qtyUnit(c.morningQty, c.unit)} subah');
    }
    if (c.eveningQty > 0) {
      parts.add('${Fmt.qtyUnit(c.eveningQty, c.unit)} shaam');
    }
    return parts.join(', ');
  }
}
