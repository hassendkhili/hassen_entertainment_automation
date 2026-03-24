import 'dart:convert';

class ActivitySchedule {
  String name;
  String time;
  String? filePath;
  bool hasPlayed;

  ActivitySchedule({
    required this.name,
    required this.time,
    this.filePath,
    this.hasPlayed = false
  });

  // تحويل الكائن إلى Map ليتم حفظه
  Map<String, dynamic> toMap() => {
    'name': name,
    'time': time,
    'filePath': filePath,
  };

  // استرجاع الكائن من Map
  factory ActivitySchedule.fromMap(Map<String, dynamic> map) => ActivitySchedule(
    name: map['name'],
    time: map['time'],
    filePath: map['filePath'],
  );
}