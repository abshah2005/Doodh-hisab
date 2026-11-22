import '../enums.dart';

/// A loose / khula sale: "Rs 100 ka de do".
///
/// The rupee amount is the source of truth. The quantity is derived from the
/// rate only so the doodh wala's stock totals add up.
class LooseSale {
  final int? id;
  final String date;
  final Shift shift;
  final double amountRs;
  final double rateUsed;
  final double quantityCalc;
  final MilkUnit unit;

  /// Optional: a loose sale can be tied to a known customer, or be a walk-in.
  final int? customerId;
  final String? note;
  final String createdAt;

  const LooseSale({
    this.id,
    required this.date,
    required this.shift,
    required this.amountRs,
    required this.rateUsed,
    required this.quantityCalc,
    this.unit = MilkUnit.kg,
    this.customerId,
    this.note,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date,
        'shift': shift.code,
        'amount_rs': amountRs,
        'rate_used': rateUsed,
        'quantity_calc': quantityCalc,
        'unit': unit.code,
        'customer_id': customerId,
        'note': note,
        'created_at': createdAt,
      };

  factory LooseSale.fromMap(Map<String, Object?> m) => LooseSale(
        id: m['id'] as int?,
        date: m['date'] as String,
        shift: Shift.fromCode(m['shift'] as String),
        amountRs: (m['amount_rs'] as num?)?.toDouble() ?? 0,
        rateUsed: (m['rate_used'] as num?)?.toDouble() ?? 0,
        quantityCalc: (m['quantity_calc'] as num?)?.toDouble() ?? 0,
        unit: MilkUnit.fromCode(m['unit'] as String? ?? 'kg'),
        customerId: m['customer_id'] as int?,
        note: m['note'] as String?,
        createdAt: m['created_at'] as String,
      );
}
