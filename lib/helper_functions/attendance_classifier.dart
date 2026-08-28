import 'package:intl/intl.dart';

enum AttendanceStatus {
  fullDay,
  morningOnly,
  afternoonOnly,
  missingMorning,
  missingAfternoon,
  incompleteCheckout,
  noCheckIn,
}

class AttendanceRecord {
  final DateTime time;
  final String period;
  final int dayPeriodIndex;

  AttendanceRecord({
    required this.time,
    required this.period,
    required this.dayPeriodIndex,
  });
}

class AttendanceClassifier {
  // Phân loại theo khung giờ: sáng (7h-12h), chiều (13h-17h)
  static int _getPeriodIndex(DateTime time) {
    final hour = time.hour;

    // Buổi sáng: 7h00 - 12h00
    if (hour >= 7 && hour < 12) return 0;

    // Buổi chiều: 12h00 - 17h30
    if (hour >= 12 && hour < 18) return 1;

    // Ngoài giờ (trước 7h hoặc sau 17h30)
    return -1;
  }

  static String _getPeriodName(int periodIndex) {
    switch (periodIndex) {
      case 0:
        return 'morning';
      case 1:
        return 'afternoon';
      default:
        return 'unknown';
    }
  }

  // Parse dữ liệu từ JSON với cấu trúc: id, serial, cbnv, time, systemtime
  static List<AttendanceRecord> parseAttendanceRecords(
      List<Map<String, dynamic>> rawData,
      ) {
    final records = <AttendanceRecord>[];

    for (final item in rawData) {
      final timeStr = item['time'] as String? ?? '';
      if (timeStr.isEmpty) continue;

      try {
        final dateTime = DateTime.parse(timeStr).toLocal();
        final periodIndex = _getPeriodIndex(dateTime);

        // Chỉ lấy các bản ghi trong giờ làm việc
        if (periodIndex >= 0) {
          final periodName = _getPeriodName(periodIndex);
          records.add(
            AttendanceRecord(
              time: dateTime,
              period: periodName,
              dayPeriodIndex: periodIndex,
            ),
          );
        }
      } catch (e) {
        print('Error parsing time: $timeStr - $e');
      }
    }

    // Sắp xếp theo thời gian tăng dần
    records.sort((a, b) => a.time.compareTo(b.time));
    return records;
  }

  // Phân loại trạng thái chấm công
  static AttendanceStatus classifyAttendance(
      List<AttendanceRecord> records,
      ) {
    if (records.isEmpty) {
      return AttendanceStatus.noCheckIn;
    }

    // Nhóm các bản ghi theo buổi
    final morningRecords = records.where((r) => r.dayPeriodIndex == 0).toList();
    final afternoonRecords = records.where((r) => r.dayPeriodIndex == 1).toList();

    final hasMorningCheckIn = morningRecords.isNotEmpty;
    final hasMorningCheckOut = morningRecords.length >= 2;
    final hasAfternoonCheckIn = afternoonRecords.isNotEmpty;
    final hasAfternoonCheckOut = afternoonRecords.length >= 2;

    // Trường hợp 1 & 2: Đầy đủ cả sáng và chiều
    if ((hasMorningCheckIn || hasMorningCheckOut) &&
        (hasAfternoonCheckIn || hasAfternoonCheckOut)) {
      return AttendanceStatus.fullDay;
    }

    // Trường hợp 3: Chỉ có buổi sáng
    if (hasMorningCheckIn && !hasAfternoonCheckIn) {
      if (hasMorningCheckOut) {
        // Có check-in và check-out buổi sáng nhưng thiếu buổi chiều
        return AttendanceStatus.missingAfternoon;
      } else {
        // Chỉ check-in buổi sáng, chưa checkout
        return AttendanceStatus.morningOnly;
      }
    }

    // Trường hợp 3: Chỉ có buổi chiều
    if (!hasMorningCheckIn && hasAfternoonCheckIn) {
      if (hasAfternoonCheckOut) {
        // Có check-in và check-out buổi chiều nhưng thiếu buổi sáng
        return AttendanceStatus.missingMorning;
      } else {
        // Chỉ check-in buổi chiều
        return AttendanceStatus.afternoonOnly;
      }
    }

    return AttendanceStatus.incompleteCheckout;
  }

