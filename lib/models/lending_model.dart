import 'package:uuid/uuid.dart';

class LendingModel {
  final String id;
  final String itemId;
  final String itemName;
  final String borrowerName;
  final DateTime lendDate;
  final DateTime? returnDate;
  final DateTime? actualReturnDate;
  final String status; // 'active', 'returned'

  LendingModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.borrowerName,
    required this.lendDate,
    this.returnDate,
    this.actualReturnDate,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'borrower_name': borrowerName,
      'lend_date': lendDate.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'actual_return_date': actualReturnDate?.toIso8601String(),
      'status': status,
    };
  }

  factory LendingModel.fromMap(Map<String, dynamic> map) {
    return LendingModel(
      id: map['id'],
      itemId: map['item_id'],
      itemName: map['item_name'],
      borrowerName: map['borrower_name'],
      lendDate: DateTime.parse(map['lend_date']),
      returnDate: map['return_date'] != null ? DateTime.parse(map['return_date']) : null,
      actualReturnDate: map['actual_return_date'] != null ? DateTime.parse(map['actual_return_date']) : null,
      status: map['status'] ?? 'active',
    );
  }
}
