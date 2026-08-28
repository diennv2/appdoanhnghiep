import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceProvider with ChangeNotifier {
  bool _isCheckedIn = false;
  bool isOnBreak = false;
  String? attendanceId; // today's attendance record
  DateTime? checkInTime;
  DateTime? lastBreakStart;
  Duration totalBreakDuration = Duration.zero;

  bool get isCheckedIn => _isCheckedIn;

  AttendanceProvider() {
    loadCheckInStatus();
  }

  Future<void> checkIn(String id, DateTime time) async {
    checkInTime = time.toLocal();
    _isCheckedIn = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("checkStatus", _isCheckedIn);
    notifyListeners();
  }

  void startBreak() {
    isOnBreak = true;
    lastBreakStart = DateTime.now();
    notifyListeners();
  }

  void endBreak() {
    if (lastBreakStart != null) {
      totalBreakDuration += DateTime.now().difference(lastBreakStart!);
      lastBreakStart = null;
    }
    isOnBreak = false;
    notifyListeners();
  }

  Future<void> checkOut() async {
    _isCheckedIn = false;
    attendanceId = null;
    checkInTime = null;
    totalBreakDuration = Duration.zero;
    isOnBreak = false;
    lastBreakStart = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("checkStatus", _isCheckedIn);
    notifyListeners();
  }

  Future<void> setCheckedIn(bool value) async {
    _isCheckedIn = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("checkStatus", _isCheckedIn);
    notifyListeners();
  }

  Future<void> loadCheckInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isCheckedIn = prefs.getBool('checkStatus') ?? false;
    _isCheckedIn = isCheckedIn;
    notifyListeners();
  }
}
