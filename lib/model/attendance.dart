
class Attendance {
  final int id;
  final String cbnv;
  final String time;
  final String systemTime;

  Attendance({
    required this.id,
    required this.cbnv,
    required this.time,
    required this.systemTime,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
    id: json['id'],
    cbnv: json['cbnv'] ?? '',
    time: json['time'] ?? '',
    systemTime: json['systemtime'] ?? '',
  );
}