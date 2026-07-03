class Reminder {
  final int? id;
  final int? medicineId;
  final String time; // Format: "HH:mm"
  final String repeatType; // "Every Day", "Mon-Fri", "Custom"
  final List<String> days; // e.g., ["Monday", "Wednesday"]
  final bool isActive;

  Reminder({
    this.id,
    this.medicineId,
    required this.time,
    required this.repeatType,
    required this.days,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'time': time,
      'repeatType': repeatType,
      'days': days.join(','),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      medicineId: map['medicineId'],
      time: map['time'],
      repeatType: map['repeatType'],
      days: map['days'] != null && (map['days'] as String).isNotEmpty
          ? (map['days'] as String).split(',')
          : [],
      isActive: map['isActive'] == 1,
    );
  }

  Reminder copyWith({
    int? id,
    int? medicineId,
    String? time,
    String? repeatType,
    List<String>? days,
    bool? isActive,
  }) {
    return Reminder(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      time: time ?? this.time,
      repeatType: repeatType ?? this.repeatType,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
    );
  }
}
