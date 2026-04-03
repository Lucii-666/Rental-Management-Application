import 'package:cloud_firestore/cloud_firestore.dart';

enum RentStatus { pending, paid, overdue, partiallyPaid }

class RentPaymentModel {
  final String id;
  final String propertyId;
  final String roomId;
  final String roomNumber;
  final String tenantId;
  final String tenantName;
  final String ownerId;
  final double amount;        // Total amount due this month (base + carry forward from last month)
  final double baseAmount;    // Original rent amount from room settings
  final double carryForward;  // Unpaid amount carried forward from a previous month
  final double paidAmount;    // How much was actually paid (for partial payments)
  final DateTime dueDate;
  final DateTime? paidDate;
  final RentStatus status;
  final int month; // 1-12
  final int year;
  final String? notes;

  RentPaymentModel({
    required this.id,
    required this.propertyId,
    required this.roomId,
    required this.roomNumber,
    required this.tenantId,
    required this.tenantName,
    required this.ownerId,
    required this.amount,
    double? baseAmount,
    this.carryForward = 0,
    this.paidAmount = 0,
    required this.dueDate,
    this.paidDate,
    this.status = RentStatus.pending,
    required this.month,
    required this.year,
    this.notes,
  }) : baseAmount = baseAmount ?? amount;

  /// Amount still owed after a partial payment
  double get balance => amount - paidAmount;

  String get monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month - 1]} $year';
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'ownerId': ownerId,
      'amount': amount,
      'baseAmount': baseAmount,
      'carryForward': carryForward,
      'paidAmount': paidAmount,
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'status': status.name,
      'month': month,
      'year': year,
      'notes': notes,
    };
  }

  factory RentPaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    final amount = (map['amount'] ?? 0.0).toDouble();
    return RentPaymentModel(
      id: docId,
      propertyId: map['propertyId'] ?? '',
      roomId: map['roomId'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      ownerId: map['ownerId'] ?? '',
      amount: amount,
      baseAmount: (map['baseAmount'] ?? amount).toDouble(),
      carryForward: (map['carryForward'] ?? 0.0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0.0).toDouble(),
      dueDate: (map['dueDate'] is Timestamp)
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.parse(map['dueDate']),
      paidDate: map['paidDate'] != null
          ? (map['paidDate'] is Timestamp
              ? (map['paidDate'] as Timestamp).toDate()
              : DateTime.parse(map['paidDate']))
          : null,
      status: RentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RentStatus.pending,
      ),
      month: map['month'] ?? 1,
      year: map['year'] ?? DateTime.now().year,
      notes: map['notes'],
    );
  }
}
