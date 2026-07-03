class Medicine {
  final int? id;
  final String name;
  final String dosage;
  final String type;
  final String color;
  final String notes;
  final int stock;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.type,
    required this.color,
    required this.notes,
    required this.stock,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'type': type,
      'color': color,
      'notes': notes,
      'stock': stock,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      type: map['type'],
      color: map['color'],
      notes: map['notes'] ?? '',
      stock: map['stock'] ?? 0,
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Medicine copyWith({
    int? id,
    String? name,
    String? dosage,
    String? type,
    String? color,
    String? notes,
    int? stock,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      stock: stock ?? this.stock,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
