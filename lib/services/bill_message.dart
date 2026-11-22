import '../data/enums.dart';
import '../util/date_util.dart';
import '../util/format.dart';
import 'bill.dart';

/// Builds the short Roman Urdu WhatsApp summary of a bill, so there is nothing
/// left to argue about: amount, naga dates and balance due.
class BillMessage {
  static String build(BillResult b, {String? businessName}) {
    final sb = StringBuffer();
    final monthLabel = DateUtil.monthYear(b.from);

    sb.writeln('*${b.customer.name}* ka hisaab — $monthLabel');
    sb.writeln('—' * 16);
    sb.writeln('Din diye: ${b.daysSupplied}');
    sb.writeln('Total doodh: ${Fmt.qtyUnit(b.totalQty, b.unit)}');
    if (b.extraQty > 0) {
      sb.writeln('(ismein extra: ${Fmt.qtyUnit(b.extraQty, b.unit)})');
    }

    if (b.rates.length > 1) {
      final parts = b.rates.map((r) {
        final d = DateUtil.dayMonth(DateUtil.fromKey(r.fromKey));
        return '${Fmt.rs(r.price)}/${b.unit.code} ($d se)';
      }).join(', ');
      sb.writeln('Rate: $parts');
    } else if (b.rates.isNotEmpty) {
      sb.writeln('Rate: ${Fmt.rs(b.rates.first.price)}/${b.unit.code}');
    }

    sb.writeln('Doodh ka bill: ${Fmt.rs(b.milkCharges)}');

    if (b.nagaDays.isNotEmpty) {
      sb.writeln('—' * 16);
      sb.writeln('Naga din (${b.nagaCount}):');
      sb.writeln(_nagaLine(b));
    }

    sb.writeln('—' * 16);
    if (b.previousBalance != 0) {
      sb.writeln('Pichhla baqaya: ${Fmt.rs(b.previousBalance)}');
    }
    if (b.paidInPeriod > 0) {
      sb.writeln('Is mahine jama: ${Fmt.rs(b.paidInPeriod)}');
    }
    sb.writeln('*Baqaya: ${Fmt.rs(b.balanceDue)}*');

    if (businessName != null && businessName.trim().isNotEmpty) {
      sb.writeln('');
      sb.writeln('— ${businessName.trim()}');
    }
    return sb.toString().trim();
  }

  static String _nagaLine(BillResult b) {
    // Group naga dates by reason for a compact, clear line.
    final away = <int>[];
    final missed = <int>[];
    final other = <int>[];
    for (final n in b.nagaDays) {
      switch (n.reason) {
        case NagaReason.customerRefused:
          away.add(n.date.day);
          break;
        case NagaReason.supplierMissed:
          missed.add(n.date.day);
          break;
        default:
          other.add(n.date.day);
      }
    }
    final parts = <String>[];
    if (away.isNotEmpty) {
      parts.add('${DateUtil.ordinalDays(away)} (aap ne mana kiya)');
    }
    if (missed.isNotEmpty) {
      parts.add('${DateUtil.ordinalDays(missed)} (main nahi aaya)');
    }
    if (other.isNotEmpty) {
      parts.add(DateUtil.ordinalDays(other));
    }
    return parts.join('\n');
  }
}
