class History {
  final int? id;
  final int medicineId;
  final int reminderId;
  final String date; // YYYY-MM-DD
  final String status; // "Taken", "Skipped", "Missed"
  final DateTime createdAt;

  History({
    this.id,
    required this.medicineId,
    required this.reminderId,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'reminderId': reminderId,
      'date': date,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory History.fromMap(Map<String, dynamic> map) {
    return History(
      id: map['id'],
      medicineId: map['medicineId'],
      reminderId: map['reminderId'],
      date: map['date'],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  History copyWith({
    int? id,
    int? medicineId,
    int? reminderId,
    String? date,
    String? status,
    DateTime? createdAt,
  }) {
    return History(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      reminderId: reminderId ?? this.reminderId,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
