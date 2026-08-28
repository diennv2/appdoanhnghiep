import 'dart:convert';

import 'package:attendee/helper_functions/helper_func.dart';
import 'package:attendee/pages/settings.dart';
import 'package:attendee/provider/attendance_provider.dart';
import 'package:attendee/services/api_service.dart';
import 'package:attendee/widgets/custom_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';

import '../database/database_helper.dart';
import '../helper_functions/attendance_classifier.dart';
import '../provider/profile_image_provider.dart';
import 'activity_page.dart';
import 'notification_page.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _viVN = 'vi_VN';
  static const _maxRecentEntries = 5;
  static const _statusOnTime = 'On Time';
  static const _statusCheckedOut = 'Checked Out';
  static const _statusLate = 'Late Check-In';
  List<Map<String, dynamic>> _personalBangChamCong = [];
  late Future<List<Map<String, dynamic>>> _recentHistoryFuture;
  bool _loadingBangChamCong = true;
  String? _bangChamCongError;
  Map<String, dynamic> _monthlyStats = {
    'totalDays': 0.0,
    'onTimeDays': 0,
    'lateDays': 0,
    'absentDays': 0,
  };
  bool isFinished = false;
  late final Map<String, dynamic> userInfo;
  DateTime today = DateTime.now().toLocal();
  String fullName = "Name";
  final ScrollController _scrollController = ScrollController();
  int index = 1;
  bool isOnTime = false;

  List<DateTime> generatedDatesForCurrentMonth() {
    int year = today.year;
    int month = today.month;
    int daysInMonth = DateTime(year, month + 1, 0).day;
    return List.generate(daysInMonth, (i) => DateTime(year, month, i + 1));
  }

  Future<void> _updateField(
      BuildContext context,
      String key,
      String value,
      ) async {
    await Provider.of<DatabaseHelperProvider>(
      context,
      listen: false,
    ).updateUserField(key, value);
    if (kDebugMode) print("All Data UPDATED");
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng ☀️';
    if (hour < 17) return 'Chào buổi chiều 🌤';
    return 'Chào buổi tối 🌙';
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    userInfo = widget.user;
    fullName = widget.user['name']?.toString().trim() ?? 'User';
    final String phoneNumber =
        widget.user['phone']?.toString().trim() ?? '';
    final String email = widget.user['email']?.toString().trim() ?? '';

    if (kDebugMode) print("User Phone No is $phoneNumber");

    _updateField(context, 'full_name', fullName);

    if (phoneNumber.isNotEmpty && phoneNumber != 'null') {
      _updateField(context, 'phone', phoneNumber);
    }

    if (email.isNotEmpty) {
      _updateField(context, 'email', email);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchInitialData();
      final provider = Provider.of<DatabaseHelperProvider>(
        context,
        listen: false,
      );
      await provider.fetchUserAttendance();
    });
  }

  Future<void> _fetchInitialData() async {
    try {
      final today = DateTime.now().toUtc();
      final todayDate = DateFormat('yyyy-MM-dd').format(today);

      final provider = Provider.of<DatabaseHelperProvider>(
        context,
        listen: false,
      );

      // ── Fetch từ API ──
      await _fetchBangChamCongCaNhan();
      await _fetchUserInfoFromAPI();
      await _fetchTodayAttendanceFromAPI(todayDate);
      await _getRecentAttendanceHistory();
      await provider.fetchUserAttendance();

      // KHÔNG dùng checkInTime để tính isOnTime nữa vì giờ là HH:mm
      // Thay vào đó dùng morning_check_in từ todayAttendance
      final todayAttendance = provider.todayAttendance;
      final morningCheckIn = todayAttendance?["morning_check_in"] ?? "";
      final shiftStart = provider.profile?["start_time"] ?? "";

      if (morningCheckIn.isNotEmpty && shiftStart.isNotEmpty) {
        try {
          final now = DateTime.now();
          final timeParts = morningCheckIn.split(':');

          if (timeParts.length >= 2) {
            final checkInDateTime = DateTime(
              now.year,
              now.month,
              now.day,
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
            );

            final shiftParts = shiftStart.split(":");
            final shiftDateTime = DateTime(
              now.year,
              now.month,
              now.day,
              int.parse(shiftParts[0]),
              int.parse(shiftParts[1]),
              shiftParts.length > 2 ? int.parse(shiftParts[2]) : 0,
            );

            final difference = checkInDateTime.difference(shiftDateTime);
            setState(() {
              isOnTime = difference.isNegative || difference.inMinutes == 0;
            });

            if (mounted) {
              await provider.updateStatus(isOnTime, widget.user['user_id'], todayDate);
            }
          }
        } catch (e) {
          if (kDebugMode) print("Error calculating on time: $e");
        }
      }

      // Chỉ animate khi scrollController đã được attach
      if (_scrollController.hasClients) {
        int todayIndex = generatedDatesForCurrentMonth().indexWhere(
              (date) =>
          date.day == today.day &&
              date.month == today.month &&
              date.year == today.year,
        );

        if (todayIndex != -1) {
          double itemWidth = 75 + 11.2;
          _scrollController.animateTo(
            todayIndex * itemWidth,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context: context, label: "Lỗi tải dữ liệu: $e");
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentAttendanceHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('user_id') ?? '';
      final userIdInt = int.tryParse(userIdStr);

      // Lấy lịch sử với page size lớn hơn để có đủ dữ liệu
      final result = await ApiService.getAttendanceHistory(
        userFilter: userIdInt,
        page: 1,
        perPage: 10, // Tăng lên để có nhiều dữ liệu hơn
      );

      if (result['success'] == true && result['dataProvider'] != null) {
        final dataProvider = result['dataProvider'] as List;
        final List<Map<String, dynamic>> records = [];

        for (var item in dataProvider) {
          if (item is Map) {
            final record = Map<String, dynamic>.from(item);

            // Parse tất cả attendance records trong ngày
            final allRecords = AttendanceClassifier.parseAttendanceRecords([record]);
            final times = AttendanceClassifier.getCheckInOutTimes(allRecords);

            // Thêm thông tin chi tiết vào record
            record['morning_check_in'] = times['morning_check_in'] ?? '';
            record['morning_check_out'] = times['morning_check_out'] ?? '';
            record['afternoon_check_in'] = times['afternoon_check_in'] ?? '';
            record['afternoon_check_out'] = times['afternoon_check_out'] ?? '';

            records.add(_convertToDisplayFormat(record));
          }
        }

        // Sort by time descending và lấy 5 records gần nhất
        records.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
        return records.take(_maxRecentEntries).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching recent history: $e');
      return [];
    }
  }

  Map<String, dynamic> _convertToDisplayFormat(Map<String, dynamic> record) {
    DateTime? timestamp;
    final timeStr = record['time']?.toString() ?? '';
    if (timeStr.isNotEmpty) {
      try {
        timestamp = DateTime.parse(timeStr).toLocal();
      } catch (_) {}
    }

    // Lấy thông tin chi tiết từ record
    final morningCheckIn = record['morning_check_in']?.toString() ?? '';
    final morningCheckOut = record['morning_check_out']?.toString() ?? '';
    final afternoonCheckIn = record['afternoon_check_in']?.toString() ?? '';
    final afternoonCheckOut = record['afternoon_check_out']?.toString() ?? '';

    final lydodiemdanhho = record['lydodiemdanhho']?.toString() ?? '';
    final statusText = lydodiemdanhho.isNotEmpty ? lydodiemdanhho : 'Bình thường';

    final dateLabel = timestamp != null
        ? DateFormat('EEEE, d MMMM, yyyy', 'vi_VN').format(timestamp)
        : (record['date']?.toString() ?? '');

    // Phân loại dựa vào thời gian
    String title = 'Điểm danh';
    IconData icon = Icons.fingerprint;
    Color statusColor = Colors.blue;
    String statusDetail = '';

    if (timestamp != null) {
      final hour = timestamp.hour;
      if (hour < 12) {
        title = 'Check-In Sáng';
        icon = Icons.wb_sunny_outlined;
        statusColor = const Color(0xFFF59E0B);
      } else if (hour >= 12 && hour < 14) {
        title = 'Check-In Chiều';
        icon = Icons.wb_twilight;
        statusColor = const Color(0xFF6366F1);
      } else {
        title = 'Check-Out';
        icon = Icons.logout;
        statusColor = const Color(0xFF8B5CF6);
      }
    }

    // Xác định trạng thái chi tiết
    if (morningCheckIn.isNotEmpty && morningCheckOut.isNotEmpty &&
        afternoonCheckIn.isNotEmpty && afternoonCheckOut.isNotEmpty) {
      statusDetail = 'Đầy đủ';
      statusColor = const Color(0xFF10B981);
    } else if (morningCheckIn.isNotEmpty || afternoonCheckIn.isNotEmpty) {
      statusDetail = 'Thiếu giờ';
      statusColor = const Color(0xFFF59E0B);
    } else {
      statusDetail = 'Vắng';
      statusColor = const Color(0xFFEF4444);
    }

    return {
      'icon': icon,
      'title': title,
      'date': dateLabel,
      'time': timestamp != null ? DateFormat('HH:mm:ss').format(timestamp) : '--:--',
      'status': statusText,
      'statusDetail': statusDetail,
      'timestamp': timestamp ?? DateTime.now(),
      'statusColor': statusColor,
      'morningCheckIn': morningCheckIn,
      'morningCheckOut': morningCheckOut,
      'afternoonCheckIn': afternoonCheckIn,
      'afternoonCheckOut': afternoonCheckOut,
    };
  }

  Future<void> _fetchBangChamCongCaNhan() async {
    setState(() {
      _loadingBangChamCong = true;
      _bangChamCongError = null;
    });

    final now = DateTime.now();
    final resp = await ApiService.getBangChamCongCaNhan(thang: now.month, nam: now.year);

    if (resp['success'] == true) {
      final khuvucs = List<Map<String, dynamic>>.from(resp['khuvucs']);

      // Tính toán thống kê từ dữ liệu
      _calculateMonthlyStats(khuvucs);

      setState(() {
        _personalBangChamCong = khuvucs;
        _loadingBangChamCong = false;
      });
    } else {
      setState(() {
        _personalBangChamCong = [];
        _bangChamCongError = resp['message']?.toString();
        _loadingBangChamCong = false;
      });
    }
  }
  void _calculateMonthlyStats(List<Map<String, dynamic>> khuvucs) {
    double totalDays = 0.0;
    int onTimeDays = 0;
    int lateDays = 0;
    int absentDays = 0;

    for (var khuvuc in khuvucs) {
      final nhanviens = khuvuc['nhanvien'] as List<dynamic>? ?? [];

      for (var nv in nhanviens) {
        if (nv is Map<String, dynamic>) {
          // Lấy tổng ngày công
          final tong = double.tryParse(nv['tong']?.toString() ?? '0') ?? 0.0;
          totalDays += tong;

          // Phân tích từng ngày
          final ngay = nv['ngay'] as Map<String, dynamic>? ?? {};

          // Số ngày trong tháng hiện tại
          final now = DateTime.now();
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

          for (int day = 1; day <= daysInMonth; day++) {
            final dayKey = day.toString();
            final dayValue = double.tryParse(ngay[dayKey]?.toString() ?? '0') ?? 0.0;

            if (dayValue == 1.0) {
              onTimeDays++; // Đầy đủ = đúng giờ
            } else if (dayValue == 0.5) {
              lateDays++; // Nửa ngày = đi muộn/thiếu
            } else if (dayValue == 0.0) {
              // Kiểm tra xem có phải ngày làm việc không (thứ 2-6)
              final date = DateTime(now.year, now.month, day);
              if (date.weekday <= 5) { // Thứ 2-6
                absentDays++; // Không đi làm
              }
            }
          }
        }
      }
    }

    setState(() {
      _monthlyStats = {
        'totalDays': totalDays,
        'onTimeDays': onTimeDays,
        'lateDays': lateDays,
        'absentDays': absentDays,
      };
    });

    if (kDebugMode) {
      print("Monthly Stats: $_monthlyStats");
    }
  }
  /// Fetch user info từ API
  Future<void> _fetchUserInfoFromAPI() async {
    try {
      final result = await ApiService.getUserInfo();
      if (result['success'] == true) {
        final userInfo = result['userInfo'] as Map<String, dynamic>? ?? {};
        final provider = Provider.of<DatabaseHelperProvider>(
          context,
          listen: false,
        );

        // Cập nhật profile vào database
        await provider.updateUserField('start_time', userInfo['start_time']?.toString() ?? '');
        await provider.updateUserField('designation', userInfo['designation']?.toString() ?? '');
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching user info from API: $e");
    }
  }
  String getAttendanceStatusDisplay() {
    final dbProvider = Provider.of<DatabaseHelperProvider>(context);
    final todayAttendance = dbProvider.todayAttendance;
    final detailedStatus = todayAttendance?["detailed_status"] ?? "";
    final attendanceStatus = todayAttendance?["attendance_status"] ?? "";

    if (attendanceStatus.isNotEmpty) {
      return attendanceStatus;
    }

    return "Chưa chấm công hôm nay";
  }
  Future<void> _fetchTodayAttendanceFromAPI(String todayDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString('user_id') ?? '';
      final userIdInt = int.tryParse(userIdStr);

      if (kDebugMode) {
        print("Fetching attendance for user: $userIdInt, date: $todayDate");
      }

      final result = await ApiService.getOwnedAttendances(
        userFilter: userIdInt,
        dateFilter: todayDate,
        page: 1,
      );

      if (kDebugMode) {
        print("API Result: $result");
      }

      if (result['success'] == true) {
        // Lấy dataProvider từ response - đây là List<dynamic>
        final dataProvider = result['dataProvider'];

        if (kDebugMode) {
          print("dataProvider type: ${dataProvider.runtimeType}");
          print("dataProvider: $dataProvider");
        }

        if (dataProvider != null && dataProvider is List && dataProvider.isNotEmpty) {
          // Convert mỗi phần tử sang Map<String, dynamic>
          final List<Map<String, dynamic>> attendanceList = [];

          for (var item in dataProvider) {
            if (item is Map) {
              attendanceList.add(Map<String, dynamic>.from(item));
            }
          }

          if (kDebugMode) {
            print("Attendance list length: ${attendanceList.length}");
            for (var item in attendanceList) {
              print("Item: $item");
            }
          }

          // Parse và phân loại
          final records = AttendanceClassifier.parseAttendanceRecords(attendanceList);
          final status = AttendanceClassifier.classifyAttendance(records);
          final times = AttendanceClassifier.getCheckInOutTimes(records);

          if (kDebugMode) {
            print("Records count: ${records.length}");
            print("Status: $status");
            print("Times: $times");
          }

          final provider = Provider.of<DatabaseHelperProvider>(
            context,
            listen: false,
          );

          // Cập nhật trực tiếp vào provider
          final statusMsg = AttendanceClassifier.getStatusMessage(status);

          // Lưu vào biến todayAttendance của provider
          provider.setTodayAttendanceDirectly({
            'check_in_time': times['check_in_time'] ?? '',
            'check_out_time': times['check_out_time'] ?? '',
            'morning_check_in': times['morning_check_in'] ?? '',
            'morning_check_out': times['morning_check_out'] ?? '',
            'afternoon_check_in': times['afternoon_check_in'] ?? '',
            'afternoon_check_out': times['afternoon_check_out'] ?? '',
            'attendance_status': statusMsg,
            'date': todayDate,
          });

          // Tính late minutes nếu có
          final shiftStart = provider.profile?["start_time"] ?? "";
          if (shiftStart.isNotEmpty) {
            final lateMinutes = AttendanceClassifier.calculateLateMinutes(records, shiftStart);
            if (lateMinutes > 0) {
              provider.updateAttendanceFieldDirectly('late_minutes', lateMinutes);
            }
          }

        } else {
          // Không có dữ liệu
          if (kDebugMode) {
            print("No attendance data for today");
          }

          final provider = Provider.of<DatabaseHelperProvider>(
            context,
            listen: false,
          );

          // Reset về rỗng
          provider.setTodayAttendanceDirectly({
            'check_in_time': '',
            'check_out_time': '',
            'morning_check_in': '',
            'morning_check_out': '',
            'afternoon_check_in': '',
            'afternoon_check_out': '',
            'attendance_status': 'Chưa chấm công hôm nay',
            'date': todayDate,
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
        print("Stack trace: ${StackTrace.current}");
      }
    }
  }

  String formatTime(String timeString) {
    if (timeString.trim().isEmpty) return '';

    // Kiểm tra nếu timeString đã ở định dạng HH:mm
    if (timeString.contains(':') && !timeString.contains('-') && !timeString.contains('T')) {
      // Đã là định dạng HH:mm, trả về luôn
      return timeString;
    }

    // Nếu là ISO datetime string
    try {
      final parsedTime = DateTime.parse(timeString);
      return DateFormat('HH:mm').format(parsedTime.toLocal());
    } catch (e) {
      if (kDebugMode) {
        print("Error parsing time: $timeString - $e");
      }
      return timeString; // Trả về nguyên bản nếu không parse được
    }
  }

  String formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  void checkIn() async {
    await HelperFunction().handleCheckIn(context);
  }

  /// Returns the set of day-of-month numbers that have a Check In record
  /// in the current month, parsed from the attendance list.
  Set<int> _getAttendedDaysInCurrentMonth(
      List<Map<String, dynamic>> activityList) {
    final Set<int> days = {};
    final now = DateTime.now();
    final fmt = DateFormat('EEEE,d MMMM,yyyy');
    for (final item in activityList) {
      if (item["title"] == "Check In") {
        final dateStr = item["date"] as String? ?? "";
        try {
          final parsed = fmt.parse(dateStr);
          if (parsed.month == now.month && parsed.year == now.year) {
            days.add(parsed.day);
          }
        } catch (_) {}
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;
    final List<DateTime> monthDates = generatedDatesForCurrentMonth();
    final isDark = Theme.of(context).brightness == Brightness.light;
    final dbProvider = Provider.of<DatabaseHelperProvider>(context);
    final profile = dbProvider.profile;
    final todayAttendance = dbProvider.todayAttendance;
    final workingDaysCount = dbProvider.workedDaysCount ?? 0;
    final checkInTime = todayAttendance?["check_in_time"] ?? "";
    final checkOutTime = todayAttendance?["check_out_time"] ?? "";
    final formattedCheckInTime = checkInTime.isNotEmpty ? checkInTime : "";
    final formattedCheckOutTime = checkOutTime.isNotEmpty ? checkOutTime : "";
    final attendedDays = _getAttendedDaysFromBangChamCong();

    final shiftStart = (profile?["start_time"] ?? " ").trim();
    final designation =
    (profile?["designation"] != null && profile?["designation"] != "")
        ? profile!["designation"]
        : "Nhân viên";

    if (kDebugMode) print("Format is $formattedCheckInTime");

    int lateMinutes = 0;
    if (checkInTime.isNotEmpty && shiftStart.isNotEmpty) {
      final checkedTimestamp = DateTime.parse(checkInTime).toLocal();
      final now = DateTime.now();
      final shiftParts = shiftStart.split(":");
      if (shiftParts.length >= 3) {
        final shiftDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(shiftParts[0]),
          int.parse(shiftParts[1]),
          int.parse(shiftParts[2]),
        );
        final difference = checkedTimestamp.difference(shiftDateTime);
        isOnTime = difference.isNegative || difference.inMinutes == 0;
        if (!isOnTime) lateMinutes = difference.inMinutes.abs();
      }
    }

    final isCheckedIn = context.watch<AttendanceProvider>().isCheckedIn;
    final activityList = dbProvider.attendance ?? [];
    final onTimeCount =
        activityList.where((e) => e["status"] == _statusOnTime).length;
    final lateCount =
        activityList.where((e) => e["status"] == _statusLate).length;

    final bgColor =
    isDark ?  const Color(0xFFF0F2FF) : const Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        color: const Color(0xFF667EEA),
        onRefresh: _fetchInitialData,
        child: CustomScrollView(
          slivers: [
            // ── Personalised gradient header ─────────────────────────
            SliverToBoxAdapter(
              child: _buildHeader(isDark, isSmallScreen, designation),
            ),

            // ── Horizontal date strip ─────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _DateStripDelegate(
                monthDates: monthDates,
                today: today,
                scrollController: _scrollController,
                isDark: isDark,
                attendedDays: attendedDays,
              ),
            ),

            // ── Main content ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero attendance card
                  _buildHeroCard(
                    isDark,
                    isSmallScreen,
                    formattedCheckInTime,
                    formattedCheckOutTime,
                    isCheckedIn,
                    lateMinutes,
                  ),

                  // Monthly summary row
                  _buildMonthlySummary(
                    isDark,
                    isSmallScreen,
                    workingDaysCount,
                    onTimeCount,
                    lateCount,
                  ),

                  // Activity list
                  _buildActivityList(isDark, isSmallScreen, activityList),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Personalised header ──────────────────────────────────────────────────

  Widget _buildHeader(bool isDark, bool isSmallScreen, String designation) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + notification bell
              Row(
                children: [
                  Text(
                    _greeting(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: isSmallScreen ? 12 : 13,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationScreen()),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Avatar + name + designation
              Row(
                children: [
                  Consumer<ProfileImageProvider>(
                    builder: (ctx, pp, _) {
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SettingPage(user: userInfo)),
                        ),
                        child: Hero(
                          tag: 'profile-image-hero',
                          child: CircleAvatar(
                            radius: isSmallScreen ? 26 : 32,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: pp.cachedImageBytes != null
                                ? MemoryImage(pp.cachedImageBytes!)
                            as ImageProvider
                                : (pp.imageUrl != null
                                ? NetworkImage(pp.imageUrl!)
                                : const AssetImage(
                                "assets/images/avatar.png")),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            designation,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 11 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Today date pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                  Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  DateFormat('EEEE, dd MMMM yyyy', _viVN)
                      .format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12 : 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero attendance card ─────────────────────────────────────────────────

  Widget _buildHeroCard(
      bool isDark,
      bool isSmallScreen,
      String checkInDisp,
      String checkOutDisp,
      bool isCheckedIn,
      int lateMinutes,
      ) {
    final cardColor = isDark ? Colors.white : const Color(0xFF161B22);

    // Lấy trực tiếp từ provider
    final dbProvider = Provider.of<DatabaseHelperProvider>(context);
    final todayAttendance = dbProvider.todayAttendance;

    // Debug
    if (kDebugMode) {
      print("Today attendance in card: $todayAttendance");
    }

    // Lấy thông tin chi tiết
    final morningCheckIn = todayAttendance?["morning_check_in"] ?? "";
    final morningCheckOut = todayAttendance?["morning_check_out"] ?? "";
    final afternoonCheckIn = todayAttendance?["afternoon_check_in"] ?? "";
    final afternoonCheckOut = todayAttendance?["afternoon_check_out"] ?? "";
    final attendanceStatus = todayAttendance?["attendance_status"] ?? "";

    // Xác định trạng thái và màu sắc
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (attendanceStatus.isEmpty || attendanceStatus.contains("Chưa chấm công")) {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_outlined;
      statusLabel = "❌ Chưa chấm công hôm nay";
    } else if (attendanceStatus.contains("đầy đủ") || attendanceStatus.contains("thành công")) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_outline;
      statusLabel = "✅ $attendanceStatus";
    } else if (attendanceStatus.contains("thiếu")) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.warning_amber_rounded;
      statusLabel = "⚠️ $attendanceStatus";
    } else if (attendanceStatus.contains("Muộn")) {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.access_time_filled;
      statusLabel = "⚠️ $attendanceStatus";
    } else {
      statusColor = const Color(0xFF6366F1);
      statusIcon = Icons.access_time;
      statusLabel = attendanceStatus.isNotEmpty ? attendanceStatus : "Chưa chấm công hôm nay";
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          children: [
            // Tiêu đề
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "CHI TIẾT CHẤM CÔNG HÔM NAY",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[600] : Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2 cột sáng/chiều
            Row(
              children: [
                // Buổi sáng
                Expanded(
                  child: _buildSessionBlock(
                    "BUỔI SÁNG",
                    morningCheckIn,
                    morningCheckOut,
                    morningCheckIn.isNotEmpty,
                    const Color(0xFFF59E0B),
                    isDark,
                    isSmallScreen,
                  ),
                ),
                Container(
                  width: 1,
                  height: 80,
                  color: isDark ? Colors.grey[200] : Colors.white12,
                ),
                // Buổi chiều
                Expanded(
                  child: _buildSessionBlock(
                    "BUỔI CHIỀU",
                    afternoonCheckIn,
                    afternoonCheckOut,
                    afternoonCheckIn.isNotEmpty,
                    const Color(0xFF6366F1),
                    isDark,
                    isSmallScreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.35)),
              ),
              child: Text(
                statusLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: isSmallScreen ? 13 : 15,
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

// Widget hiển thị từng buổi
  Widget _buildSessionBlock(
      String label,
      String checkIn,
      String checkOut,
      bool hasData,
      Color color,
      bool isDark,
      bool isSmallScreen,
      ) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hasData ? color.withOpacity(0.12) : (isDark ? Colors.grey[100] : Colors.white12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            label.contains("SÁNG") ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
            color: hasData ? color : Colors.grey[400],
            size: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          checkIn.isNotEmpty ? checkIn : "--:--",
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: hasData ? (isDark ? const Color(0xFF1A1A2E) : Colors.white) : Colors.grey[400],
          ),
        ),
        Text(
          "CHECK IN",
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          checkOut.isNotEmpty ? checkOut : "--:--",
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: hasData ? (isDark ? const Color(0xFF1A1A2E) : Colors.white) : Colors.grey[400],
          ),
        ),
        Text(
          "CHECK OUT",
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: hasData ? color : Colors.grey[500], letterSpacing: 0.8),
        ),
      ],
    );
  }

// Tạo thông báo chi tiết
  String _getDetailedStatusMessage(
      String morningIn, String morningOut,
      String afternoonIn, String afternoonOut,
      ) {
    List<String> messages = [];

    // Kiểm tra buổi sáng
    if (morningIn.isEmpty && morningOut.isEmpty) {
      messages.add("• Sáng: Chưa chấm công");
    } else if (morningIn.isNotEmpty && morningOut.isEmpty) {
      messages.add("• Sáng: Thiếu giờ ra");
    } else if (morningIn.isNotEmpty && morningOut.isNotEmpty) {
      messages.add("• Sáng: $morningIn - $morningOut ");
    }

    // Kiểm tra buổi chiều
    if (afternoonIn.isEmpty && afternoonOut.isEmpty) {
      messages.add("• Chiều: Chưa chấm công");
    } else if (afternoonIn.isNotEmpty && afternoonOut.isEmpty) {
      messages.add("• Chiều: Thiếu giờ ra");
    } else if (afternoonIn.isNotEmpty && afternoonOut.isNotEmpty) {
      messages.add("• Chiều: $afternoonIn - $afternoonOut ");
    }

    return messages.join("\n");
  }

  Widget _timeBlock(
      String label,
      String value,
      IconData icon,
      Color color,
      bool isDark,
      bool isSmallScreen,
      ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF1A1A2E)  : Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ── Monthly summary row ──────────────────────────────────────────────────

  Widget _buildMonthlySummary(
      bool isDark,
      bool isSmallScreen,
      int workingDays,
      int onTimeCount,
      int lateCount,
      ) {
    // Sử dụng _monthlyStats thay vì activityList
    final totalDays = _monthlyStats['totalDays'] ?? 0.0;
    final onTimeDays = _monthlyStats['onTimeDays'] ?? 0;
    final lateDays = _monthlyStats['lateDays'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề tháng
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_month, size: 18, color: isDark ? Colors.grey[600] : Colors.white54),
                const SizedBox(width: 8),
                Text(
                  "THỐNG KÊ THÁNG ${today.month}/${today.year}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[600] : Colors.white54,
                    letterSpacing: 0.8,
                  ),
                ),
                if (_loadingBangChamCong)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF667EEA),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Cards thống kê
          Row(
            children: [
              Expanded(
                child: _summaryCell(
                  totalDays.toString(),
                  "Ngày công",
                  const Color(0xFF667EEA),
                  isDark,
                  isSmallScreen,
                  subtitle: "Tổng",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCell(
                  "$onTimeDays",
                  "Đúng giờ",
                  const Color(0xFF10B981),
                  isDark,
                  isSmallScreen,
                  subtitle: "Đầy đủ",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCell(
                  "$lateDays",
                  "Đi muộn",
                  const Color(0xFFEF4444),
                  isDark,
                  isSmallScreen,
                  subtitle: "Thiếu/Trễ",
                ),
              ),
            ],
          ),

          // Progress bar thể hiện tỉ lệ
          if (totalDays > 0) ...[
            const SizedBox(height: 12),
            _buildProgressBar(isDark, totalDays, onTimeDays, lateDays),
          ],
        ],
      ),
    );
  }

// Widget progress bar
  Widget _buildProgressBar(bool isDark, double totalDays, int onTimeDays, int lateDays) {
    final totalValidDays = onTimeDays + lateDays;
    if (totalValidDays == 0) return const SizedBox.shrink();

    final onTimePercent = (onTimeDays / totalValidDays * 100).clamp(0, 100);
    final latePercent = (lateDays / totalValidDays * 100).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[200]! : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tỉ lệ chuyên cần",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[600] : Colors.white54,
                ),
              ),
              Text(
                "${onTimePercent.toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Flexible(
                    flex: onTimeDays,
                    child: Container(
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  if (lateDays > 0)
                    Flexible(
                      flex: lateDays,
                      child: Container(
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _legendDot(const Color(0xFF10B981), "Đúng giờ", isDark),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFEF4444), "Đi muộn", isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[600] : Colors.white54,
          ),
        ),
      ],
    );
  }

// Cập nhật _summaryCell để thêm subtitle
  Widget _summaryCell(
      String value,
      String label,
      Color color,
      bool isDark,
      bool isSmallScreen,
      {String? subtitle}
      ) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 16,
          horizontal: isSmallScreen ? 8 : 12
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              color: isDark ? Colors.grey[600] : Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: color.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

// Cập nhật _getAttendedDaysInCurrentMonth để dùng _personalBangChamCong
  Set<int> _getAttendedDaysFromBangChamCong() {
    final Set<int> days = {};

    for (var khuvuc in _personalBangChamCong) {
      final nhanviens = khuvuc['nhanvien'] as List<dynamic>? ?? [];

      for (var nv in nhanviens) {
        if (nv is Map<String, dynamic>) {
          final ngay = nv['ngay'] as Map<String, dynamic>? ?? {};

          ngay.forEach((dayStr, value) {
            final dayValue = double.tryParse(value?.toString() ?? '0') ?? 0.0;
            final day = int.tryParse(dayStr);

            if (day != null && dayValue > 0) {
              days.add(day); // Có đi làm (kể cả nửa ngày)
            }
          });
        }
      }
    }

    return days;
  }
  // ── Widget hiển thị lịch sử chấm công chi tiết ──
  Widget _buildAttendanceListFromAPI(
      List<Map<String, dynamic>> records,
      bool isDark,
      bool isSmallScreen,
      ) {
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Chưa có lịch sử chấm công.',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final event = records[idx];
        final statusColor = event['statusColor'] as Color? ?? const Color(0xFF667EEA);
        final morningIn = event['morningCheckIn']?.toString() ?? '';
        final morningOut = event['morningCheckOut']?.toString() ?? '';
        final afternoonIn = event['afternoonCheckIn']?.toString() ?? '';
        final afternoonOut = event['afternoonCheckOut']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : const Color(0xFF1A1D2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Ngày + Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          event['icon'] as IconData? ?? Icons.access_time,
                          color: statusColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'] ?? "—",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                            ),
                          ),
                          Text(
                            event['date'] ?? "",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: isSmallScreen ? 10 : 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event['statusDetail'] ?? event['status'] ?? "",
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Chi tiết check-in/check-out (nếu có)
              if (morningIn.isNotEmpty || afternoonIn.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[50] : const Color(0xFF222640),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Buổi sáng
                      Expanded(
                        child: _buildSessionDetail(
                          'Buổi sáng',
                          Icons.wb_sunny_outlined,
                          const Color(0xFFF59E0B),
                          morningIn,
                          morningOut,
                          isDark,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: isDark ? Colors.grey[200] : Colors.white12,
                      ),
                      // Buổi chiều
                      Expanded(
                        child: _buildSessionDetail(
                          'Buổi chiều',
                          Icons.nights_stay_outlined,
                          const Color(0xFF6366F1),
                          afternoonIn,
                          afternoonOut,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Thời gian check-in gần nhất
              if (event['time'] != null && event['time'].toString() != '--:--') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Gần nhất: ${event['time']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

// ── Widget chi tiết từng buổi ──
  Widget _buildSessionDetail(
      String label,
      IconData icon,
      Color color,
      String checkIn,
      String checkOut,
      bool isDark,
      ) {
    final hasData = checkIn.isNotEmpty;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: hasData ? color : Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: hasData ? color : Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hasData ? checkIn : '--:--',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: hasData
                    ? (isDark ? const Color(0xFF1A1A2E) : Colors.white)
                    : Colors.grey[500],
              ),
            ),
            if (hasData && checkOut.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey[400]),
              ),
              Text(
                checkOut,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

// Giữ lại phương thức cũ cho fallback
  Widget _buildAttendanceList(
      List<Map<String, dynamic>> list,
      bool isDark,
      bool isSmallScreen,
      ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: isDark ? Colors.white12 : Colors.grey[100],
      ),
      itemBuilder: (ctx, idx) {
        final event = list[idx];
        final statusColor = event["status"] == _statusOnTime
            ? const Color(0xFF10B981)
            : event["status"] == _statusCheckedOut
            ? const Color(0xFF6366F1)
            : const Color(0xFFEF4444);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  event["icon"] ?? Icons.access_time,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event["title"] ?? "—",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      event["date"] ?? "",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: isSmallScreen ? 10 : 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    event["time"] ?? "--:--",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event["status"] ?? "",
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  // ── Activity / attendance history list ──────────────────────────────────

  Widget _buildActivityList(
      bool isDark,
      bool isSmallScreen,
      List<Map<String, dynamic>> activityList,
      ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? Colors.white : const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 20,
                      color: const Color(0xFF667EEA),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Lịch sử chấm công",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActivityPage(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFF667EEA),
                  ),
                  label: const Text(
                    "Xem tất cả",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF667EEA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Subtle description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "5 lần chấm công gần nhất của bạn",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // Content
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getRecentAttendanceHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF667EEA)),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                // Fallback to local database if API fails
                return Consumer<DatabaseHelperProvider>(
                  builder: (ctx, provider, __) {
                    if (provider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF667EEA)),
                        ),
                      );
                    }

                    final list = provider.attendance;
                    if (list == null || list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'Chưa có lịch sử chấm công.',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Show only the most recent entries
                    final start = list.length > _maxRecentEntries
                        ? list.length - _maxRecentEntries
                        : 0;
                    final recent = list.skip(start).toList();

                    return _buildAttendanceList(recent, isDark, isSmallScreen);
                  },
                );
              }

              final recentRecords = snapshot.data!;
              return _buildAttendanceListFromAPI(recentRecords, isDark, isSmallScreen);
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// ── Horizontal date strip persistent header ────────────────────────────────

class _DateStripDelegate extends SliverPersistentHeaderDelegate {
  static const _viVN = 'vi_VN';
  static const _stripHeight = 90.0;

  final List<DateTime> monthDates;
  final DateTime today;
  final ScrollController scrollController;
  final bool isDark;
  final Set<int> attendedDays;

  const _DateStripDelegate({
    required this.monthDates,
    required this.today,
    required this.scrollController,
    required this.isDark,
    required this.attendedDays,
  });

  @override
  double get minExtent => _stripHeight;
  @override
  double get maxExtent => _stripHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ?  const Color(0xFFF0F2FF) : const Color(0xFF0D1117) ,
      height: _stripHeight,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: monthDates.length,
        itemBuilder: (ctx, index) {
          final date = monthDates[index];
          final isToday = date.day == today.day &&
              date.month == today.month &&
              date.year == today.year;
          final hasAttendance = attendedDays.contains(date.day);

          return GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                gradient: isToday
                    ? const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                )
                    : null,
                color: isToday
                    ? null
                    : (isDark
                    ? Colors.white
                    : const Color(0xFF161B22)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isToday
                    ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat("dd").format(date),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isToday
                          ? Colors.white
                          : (isDark
                          ? Colors.black87
                          : Colors.white70),
                    ),
                  ),
                  Text(
                    DateFormat("EEE", _viVN).format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: isToday
                          ? Colors.white70
                          : (isDark
                          ? Colors.black45
                          : Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Attendance dot
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasAttendance
                          ? (isToday
                          ? Colors.white
                          : const Color(0xFF10B981))
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_DateStripDelegate oldDelegate) =>
      oldDelegate.isDark != isDark ||
          oldDelegate.attendedDays != attendedDays;
}