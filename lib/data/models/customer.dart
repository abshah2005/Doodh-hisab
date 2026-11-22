import '../enums.dart';

/// A regular customer on the route.
///
/// The fixed daily order lives here as [morningQty] / [eveningQty] for the
/// common case (one order that rarely changes). Historical changes to the
/// order are kept in the `fixed_order` table; this pair holds the *current*
/// default so the Today screen can pre-fill without a join.
class Customer {
  final int? id;
  final String name;
  final String? phone;
  final CustomerType type;
  final String? addressNote;

  /// Position in the delivery round; lower comes first.
  final int routeOrder;

  final MilkUnit unit;

  /// Current fixed order per shift, in [unit]. 0 means "not on this shift".
  final double morningQty;
  final double eveningQty;

  /// Customer-specific rate. If null, the global default rate applies.
  final double? rate;

  /// Opening balance carried in when the customer was added (what they already
  /// owed). Positive = customer owes the doodh wala.
  final double openingBalance;

  final bool active;
  final String createdAt;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.type = CustomerType.house,
    this.addressNote,
    this.routeOrder = 0,
    this.unit = MilkUnit.kg,
    this.morningQty = 0,
    this.eveningQty = 0,
    this.rate,
    this.openingBalance = 0,
    this.active = true,
    required this.createdAt,
  });

  double qtyForShift(Shift shift) =>
      shift == Shift.morning ? morningQty : eveningQty;

  bool get hasEvening => eveningQty > 0;

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    CustomerType? type,
    String? addressNote,
    int? routeOrder,
    MilkUnit? unit,
    double? morningQty,
    double? eveningQty,
    double? rate,
    double? openingBalance,
    bool? active,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      addressNote: addressNote ?? this.addressNote,
      routeOrder: routeOrder ?? this.routeOrder,
      unit: unit ?? this.unit,
      morningQty: morningQty ?? this.morningQty,
      eveningQty: eveningQty ?? this.eveningQty,
      rate: rate ?? this.rate,
      openingBalance: openingBalance ?? this.openingBalance,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'type': type.code,
        'address_note': addressNote,
        'route_order': routeOrder,
        'unit': unit.code,
        'morning_qty': morningQty,
        'evening_qty': eveningQty,
        'rate': rate,
        'opening_balance': openingBalance,
        'active': active ? 1 : 0,
        'created_at': createdAt,
      };

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        type: CustomerType.fromCode(m['type'] as String? ?? 'house'),
        addressNote: m['address_note'] as String?,
        routeOrder: (m['route_order'] as int?) ?? 0,
        unit: MilkUnit.fromCode(m['unit'] as String? ?? 'kg'),
        morningQty: (m['morning_qty'] as num?)?.toDouble() ?? 0,
        eveningQty: (m['evening_qty'] as num?)?.toDouble() ?? 0,
        rate: (m['rate'] as num?)?.toDouble(),
        openingBalance: (m['opening_balance'] as num?)?.toDouble() ?? 0,
        active: ((m['active'] as int?) ?? 1) == 1,
        createdAt: m['created_at'] as String,
      );
}
