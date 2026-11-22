import 'package:doodh_hisaab/data/enums.dart';
import 'package:doodh_hisaab/data/models/customer.dart';
import 'package:doodh_hisaab/data/models/daily_entry.dart';
import 'package:doodh_hisaab/data/models/payment.dart';
import 'package:doodh_hisaab/services/bill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Reproduces the worked example from the case study (section 8):
  // Rashid sahab, 2 kg every morning at Rs 220/kg, 30-day month, 3 nagas
  // (2 customer away, 1 supplier missed), 1 kg extra once, previous balance
  // Rs 500, paid Rs 10,000 -> balance due Rs 2,600.
  test('Rashid sahab monthly bill matches the case study', () {
    final customer = Customer(
      id: 1,
      name: 'Rashid Sahab',
      unit: MilkUnit.kg,
      morningQty: 2,
      rate: 220,
      openingBalance: 500,
      createdAt: '2026-11-01T00:00:00',
    );

    const rate = 220.0;
    final entries = <DailyEntry>[];

    DailyEntry mk(int day, EntryStatus status,
        {double qty = 2, NagaReason? reason}) {
      final date = '2026-11-${day.toString().padLeft(2, '0')}';
      return DailyEntry(
        customerId: 1,
        date: date,
        shift: Shift.morning,
        status: status,
        quantity: status == EntryStatus.naga ? 0 : qty,
        rate: rate,
        unit: MilkUnit.kg,
        nagaReason: reason,
        createdAt: '$date' 'T06:00:00',
      );
    }

    // 30 days. Days 6, 7 customer away; day 19 supplier missed. Day 10 extra
    // (+1 kg -> total 3 kg). Everything else delivered 2 kg.
    for (int day = 1; day <= 30; day++) {
      if (day == 6 || day == 7) {
        entries.add(mk(day, EntryStatus.naga,
            reason: NagaReason.customerRefused));
      } else if (day == 19) {
        entries.add(
            mk(day, EntryStatus.naga, reason: NagaReason.supplierMissed));
      } else if (day == 10) {
        entries.add(mk(day, EntryStatus.extra, qty: 3));
      } else {
        entries.add(mk(day, EntryStatus.delivered));
      }
    }

    final payments = [
      Payment(
        customerId: 1,
        date: '2026-11-20',
        amount: 10000,
        createdAt: '2026-11-20T12:00:00',
      ),
    ];

    final bill = BillCalculator.compute(
      customer: customer,
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 30),
      entries: entries,
      payments: payments,
      previousBalance: 500,
    );

    expect(bill.daysSupplied, 27); // 30 - 3 nagas
    expect(bill.totalQty, 55); // 26*2 + 3
    expect(bill.extraQty, 1);
    expect(bill.milkCharges, 55 * 220); // 12,100
    expect(bill.paidInPeriod, 10000);
    expect(bill.balanceDue, 2600); // 500 + 12,100 - 10,000
    expect(bill.nagaCount, 3);
    expect(bill.nagaCustomerAway, 2);
    expect(bill.nagaSupplierMissed, 1);
  });

  test('naga is charged zero and only affects that customer', () {
    final customer = Customer(
      id: 2,
      name: 'Test',
      unit: MilkUnit.kg,
      morningQty: 1,
      rate: 100,
      createdAt: '2026-11-01T00:00:00',
    );

    final entries = [
      DailyEntry(
        customerId: 2,
        date: '2026-11-01',
        shift: Shift.morning,
        status: EntryStatus.naga,
        quantity: 0,
        rate: 100,
        unit: MilkUnit.kg,
        createdAt: '2026-11-01T06:00:00',
      ),
      DailyEntry(
        customerId: 2,
        date: '2026-11-02',
        shift: Shift.morning,
        status: EntryStatus.delivered,
        quantity: 1,
        rate: 100,
        unit: MilkUnit.kg,
        createdAt: '2026-11-02T06:00:00',
      ),
    ];

    final bill = BillCalculator.compute(
      customer: customer,
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 30),
      entries: entries,
      payments: const [],
      previousBalance: 0,
    );

    expect(bill.milkCharges, 100); // only the one delivered day
    expect(bill.nagaCount, 1);
    expect(bill.balanceDue, 100);
  });

  test('mid-month rate change shows two rate slices', () {
    final customer = Customer(
      id: 3,
      name: 'Rate Change',
      unit: MilkUnit.kg,
      morningQty: 1,
      createdAt: '2026-11-01T00:00:00',
    );

    final entries = [
      DailyEntry(
        customerId: 3,
        date: '2026-11-10',
        shift: Shift.morning,
        status: EntryStatus.delivered,
        quantity: 1,
        rate: 210,
        unit: MilkUnit.kg,
        createdAt: '2026-11-10T06:00:00',
      ),
      DailyEntry(
        customerId: 3,
        date: '2026-11-20',
        shift: Shift.morning,
        status: EntryStatus.delivered,
        quantity: 1,
        rate: 220,
        unit: MilkUnit.kg,
        createdAt: '2026-11-20T06:00:00',
      ),
    ];

    final bill = BillCalculator.compute(
      customer: customer,
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 30),
      entries: entries,
      payments: const [],
      previousBalance: 0,
    );

    expect(bill.rates.length, 2);
    expect(bill.milkCharges, 430); // 210 + 220
  });
}
