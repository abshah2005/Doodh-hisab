import 'package:intl/intl.dart';

import '../data/enums.dart';

/// Number, quantity and currency formatting used across the app.
class Fmt {
  Fmt._();

  static final NumberFormat _rs = NumberFormat('#,##0', 'en');
  static final NumberFormat _qty = NumberFormat('0.##', 'en');

  /// Rupees with the `Rs` prefix, e.g. `Rs 12,100`.
  static String rs(num amount) => 'Rs ${_rs.format(amount)}';

  /// A quantity trimmed of trailing zeros, e.g. `2`, `1.5`, `0.75`.
  static String qty(num q) => _qty.format(q);

  /// Quantity with its unit, e.g. `2 kg`, `1.5 L`.
  static String qtyUnit(num q, MilkUnit unit) => '${qty(q)} ${unit.code}';
}
