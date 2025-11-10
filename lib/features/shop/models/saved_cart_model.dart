import 'package:hive/hive.dart';

part 'saved_cart_model.g.dart';

@HiveType(typeId: 1)
class SavedCart extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime savedDate;

  @HiveField(2)
  final List<Map<String, dynamic>> items;

  @HiveField(3)
  final double totalAmount;

  @HiveField(4)
  final String qrData;

  SavedCart({
    required this.id,
    required this.savedDate,
    required this.items,
    required this.totalAmount,
    required this.qrData,
  });

  // Convert to Map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'savedDate': savedDate.toIso8601String(),
      'items': items,
      'totalAmount': totalAmount,
      'qrData': qrData,
    };
  }

  // Create from Map
  factory SavedCart.fromJson(Map<String, dynamic> json) {
    return SavedCart(
      id: json['id'] as String,
      savedDate: DateTime.parse(json['savedDate'] as String),
      items: List<Map<String, dynamic>>.from(json['items'] as List),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      qrData: json['qrData'] as String,
    );
  }

  // Get total item count
  int get itemCount {
    int count = 0;
    for (var item in items) {
      count += int.tryParse(item['productQuantity']?.toString() ?? '0') ?? 0;
    }
    return count;
  }
}
