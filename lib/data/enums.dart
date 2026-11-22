// Shared enums for the Doodh Hisaab data model.
//
// Each enum stores a stable string `code` in SQLite so the on-disk values
// never depend on Dart's enum ordering.

enum CustomerType {
  house('house'),
  shop('shop');

  const CustomerType(this.code);
  final String code;

  static CustomerType fromCode(String code) =>
      values.firstWhere((e) => e.code == code, orElse: () => CustomerType.house);
}

enum MilkUnit {
  litre('L'),
  kg('kg');

  const MilkUnit(this.code);
  final String code;

  static MilkUnit fromCode(String code) =>
      values.firstWhere((e) => e.code == code, orElse: () => MilkUnit.kg);
}

enum Shift {
  morning('morning'),
  evening('evening');

  const Shift(this.code);
  final String code;

  static Shift fromCode(String code) =>
      values.firstWhere((e) => e.code == code, orElse: () => Shift.morning);
}

/// Status of a single customer, single shift, single day.
enum EntryStatus {
  /// The fixed order (or an explicit quantity) was supplied.
  delivered('delivered'),

  /// No milk was given to this customer this shift. Charged zero.
  naga('naga'),

  /// Customer took more than the fixed order. `quantity` holds the EXTRA
  /// amount on top of the fixed order.
  extra('extra');

  const EntryStatus(this.code);
  final String code;

  static EntryStatus fromCode(String code) => values
      .firstWhere((e) => e.code == code, orElse: () => EntryStatus.delivered);
}

enum NagaReason {
  customerRefused('customer_refused'),
  supplierMissed('supplier_missed'),
  other('other');

  const NagaReason(this.code);
  final String code;

  static NagaReason? fromCode(String? code) {
    if (code == null) return null;
    for (final r in values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

enum PaymentMethod {
  cash('cash'),
  jazzcash('jazzcash'),
  easypaisa('easypaisa'),
  bank('bank');

  const PaymentMethod(this.code);
  final String code;

  static PaymentMethod fromCode(String code) =>
      values.firstWhere((e) => e.code == code, orElse: () => PaymentMethod.cash);
}
