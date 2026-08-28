
import 'package:attendee/model/bangchamcong.dart';

class AttendanceDataMapper {
  /// Map dữ liệu từ getBangChamCongCaNhan API
  /// Trả về thống kê tổng: tổng điểm danh, đi muộn, đúng giờ
  static Map<String, dynamic> mapBangChamCongCaNhanStats(
      BangChamCongCaNhan bangChamCong,
      ) {
    if (bangChamCong.khuvucs.isEmpty) {
      return {
        'totalAttendance': 0,
        'onTimeDays': 0,
        'lateDays': 0,
        'absentDays': 0,
        'workingDays': 0.0,
        'totalHours': 0.0,
      };
    }

    // Lấy nhân viên đầu tiên từ khu vực đầu tiên (thường chỉ có 1 nhân viên - user hiện tại)
    final nhanvien = bangChamCong.khuvucs.first.nhanvien.isNotEmpty
        ? bangChamCong.khuvucs.first.nhanvien.first
        : null;

    if (nhanvien == null) {
      return {
        'totalAttendance': 0,
        'onTimeDays': 0,
        'lateDays': 0,
        'absentDays': 0,
        'workingDays': 0.0,
        'totalHours': 0.0,
      };
    }

    // Tính thống kê
    final onTimeDays = nhanvien.getOnTimeDays();
    final lateDays = nhanvien.getLateDays();
    final absentDays = nhanvien.getAbsentDays();
    final totalAttendance = onTimeDays + lateDays;

    return {
      'totalAttendance': totalAttendance,
      'onTimeDays': onTimeDays,
      'lateDays': lateDays,
      'absentDays': absentDays,
      'workingDays': nhanvien.getWorkingDays(),
      'totalHours': nhanvien.tong,
      'nhanvien': nhanvien,
      'thang': bangChamCong.thang,
      'nam': bangChamCong.nam,
    };
  }

  /// Lấy chi tiết ngày công từ BangChamCongCaNhan
  /// Trả về Map<ngayThangNam, gioCong>
  static Map<String, double> getDayDetails(BangChamCongCaNhan bangChamCong) {
    if (bangChamCong.khuvucs.isEmpty) return {};

    final nhanvien = bangChamCong.khuvucs.first.nhanvien.isNotEmpty
        ? bangChamCong.khuvucs.first.nhanvien.first
        : null;

    if (nhanvien == null) return {};

    final Map<String, double> dayDetails = {};
    nhanvien.ngay.forEach((day, hours) {
      final formattedDate =
          '${day.padLeft(2, '0')}/${bangChamCong.thang.toString().padLeft(2, '0')}/${bangChamCong.nam}';
      dayDetails[formattedDate] = hours;
    });

    return dayDetails;
  }

  /// Phân loại loại công việc trong ngày dựa trên giờ công
  static String classifyDayType(double hours, int dayOfMonth) {
    if (hours == 0) {
      return 'Nghỉ'; // Không chấm công hoặc nghỉ
    } else if (hours >= 1) {
      return 'Đúng giờ'; // Full day
    } else if (hours > 0) {
      return 'Nửa ngày'; // Half day / Late check-in
    }
    return 'N/A';
  }

  /// Lấy màu status dựa trên loại công việc
  static String getStatusColor(String status) {
    switch (status) {
      case 'Đúng giờ':
        return '#10B981'; // Green
      case 'Nửa ngày':
        return '#FFA500'; // Orange
      case 'Đi muộn':
        return '#EF4444'; // Red
      case 'Nghỉ':
        return '#9CA3AF'; // Gray
      default:
        return '#6B7280'; // Default gray
    }
  }

  /// Map dữ liệu getOwnedAttendances để hiển thị thông tin hôm nay
  static Map<String, dynamic> mapTodayAttendance(
      List<Map<String, dynamic>> dataProvider,
      ) {
    if (dataProvider.isEmpty) {
      return {
        'hasCheckIn': false,
        'checkInTime': '',
        'latestTime': '',
        'serial': '',
        'fullName': '',
      };
    }

    // Lấy bản ghi cuối cùng (mới nhất)
    final latest = dataProvider.last;

    return {
      'hasCheckIn': true,
      'checkInTime': latest['time'] ?? '',
      'systemtime': latest['systemtime'] ?? '',
      'latestTime': _formatTimeFromString(latest['time'] ?? ''),
      'serial': latest['serial'] ?? '',
      'fullName': latest['cbnv'] ?? '',
      'id': latest['id'] ?? 0,
      'allRecords': dataProvider,
    };
  }

  /// Format time string từ "2026-05-29 07:43:22" thành "07:43"
  static String _formatTimeFromString(String timeString) {
    if (timeString.isEmpty) return '';
    try {
      final parts = timeString.split(' ');
      if (parts.length >= 2) {
        final timeParts = parts[1].split(':');
        if (timeParts.length >= 2) {
          return '${timeParts[0]}:${timeParts[1]}';
        }
      }
    } catch (_) {}
    return timeString;
  }

  /// Tính chênh lệch giờ giữa check-in và shift start time
  /// Trả về số phút muộn (âm nếu sớm)
  static int calculateLateMinutes(String checkInTime, String shiftStart) {
    try {
      final checkIn = DateTime.parse(checkInTime);
      final now = DateTime.now();

      final shiftParts = shiftStart.split(':');
      final shift = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(shiftParts[0]),
        int.parse(shiftParts[1]),
        shiftParts.length > 2 ? int.parse(shiftParts[2]) : 0,
      );

      final difference = checkIn.difference(shift);
      return difference.inMinutes;
    } catch (_) {
      return 0;
    }
  }

  /// Kiểm tra xem có phải đúng giờ không
  static bool isOnTime(String checkInTime, String shiftStart) {
    final lateMinutes = calculateLateMinutes(checkInTime, shiftStart);
    return lateMinutes <= 0; // Đúng giờ nếu không muộn
  }
}
