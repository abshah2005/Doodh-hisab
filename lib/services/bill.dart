import '../data/enums.dart';
import '../data/models/customer.dart';
import '../data/models/daily_entry.dart';
import '../data/models/payment.dart';
import '../util/date_util.dart';

/// One rate that applied during the billing period and the date it started.
class RateSlice {
  final double price;
  final String fromKey;
  const RateSlice(this.price, this.fromKey);
}

/// A naga, grouped for the bill ("6th, 7th customer away; 19th supplier
/// missed").
class NagaDay {
  final DateTime date;
  final Shift shift;
  final NagaReason? reason;
  const NagaDay(this.date, this.shift, this.reason);
}

/// The fully computed bill for one customer over a date range.
class BillResult {
  final Customer customer;
  final DateTime from;
  final DateTime to;

  final int daysSupplied;
  final double totalQty;
  final double extraQty;
  final MilkUnit unit;

  final double milkCharges;
  final double previousBalance;
  final double paidInPeriod;
  final double balanceDue;

  final List<NagaDay> nagaDays;
  final List<RateSlice> rates;
  final List<Payment> payments;

  const BillResult({
    required this.customer,
    required this.from,
    required this.to,
    required this.daysSupplied,
    required this.totalQty,
    required this.extraQty,
    required this.unit,
    required this.milkCharges,
    required this.previousBalance,
    required this.paidInPeriod,
    required this.balanceDue,
    required this.nagaDays,
    required this.rates,
    required this.payments,
  });

  int get nagaCount => nagaDays.length;

  int get nagaCustomerAway =>
      nagaDays.where((n) => n.reason == NagaReason.customerRefused).length;

  int get nagaSupplierMissed =>
      nagaDays.where((n) => n.reason == NagaReason.supplierMissed).length;
}

/// Pure functions that turn stored rows into a [BillResult]. Kept free of any
/// database or UI code so the billing rules are easy to read and to test.
class BillCalculator {
  /// [entries] and [payments] must already be scoped to [customer] and the
  /// [from]..[to] range. [previousBalance] is the balance carried in at the
  /// start of the range (opening balance + prior milk − prior payments).
  static BillResult compute({
    required Customer customer,
    required DateTime from,
    required DateTime to,
    required List<DailyEntry> entries,
    required List<Payment> payments,
    required double previousBalance,
  }) {
    double totalQty = 0;
    double extraQty = 0;
    double milkCharges = 0;
    final suppliedDates = <String>{};
    final nagaDays = <NagaDay>[];
    final rateByFrom = <double, String>{};

    for (final e in entries) {
      if (e.status == EntryStatus.naga) {
        nagaDays.add(NagaDay(
          DateUtil.fromKey(e.date),
          e.shift,
          e.nagaReason,
        ));
        continue;
      }

      // delivered or extra
      totalQty += e.quantity;
      milkCharges += e.amount;
      suppliedDates.add(e.date);

      if (e.status == EntryStatus.extra) {
        final fixed = customer.qtyForShift(e.shift);
        final extra = e.quantity - fixed;
        if (extra > 0) extraQty += extra;
      }

      // Track the earliest date each distinct rate appeared.
      final existing = rateByFrom[e.rate];
      if (existing == null || e.date.compareTo(existing) < 0) {
        rateByFrom[e.rate] = e.date;
      }
    }

    final paidInPeriod =
        payments.fold<double>(0, (sum, p) => sum + p.amount);
    final balanceDue = previousBalance + milkCharges - paidInPeriod;

    final rates = rateByFrom.entries
        .map((e) => RateSlice(e.key, e.value))
        .toList()
      ..sort((a, b) => a.fromKey.compareTo(b.fromKey));

    nagaDays.sort((a, b) => a.date.compareTo(b.date));

    return BillResult(
      customer: customer,
      from: from,
      to: to,
      daysSupplied: suppliedDates.length,
      totalQty: totalQty,
      extraQty: extraQty,
      unit: customer.unit,
      milkCharges: milkCharges,
      previousBalance: previousBalance,
      paidInPeriod: paidInPeriod,
      balanceDue: balanceDue,
      nagaDays: nagaDays,
      rates: rates,
      payments: payments,
    );
  }
}
