import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/enums.dart';
import '../data/models/customer.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import '../util/format.dart';

/// Result of the khula (loose sale) sheet.
class KhulaResult {
  final double amount;
  final int? customerId;
  const KhulaResult(this.amount, this.customerId);
}

/// Result of the payment sheet.
class PaymentResult {
  final double amount;
  final PaymentMethod method;
  const PaymentResult(this.amount, this.method);
}

/// Pick a naga reason. Returns the chosen [NagaReason], or null if dismissed.
Future<NagaReason?> showNagaReasonSheet(
    BuildContext context, Strings s) async {
  return showModalBottomSheet<NagaReason>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      Widget tile(String label, NagaReason r, IconData icon) => ListTile(
            leading: Icon(icon),
            title: Text(label, style: const TextStyle(fontSize: 16)),
            onTap: () => Navigator.pop(context, r),
          );
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Text(s.nagaReasonTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            tile(s.reasonCustomer, NagaReason.customerRefused,
                Icons.person_off_outlined),
            tile(s.reasonSupplier, NagaReason.supplierMissed,
                Icons.pedal_bike_outlined),
            tile(s.reasonOther, NagaReason.other, Icons.more_horiz),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Enter the EXTRA quantity on top of the fixed order. Returns the extra
/// amount, or null if cancelled.
Future<double?> showExtraSheet(
  BuildContext context,
  Strings s,
  Customer c,
) async {
  final controller = TextEditingController();
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.extraTitle} — ${c.name}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(s.extraHint,
                style: TextStyle(color: Colors.black.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                suffixText: c.unit.code,
                hintText: '0.5',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(controller.text.trim());
                if (v != null && v > 0) Navigator.pop(context, v);
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.extra),
              child: Text(s.done),
            ),
          ],
        ),
      );
    },
  );
}

/// Khula (loose) sale sheet. [customers] lets the sale optionally be tied to a
/// known customer. Returns [KhulaResult], or null if cancelled.
Future<KhulaResult?> showKhulaSheet(
  BuildContext context,
  Strings s,
  List<Customer> customers,
) async {
  final controller = TextEditingController();
  int? customerId;
  return showModalBottomSheet<KhulaResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(builder: (context, setSheet) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 4,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.looseSale,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixText: 'Rs ',
                  hintText: '200',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: customerId,
                isExpanded: true,
                decoration: InputDecoration(labelText: s.optionalCustomer),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(s.walkIn),
                  ),
                  ...customers.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      )),
                ],
                onChanged: (v) => setSheet(() => customerId = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final v = double.tryParse(controller.text.trim());
                  if (v != null && v > 0) {
                    Navigator.pop(context, KhulaResult(v, customerId));
                  }
                },
                style:
                    FilledButton.styleFrom(backgroundColor: AppTheme.seed),
                child: Text(s.done),
              ),
            ],
          ),
        );
      });
    },
  );
}

/// Payment sheet. Returns [PaymentResult], or null if cancelled.
Future<PaymentResult?> showPaymentSheet(
  BuildContext context,
  Strings s,
  Customer c,
) async {
  final controller = TextEditingController();
  PaymentMethod method = PaymentMethod.cash;
  return showModalBottomSheet<PaymentResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(builder: (context, setSheet) {
        Widget methodChip(String label, PaymentMethod m) => ChoiceChip(
              label: Text(label),
              selected: method == m,
              onSelected: (_) => setSheet(() => method = m),
            );
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 4,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.paymentTitle} — ${c.name}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixText: 'Rs ',
                  hintText: '1000',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  methodChip(s.methodCash, PaymentMethod.cash),
                  methodChip(s.methodJazzCash, PaymentMethod.jazzcash),
                  methodChip(s.methodEasypaisa, PaymentMethod.easypaisa),
                  methodChip(s.methodBank, PaymentMethod.bank),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final v = double.tryParse(controller.text.trim());
                  if (v != null && v > 0) {
                    Navigator.pop(context, PaymentResult(v, method));
                  }
                },
                child: Text(s.done),
              ),
            ],
          ),
        );
      });
    },
  );
}

/// A small confirming chip shown in the footer / headers.
String footerTotals(
  Map<MilkUnit, double> byUnit,
  double looseRs,
  Strings s,
) {
  final parts = <String>[];
  byUnit.forEach((unit, qty) {
    if (qty > 0) parts.add(Fmt.qtyUnit(qty, unit));
  });
  if (looseRs > 0) parts.add('${Fmt.rs(looseRs)} ${s.looseLabel}');
  return parts.isEmpty ? '—' : parts.join('  ·  ');
}