  // Lấy thông điệp trạng thái
  static String getStatusMessage(
      AttendanceStatus status, {
        int? lateMinutes,
      }) {
    switch (status) {
      case AttendanceStatus.fullDay:
        return lateMinutes != null && lateMinutes > 0
            ? "Điểm danh cả ngày thành công (Muộn ${lateMinutes} phút)"
            : "Điểm danh cả ngày thành công";

      case AttendanceStatus.morningOnly:
        return "Điểm danh thiếu buổi chiều";

      case AttendanceStatus.afternoonOnly:
        return "Điểm danh thiếu buổi sáng";

      case AttendanceStatus.missingMorning:
        return "Điểm danh thiếu buổi sáng";

      case AttendanceStatus.missingAfternoon:
        return "Điểm danh thiếu buổi chiều";

      case AttendanceStatus.incompleteCheckout:
        return "Điểm danh thiếu giờ";

      case AttendanceStatus.noCheckIn:
        return "Chưa chấm công";
    }
  }

  // Trích xuất thời gian check-in và check-out
  static Map<String, String> getCheckInOutTimes(
      List<AttendanceRecord> records,
      ) {
    String morningCheckIn = '';
    String morningCheckOut = '';
    String afternoonCheckIn = '';
    String afternoonCheckOut = '';

    if (records.isEmpty) {
      return {
        'check_in_time': '',
        'check_out_time': '',
        'morning_check_in': '',
        'morning_check_out': '',
        'afternoon_check_in': '',
        'afternoon_check_out': '',
      };
    }

    final morningRecords = records.where((r) => r.dayPeriodIndex == 0).toList();
    final afternoonRecords = records.where((r) => r.dayPeriodIndex == 1).toList();

    // Lấy check-in và check-out buổi sáng
    if (morningRecords.isNotEmpty) {
      morningCheckIn = DateFormat('HH:mm').format(morningRecords.first.time);
      if (morningRecords.length >= 2) {
        morningCheckOut = DateFormat('HH:mm').format(morningRecords.last.time);
      }
    }

    // Lấy check-in và check-out buổi chiều
    if (afternoonRecords.isNotEmpty) {
      afternoonCheckIn = DateFormat('HH:mm').format(afternoonRecords.first.time);
      if (afternoonRecords.length >= 2) {
        afternoonCheckOut = DateFormat('HH:mm').format(afternoonRecords.last.time);
      }
    }

    // Xác định check-in chính (ưu tiên buổi sáng, nếu không có thì lấy buổi chiều)
    String mainCheckIn = morningCheckIn.isNotEmpty ? morningCheckIn : afternoonCheckIn;
    // Xác định check-out chính (ưu tiên buổi chiều, nếu không có thì lấy buổi sáng)
    String mainCheckOut = afternoonCheckOut.isNotEmpty ? afternoonCheckOut :
    (morningCheckOut.isNotEmpty ? morningCheckOut : '');

    return {
      'check_in_time': mainCheckIn,
      'check_out_time': mainCheckOut,
      'morning_check_in': morningCheckIn,
      'morning_check_out': morningCheckOut,
      'afternoon_check_in': afternoonCheckIn,
      'afternoon_check_out': afternoonCheckOut,
    };
  }

  // Tính số phút đi muộn
  static int calculateLateMinutes(
      List<AttendanceRecord> records,
      String shiftStartTime,
      ) {
    if (records.isEmpty) return 0;

    // Tìm bản ghi check-in đầu tiên trong ngày
    final firstCheckIn = records.first.time;

    try {
      final shiftParts = shiftStartTime.split(':');
      final now = DateTime.now();
      final shiftDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(shiftParts[0]),
        int.parse(shiftParts[1]),
        shiftParts.length > 2 ? int.parse(shiftParts[2]) : 0,
      );

      final difference = firstCheckIn.difference(shiftDateTime);
      if (difference.isNegative || difference.inMinutes <= 0) {
        return 0;
      }
      return difference.inMinutes.abs();
    } catch (e) {
      print('Error calculating late minutes: $e');
      return 0;
    }
  }

  // Lấy chi tiết trạng thái từng buổi
  static Map<String, dynamic> getDetailedStatus(
      List<AttendanceRecord> records,
      ) {
    final morningRecords = records.where((r) => r.dayPeriodIndex == 0).toList();
    final afternoonRecords = records.where((r) => r.dayPeriodIndex == 1).toList();

    return {
      'morning_status': morningRecords.length >= 2 ? 'Đầy đủ' :
      (morningRecords.length == 1 ? 'Thiếu checkout' : 'Không có'),
      'afternoon_status': afternoonRecords.length >= 2 ? 'Đầy đủ' :
      (afternoonRecords.length == 1 ? 'Thiếu checkout' : 'Không có'),
      'morning_count': morningRecords.length,
      'afternoon_count': afternoonRecords.length,
    };
  }
}