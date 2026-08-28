import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MockAttendanceData {
  static List<Map<String, dynamic>> getMockAttendanceHistory() {
    final now = DateTime.now();

    return [
      // Hôm nay
      {
        "icon": Icons.login,
        "title": "Điểm danh vào",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now),
        "time": "08:45 AM",
        "status": "Đúng giờ",
        "timestamp": now.subtract(Duration(hours: 4, minutes: 15)),
      },
      {
        "icon": Icons.lunch_dining,
        "title": "Tổng thời gian nghỉ",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now),
        "time": "01:30:00",
        "status": "Nghỉ",
        "timestamp": now.subtract(Duration(hours: 2, minutes: 30)),
      },
      {
        "icon": Icons.logout,
        "title": "Điểm danh về",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now),
        "time": "05:30 PM",
        "status": "Điểm danh về",
        "timestamp": now,
      },

      // Hôm qua
      {
        "icon": Icons.login,
        "title": "Điểm danh vào",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 1))),
        "time": "08:30 AM",
        "status": "Đúng giờ",
        "timestamp": now.subtract(Duration(days: 1, hours: 4, minutes: 30)),
      },
      {
        "icon": Icons.lunch_dining,
        "title": "Tổng thời gian nghỉ",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 1))),
        "time": "01:15:00",
        "status": "Nghỉ",
        "timestamp": now.subtract(Duration(days: 1, hours: 2, minutes: 45)),
      },
      {
        "icon": Icons.logout,
        "title": "Điểm danh về",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 1))),
        "time": "05:45 PM",
        "status": "Điểm danh về",
        "timestamp": now.subtract(Duration(days: 1, minutes: 15)),
      },

      // 2 ngày trước
      {
        "icon": Icons.login,
        "title": "Điểm danh vào",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 2))),
        "time": "09:15 AM",
        "status": "Điểm danh vào muộn",
        "timestamp": now.subtract(Duration(days: 2, hours: 3, minutes: 45)),
      },
      {
        "icon": Icons.lunch_dining,
        "title": "Tổng thời gian nghỉ",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 2))),
        "time": "01:45:00",
        "status": "Nghỉ",
        "timestamp": now.subtract(Duration(days: 2, hours: 2, minutes: 15)),
      },
      {
        "icon": Icons.logout,
        "title": "Điểm danh về",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 2))),
        "time": "05:20 PM",
        "status": "Điểm danh về",
        "timestamp": now.subtract(Duration(days: 2, hours: 30)),
      },

      // 3 ngày trước
      {
        "icon": Icons.login,
        "title": "Điểm danh vào",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 3))),
        "time": "08:00 AM",
        "status": "Đúng giờ",
        "timestamp": now.subtract(Duration(days: 3, hours: 5)),
      },
      {
        "icon": Icons.lunch_dining,
        "title": "Tổng thời gian nghỉ",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 3))),
        "time": "01:00:00",
        "status": "Nghỉ",
        "timestamp": now.subtract(Duration(days: 3, hours: 3)),
      },
      {
        "icon": Icons.logout,
        "title": "Điểm danh về",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 3))),
        "time": "06:00 PM",
        "status": "Điểm danh về",
        "timestamp": now.subtract(Duration(days: 3, hours: 1)),
      },

      // 4 ngày trước
      {
        "icon": Icons.login,
        "title": "Điểm danh vào",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 4))),
        "time": "08:20 AM",
        "status": "Đúng giờ",
        "timestamp": now.subtract(Duration(days: 4, hours: 4, minutes: 40)),
      },
      {
        "icon": Icons.lunch_dining,
        "title": "Tổng thời gian nghỉ",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 4))),
        "time": "01:20:00",
        "status": "Nghỉ",
        "timestamp": now.subtract(Duration(days: 4, hours: 2, minutes: 40)),
      },
      {
        "icon": Icons.logout,
        "title": "Điểm danh về",
        "date": DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(now.subtract(Duration(days: 4))),
        "time": "05:50 PM",
        "status": "Điểm danh về",
        "timestamp": now.subtract(Duration(days: 4, hours: 10)),
      },
    ];
  }
}
