import '../enums.dart';

/// A payment received from a customer.
class Payment {
  final int? id;
  final int customerId;
  final String date;
  final double amount;
  final PaymentMethod method;
  final String? note;
  final String createdAt;

  const Payment({
    this.id,
    required this.customerId,
    required this.date,
    required this.amount,
    this.method = PaymentMethod.cash,
    this.note,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'customer_id': customerId,
        'date': date,
        'amount': amount,
        'method': method.code,
        'note': note,
        'created_at': createdAt,
      };

  factory Payment.fromMap(Map<String, Object?> m) => Payment(
        id: m['id'] as int?,
        customerId: m['customer_id'] as int,
        date: m['date'] as String,
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        method: PaymentMethod.fromCode(m['method'] as String? ?? 'cash'),
        note: m['note'] as String?,
        createdAt: m['created_at'] as String,
      );
}
