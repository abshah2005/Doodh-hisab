import 'package:flutter/material.dart';

import '../data/enums.dart';
import '../data/models/customer.dart';
import '../data/models/daily_entry.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import '../util/format.dart';

/// A single customer's card on the Today route. Default state shows the fixed
/// order with Naga / + Extra buttons. A naga greys the card; an extra tints it.
class CustomerCard extends StatelessWidget {
  final Customer customer;
  final Shift shift;
  final DailyEntry? entry;
  final Strings s;

  final VoidCallback onToggleNaga;
  final VoidCallback onPickReason;
  final VoidCallback onExtra;
  final VoidCallback onClearExtra;
  final VoidCallback onTapBody; // payment / khata quick actions

  const CustomerCard({
    super.key,
    required this.customer,
    required this.shift,
    required this.entry,
    required this.s,
    required this.onToggleNaga,
    required this.onPickReason,
    required this.onExtra,
    required this.onClearExtra,
    required this.onTapBody,
  });

  @override
  Widget build(BuildContext context) {
    final isNaga = entry?.status == EntryStatus.naga;
    final isExtra = entry?.status == EntryStatus.extra;
    final isDelivered = entry?.status == EntryStatus.delivered;
    final fixedQty = customer.qtyForShift(shift);

    Color bg = Colors.white;
    if (isNaga) bg = const Color(0xFFF2E6E6);
    if (isExtra) bg = const Color(0xFFE7EEFC);
    if (isDelivered) bg = const Color(0xFFE8F1EE);

    return Card(
      color: bg,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTapBody,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _routeBadge(customer.routeOrder),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            decoration:
                                isNaga ? TextDecoration.lineThrough : null,
                            color: isNaga
                                ? Colors.black.withValues(alpha: 0.55)
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _subtitle(isNaga, isExtra, isDelivered, fixedQty),
                      ],
                    ),
                  ),
                  _trailing(context, isNaga, isExtra, isDelivered),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subtitle(
      bool isNaga, bool isExtra, bool isDelivered, double fixedQty) {
    if (isNaga) {
      final reason = entry?.nagaReason;
      final text = reason == null
          ? null
          : switch (reason) {
              NagaReason.customerRefused => s.reasonCustomer,
              NagaReason.supplierMissed => s.reasonSupplier,
              NagaReason.other => s.reasonOther,
            };
      return Row(
        children: [
          Text('NAGA',
              style: TextStyle(
                  color: AppTheme.naga, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          if (text != null)
            Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.6))),
            )
          else
            GestureDetector(
              onTap: onPickReason,
              child: Text('wajah?',
                  style: TextStyle(
                      color: AppTheme.extra,
                      decoration: TextDecoration.underline)),
            ),
        ],
      );
    }

    final qty = entry?.quantity ?? fixedQty;
    final label = Fmt.qtyUnit(qty, customer.unit);
    if (isExtra) {
      final extra = (entry!.quantity - fixedQty).clamp(0, double.infinity);
      return Text('$label  (+${Fmt.qty(extra)} ${customer.unit.code})',
          style: TextStyle(
              color: AppTheme.extra, fontWeight: FontWeight.w600));
    }
    return Text(label,
        style: TextStyle(color: Colors.black.withValues(alpha: 0.7)));
  }

  Widget _trailing(
      BuildContext context, bool isNaga, bool isExtra, bool isDelivered) {
    if (isNaga) {
      return TextButton.icon(
        onPressed: onToggleNaga,
        icon: const Icon(Icons.undo, size: 18),
        label: Text(s.undo),
        style: TextButton.styleFrom(foregroundColor: AppTheme.naga),
      );
    }
    if (isExtra) {
      return IconButton(
        onPressed: onClearExtra,
        icon: const Icon(Icons.close),
        tooltip: s.undo,
      );
    }
    // default or delivered -> show action buttons
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _smallBtn(
          label: s.naga,
          color: AppTheme.naga,
          onTap: onToggleNaga,
        ),
        const SizedBox(width: 6),
        _smallBtn(
          label: s.extra,
          color: AppTheme.extra,
          onTap: onExtra,
        ),
      ],
    );
  }

  Widget _smallBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _routeBadge(int order) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.seed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$order',
          style: TextStyle(
              color: AppTheme.seed, fontWeight: FontWeight.w700)),
    );
  }
}
