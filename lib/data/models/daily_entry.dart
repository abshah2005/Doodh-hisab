import '../enums.dart';

/// One customer, one shift, one day.
///
/// Per the case study we store a row for every customer on every closed shift
/// (treating "no row" as not-yet-recorded, and an explicit `delivered` row as
/// the confirmed normal supply). This makes a bill a simple sum over rows even
/// when orders and rates change mid-month.
///
/// Meaning of [quantity] by [status]:
///   delivered -> the quantity supplied (normally the fixed order)
///   naga      -> 0 (no charge)
///   extra     -> fixed order + the extra; i.e. the TOTAL quantity for the
///                shift. Stored as the full amount so billing never has to
///                re-derive the fixed order for a past day.
class DailyEntry {
  final int? id;
  final int customerId;

  /// `yyyy-MM-dd`.
  final String date;
  final Shift shift;
  final EntryStatus status;
  final double quantity;

  /// Rate applied for this entry (snapshotted so historical bills stay stable).
  final double rate;
  final MilkUnit unit;

  final NagaReason? nagaReason;
  final String? note;
  final bool edited;
  final String createdAt;

  const DailyEntry({
    this.id,
    required this.customerId,
    required this.date,
    required this.shift,
    required this.status,
    required this.quantity,
    required this.rate,
    required this.unit,
    this.nagaReason,
    this.note,
    this.edited = false,
    required this.createdAt,
  });

  double get amount => status == EntryStatus.naga ? 0 : quantity * rate;

  bool get isNaga => status == EntryStatus.naga;

  DailyEntry copyWith({
    int? id,
    EntryStatus? status,
    double? quantity,
    double? rate,
    NagaReason? nagaReason,
    String? note,
    bool? edited,
  }) {
    return DailyEntry(
      id: id ?? this.id,
      customerId: customerId,
      date: date,
      shift: shift,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      unit: unit,
      nagaReason: nagaReason ?? this.nagaReason,
      note: note ?? this.note,
      edited: edited ?? this.edited,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'customer_id': customerId,
        'date': date,
        'shift': shift.code,
        'status': status.code,
        'quantity': quantity,
        'rate': rate,
        'unit': unit.code,
        'naga_reason': nagaReason?.code,
        'note': note,
        'edited': edited ? 1 : 0,
        'created_at': createdAt,
      };

  factory DailyEntry.fromMap(Map<String, Object?> m) => DailyEntry(
        id: m['id'] as int?,
        customerId: m['customer_id'] as int,
        date: m['date'] as String,
        shift: Shift.fromCode(m['shift'] as String),
        status: EntryStatus.fromCode(m['status'] as String),
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        rate: (m['rate'] as num?)?.toDouble() ?? 0,
        unit: MilkUnit.fromCode(m['unit'] as String? ?? 'kg'),
        nagaReason: NagaReason.fromCode(m['naga_reason'] as String?),
        note: m['note'] as String?,
        edited: ((m['edited'] as int?) ?? 0) == 1,
        createdAt: m['created_at'] as String,
      );
}
