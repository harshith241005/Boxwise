class ItemModel {
  final String id;
  String? name;
  String? description;
  int? quantity;
  double? price;
  DateTime? expiryDate;
  List<String> tags;
  final DateTime createdDate;
  DateTime? reminderDate;
  bool isTemplate;
  String? imagePath;

  ItemModel({
    required this.id,
    this.name,
    this.description = '',
    this.quantity = 1,
    this.price = 0.0,
    this.expiryDate,
    List<String>? tags,
    DateTime? createdDate,
    this.imagePath,
    this.reminderDate,
    this.isTemplate = false,
  })  : tags = tags ?? [],
        createdDate = createdDate ?? DateTime.now();

  Map<String, dynamic> toMap(String boxId) {
    return {
      'id': id,
      'box_id': boxId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'price': price,
      'expiryDate': expiryDate?.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
      'reminderDate': reminderDate?.toIso8601String(),
      'isTemplate': isTemplate ? 1 : 0,
      'imagePath': imagePath,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map, {List<String>? tags}) {
    return ItemModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      quantity: map['quantity'],
      price: map['price']?.toDouble() ?? 0.0,
      expiryDate: map['expiryDate'] != null ? DateTime.tryParse(map['expiryDate']) : null,
      createdDate: DateTime.tryParse(map['createdDate']) ?? DateTime.now(),
      reminderDate: map['reminderDate'] != null ? DateTime.tryParse(map['reminderDate']) : null,
      isTemplate: map['isTemplate'] == 1,
      imagePath: map['imagePath'],
      tags: tags ?? [],
    );
  }
}

