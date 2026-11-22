import '../enums.dart';

/// A price that takes effect from a date.
///
/// A row with [customerId] == null is a default rate for everyone on that
/// unit. A row with a customer id overrides the default for that customer.
/// The rate "on a date" is the most recent row with `effective_from <= date`,
/// customer-specific winning over default. This is what lets a November bill
/// charge Rs 210/kg till the 14th and Rs 220/kg from the 15th.
class Rate {
  final int? id;
  final int? customerId;
  final MilkUnit unit;
  final double price;

  /// `yyyy-MM-dd`.
  final String effectiveFrom;

  const Rate({
    this.id,
    this.customerId,
    required this.unit,
    required this.price,
    required this.effectiveFrom,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'customer_id': customerId,
        'unit': unit.code,
        'price': price,
        'effective_from': effectiveFrom,
      };

  factory Rate.fromMap(Map<String, Object?> m) => Rate(
        id: m['id'] as int?,
        customerId: m['customer_id'] as int?,
        unit: MilkUnit.fromCode(m['unit'] as String? ?? 'kg'),
        price: (m['price'] as num?)?.toDouble() ?? 0,
        effectiveFrom: m['effective_from'] as String,
      );
}
