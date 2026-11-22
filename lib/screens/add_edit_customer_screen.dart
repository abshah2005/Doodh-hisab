import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/enums.dart';
import '../data/models/customer.dart';
import '../data/repositories/customer_repository.dart';
import '../state/settings_controller.dart';
import '../util/date_util.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? existing;
  const AddEditCustomerScreen({super.key, this.existing});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _repo = CustomerRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _route;
  late final TextEditingController _morning;
  late final TextEditingController _evening;
  late final TextEditingController _rate;
  late final TextEditingController _opening;

  CustomerType _type = CustomerType.house;
  MilkUnit _unit = MilkUnit.kg;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _address = TextEditingController(text: c?.addressNote ?? '');
    _route = TextEditingController(text: (c?.routeOrder ?? '').toString());
    _morning = TextEditingController(
        text: c != null && c.morningQty > 0 ? _trim(c.morningQty) : '');
    _evening = TextEditingController(
        text: c != null && c.eveningQty > 0 ? _trim(c.eveningQty) : '');
    _rate =
        TextEditingController(text: c?.rate != null ? _trim(c!.rate!) : '');
    _opening = TextEditingController(
        text: c != null && c.openingBalance != 0
            ? _trim(c.openingBalance)
            : '');
    _type = c?.type ?? CustomerType.house;
    _unit = c?.unit ?? MilkUnit.kg;
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _address,
      _route,
      _morning,
      _evening,
      _rate,
      _opening
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final todayKey = DateUtil.toKey(DateUtil.today());

    final base = widget.existing;
    final customer = Customer(
      id: base?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      type: _type,
      addressNote:
          _address.text.trim().isEmpty ? null : _address.text.trim(),
      routeOrder: int.tryParse(_route.text.trim()) ?? 0,
      unit: _unit,
      morningQty: double.tryParse(_morning.text.trim()) ?? 0,
      eveningQty: double.tryParse(_evening.text.trim()) ?? 0,
      rate: _rate.text.trim().isEmpty
          ? null
          : double.tryParse(_rate.text.trim()),
      openingBalance: double.tryParse(_opening.text.trim()) ?? 0,
      active: base?.active ?? true,
      createdAt: base?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (_isEdit) {
      await _repo.update(customer, todayKey);
    } else {
      await _repo.insert(customer, todayKey);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>().strings;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? s.edit : s.addCustomer)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: s.name),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.requiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: s.phone),
            ),
            const SizedBox(height: 12),
            SegmentedButton<CustomerType>(
              segments: [
                ButtonSegment(
                    value: CustomerType.house,
                    label: Text(s.typeHouse),
                    icon: const Icon(Icons.home_outlined)),
                ButtonSegment(
                    value: CustomerType.shop,
                    label: Text(s.typeShop),
                    icon: const Icon(Icons.store_outlined)),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: InputDecoration(labelText: s.addressNote),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _route,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: s.routePosition),
            ),
            const SizedBox(height: 20),
            Text(s.unit,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<MilkUnit>(
              segments: [
                ButtonSegment(value: MilkUnit.kg, label: Text(s.unitKg)),
                ButtonSegment(value: MilkUnit.litre, label: Text(s.unitL)),
              ],
              selected: {_unit},
              onSelectionChanged: (set) => setState(() => _unit = set.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _morning,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    decoration: InputDecoration(
                      labelText: s.morningQty,
                      suffixText: _unit.code,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _evening,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                    ],
                    decoration: InputDecoration(
                      labelText: s.eveningQty,
                      suffixText: _unit.code,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rate,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: s.rate,
                prefixText: 'Rs ',
                suffixText: '/${_unit.code}',
                helperText: s.rateHint,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _opening,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: s.openingBalance,
                prefixText: 'Rs ',
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Material(
        elevation: 8,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.save),
            ),
          ),
        ),
      ),
    );
  }
}
