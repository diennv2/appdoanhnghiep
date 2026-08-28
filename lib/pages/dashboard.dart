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
import 'package:swipeable_button_view/swipeable_button_view.dart';

import '../database/database_helper.dart';
import '../provider/profile_image_provider.dart';
import '../widgets/custom_attendance_card.dart';
import 'activity_page.dart';
import 'notification_page.dart';

class Dashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  const Dashboard({super.key, required this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool isFinished = false;
  late final Map<String, dynamic> userInfo;
  DateTime today = DateTime.now().toLocal();
  String fullName = "Name";
  final ScrollController _scrollController = ScrollController();
  int index = 1;
  bool isOnTime = false;

  // API-sourced data supplements
  Map<String, dynamic>? _apiUserInfo;
  String? _apiCheckInTime;
  String? _apiCheckOutTime;
  int _apiWorkingDays = 0;
  List<Map<String, dynamic>> _apiActivityList = [];

  List<DateTime> generatedDatesForCurrentMonth() {
    int year = today.year;
    int month = today.month;
    int daysInMonth = DateTime(year, month + 1, 0).day;

    return List.generate(
      daysInMonth,
          (index) => DateTime(year, month, index + 1),
    );
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
    print("All Data UPDATED");
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
    final String phoneNumber = widget.user['phone']?.toString().trim() ?? '';
    final String email = widget.user['email']?.toString().trim() ?? '';

    print("User Phone No is $phoneNumber");

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
      await provider.fetchUserProfile();
      await provider.fetchUserAttendanceByDate(todayDate);
      await provider.fetchUserAttendance();
      // ── New API supplemental calls ──────────────────────────────
      // 1. Get user info from new API
      final userInfoResult = await ApiService.getUserInfo();
      if (userInfoResult['success'] == true && mounted) {
        setState(() {
          _apiUserInfo = userInfoResult['data'] as Map<String, dynamic>?;
          final apiName = _apiUserInfo?['displayName']?.toString()
              ?? _apiUserInfo?['name']?.toString();
          if (apiName != null && apiName.isNotEmpty) {
            fullName = apiName;
          }
        });
      }

      // 2. Get owned attendances for today
      final ownedResult = await ApiService.getOwnedAttendances(
        dateFilter: todayDate,
        page: 1,
      );
      if (ownedResult['success'] == true && mounted) {
        final data = ownedResult['data'] as Map<String, dynamic>? ?? {};
        final rawList = data['dataProvider'];
        if (rawList is List && rawList.isNotEmpty) {
          final records = rawList.whereType<Map>().toList();
          setState(() {
            _apiActivityList = records
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            if (records.isNotEmpty) {
              // Treat first record as check-in, last as check-out
              _apiCheckInTime = records.first['time']?.toString()
                  ?? records.first['systemtime']?.toString();
              if (records.length > 1) {
                _apiCheckOutTime = records.last['time']?.toString()
                    ?? records.last['systemtime']?.toString();
              }
            }
          });
        }
      }

      // 3. Get monthly timesheet for working days count
      final bangResult = await ApiService.getBangChamCong(
        thang: DateTime.now().month,
        nam: DateTime.now().year,
      );
      if (bangResult['success'] == true && mounted) {
        final bangData = bangResult['data'] as Map<String, dynamic>? ?? {};
        final khuvucs = bangData['khuvucs'];
        if (khuvucs is List) {
          // Try to match current user by user_id or username; fall back to
          // the first employee record if no match is found.
          final currentUserId = widget.user['user_id']?.toString() ?? '';
          final currentUsername = widget.user['username']?.toString() ?? '';
          int totalDays = 0;
          bool matched = false;

          for (final kv in khuvucs) {
            if (kv is! Map) continue;
            final nhanviens = kv['nhanvien'];
            if (nhanviens is! List) continue;
            for (final nv in nhanviens) {
              if (nv is! Map) continue;
              final nvId = nv['id']?.toString() ?? '';
              final nvCode = nv['cbnv']?.toString() ?? '';
              final tong = nv['tong'];
              if (tong == null) continue;
              final days = (tong as num).toInt();
              if (!matched) {
                // First record as default
                totalDays = days;
              }
              if (nvId == currentUserId || nvCode == currentUsername) {
                // Exact match found — use this employee's total
                totalDays = days;
                matched = true;
                break;
              }
            }
            if (matched) break;
          }

          if (totalDays > 0 && mounted) {
            setState(() => _apiWorkingDays = totalDays);
          }
        }
      }

      // ── Existing on-time logic ────────────────────────────────
      final todayAttendance = provider.todayAttendance;
      final checkInTime = todayAttendance?['check_in_time'] ?? _apiCheckInTime ?? '';
      final shiftStart = provider.profile?['start_time'] ?? '';

      if (checkInTime.isNotEmpty && shiftStart.isNotEmpty) {
        final checkedTimestamp = DateTime.parse(checkInTime).toLocal();
        final now = DateTime.now();
        final shiftParts = shiftStart.split(':');
        final shiftDateTime = DateTime(
          now.year, now.month, now.day,
          int.parse(shiftParts[0]),
          int.parse(shiftParts[1]),
          int.parse(shiftParts[2]),
        );
        final difference = checkedTimestamp.difference(shiftDateTime);
        setState(() {
          isOnTime = difference.isNegative || difference.inMinutes == 0;
        });

        if (mounted) {
          await Provider.of<DatabaseHelperProvider>(
            context,
            listen: false,
          ).updateStatus(isOnTime, widget.user['user_id'], todayDate);
        }
      }

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
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(context: context, label: "Không thể tải dữ liệu: $e");
      }
    }
  }

  String formatTime(String timeString) {
    if (timeString.trim().isEmpty) return '';
    try {
      final parsedTime = DateTime.parse(timeString);
      return DateFormat.jm().format(parsedTime.toLocal());
    } catch (_) {
      return timeString;
    }
  }

  String formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours : $minutes phút';
  }

  void checkIn() async {
    await HelperFunction().handleCheckIn(context);
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> monthDates = generatedDatesForCurrentMonth();
    final isDark = Theme.of(context).brightness == Brightness.light;
    final dbProvider = Provider.of<DatabaseHelperProvider>(context);
    final profile = dbProvider.profile;
    final todayAttendance = dbProvider.todayAttendance;

    // Use API data if provider has no data
    final checkInTime  = todayAttendance?['check_in_time']  ?? _apiCheckInTime  ?? '';
    final checkOutTime = todayAttendance?['check_out_time'] ?? _apiCheckOutTime ?? '';

    // Use API working days if provider doesn't have it
    final workingDaysCount = (dbProvider.workedDaysCount != null && dbProvider.workedDaysCount! > 0)
        ? dbProvider.workedDaysCount!
        : _apiWorkingDays;

    final formattedCheckInTime  = formatTime(checkInTime);
    final formattedCheckOutTime = formatTime(checkOutTime);
    final breakTimeSec = todayAttendance?['totalBreakTime'] ?? 0;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;

    final breakCount =
    (todayAttendance?["breakCount"] == null ||
        todayAttendance?["breakCount"] == 0)
        ? 1
        : todayAttendance?["breakCount"];

    final avgBreakTime = formatDuration(breakTimeSec ~/ breakCount);
    final breakTime = formatDuration(breakTimeSec);

    final shiftStart = profile?["start_time"] ?? " ";
    if (kDebugMode) {
      print("Format is $formattedCheckInTime");
    }

    if (checkInTime.isNotEmpty && shiftStart.isNotEmpty) {
      final checkedTimestamp = DateTime.parse(checkInTime).toLocal();
      final now = DateTime.now();

      final shiftParts = shiftStart.split(":");
      final shiftDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(shiftParts[0]),
        int.parse(shiftParts[1]),
        int.parse(shiftParts[2]),
      );

      final difference = checkedTimestamp.difference(shiftDateTime);

      print(difference);
      if (difference.isNegative || difference.inMinutes == 0) {
        print("On time ✅");
        isOnTime = true;
      } else {
        print("Late by ${difference.inMinutes.abs()} minutes ❌");
        isOnTime = false;
      }
    }

    return ClipRect(
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _fetchInitialData,
          child: SizedBox(
            height: double.infinity,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Consumer<ProfileImageProvider>(
                              builder: (ctx, profileProvider, child) {
                                final imageUrl = profileProvider.imageUrl;
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SettingPage(user: userInfo),
                                      ),
                                    );
                                  },
                                  child: Hero(
                                    tag: 'profile-image-hero',
                                    child: CircleAvatar(
                                      radius: isSmallScreen ? 25 : 29,
                                      backgroundImage:
                                      profileProvider.cachedImageBytes !=
                                          null
                                          ? MemoryImage(
                                        profileProvider
                                            .cachedImageBytes!,
                                      )
                                          : (imageUrl != null
                                          ? NetworkImage(imageUrl)
                                          : const AssetImage(
                                        "assets/images/avatar.png",
                                      ) as ImageProvider),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    (profile?["designation"] != null &&
                                        profile?["designation"] != "")
                                        ? profile!["designation"]
                                        : "Nhân viên hỗ trợ khách hàng",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 1.3,
                                      wordSpacing: 1.1,
                                      fontSize: isSmallScreen ? 12 : 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).brightness ==
                                      Brightness.light
                                      ? Colors.white60
                                      : Colors.black26,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.transparent,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.notifications_none_rounded,
                                  size: isSmallScreen ? 24 : 26,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const NotificationScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        SizedBox(
                          height: isSmallScreen ? 65 : 75,
                          child: ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: monthDates.length,
                            itemBuilder: (context, index) {
                              DateTime date = monthDates[index];
                              bool isToday =
                                  date.day == today.day &&
                                      date.month == today.month &&
                                      date.year == today.year;

                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 6 : 8,
                                ),
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 12 : 15,
                                          horizontal: isSmallScreen ? 18 : 23,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? Colors.blue
                                              : Colors.grey[200],
                                          borderRadius:
                                          BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              DateFormat("dd").format(date),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isToday
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize:
                                                isSmallScreen ? 14 : 16,
                                              ),
                                            ),
                                            Text(
                                              DateFormat("EEE").format(date),
                                              style: TextStyle(
                                                color: isToday
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize:
                                                isSmallScreen ? 12 : 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.zero,
                    width: double.infinity,
                    height: 605,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff202327) : const Color(0xffffffff),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Điểm danh hôm nay",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              double gridHeight =
                              constraints.maxWidth > 600 ? 350 : 280;
                              return SizedBox(
                                height: gridHeight,
                                child: GridView.count(
                                  crossAxisCount:
                                  constraints.maxWidth > 600 ? 4 : 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio:
                                  constraints.maxWidth > 600 ? 0.9 : 1.3,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    attendanceCard(
                                      "Vào",
                                      (formattedCheckInTime.isNotEmpty)
                                          ? formattedCheckInTime
                                          : "-- : --",
                                      isOnTime ? "Đúng giờ" : "Vào muộn",
                                      Icons.login,
                                      isDark,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                    attendanceCard(
                                      "Ra",
                                      (formattedCheckOutTime.isNotEmpty)
                                          ? formattedCheckOutTime
                                          : "-- : --",
                                      "Về nhà",
                                      Icons.logout,
                                      isDark,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                    attendanceCard(
                                      "Thời gian nghỉ",
                                      breakTime,
                                      "Trung bình $avgBreakTime",
                                      Icons.timer,
                                      isDark,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                    attendanceCard(
                                      "Tổng ngày",
                                      "$workingDaysCount",
                                      "Ngày làm việc",
                                      Icons.calendar_today,
                                      isDark,
                                      isSmallScreen: isSmallScreen,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Hoạt động của bạn",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  print("View All");
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const ActivityPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Xem tất cả",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff2e79e3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          Consumer<DatabaseHelperProvider>(
                            builder: (ctx, provider, __) {
                              if (provider.isLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              // Prefer API data; fall back to provider data
                              final activityList = _apiActivityList.isNotEmpty
                                  ? _apiActivityList
                                  : provider.attendance ?? [];

                              if (activityList.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Text(
                                      'Không có hoạt động điểm danh nào.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                );
                              }

                              return SizedBox(
                                height: size.height * 0.08,
                                child: ListView.builder(
                                  itemCount: activityList.length,
                                  itemBuilder: (context, index) {
                                    final event = activityList[index];
                                    // For API records, format time field
                                    String timeDisplay = '';
                                    final rawTime = event['time']?.toString()
                                        ?? event['systemtime']?.toString() ?? '';
                                    if (rawTime.isNotEmpty) {
                                      try {
                                        timeDisplay = DateFormat.jm()
                                            .format(DateTime.parse(rawTime).toLocal());
                                      } catch (_) {
                                        timeDisplay = rawTime;
                                      }
                                    }
                                    return Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: isSmallScreen ? 6 : 12,
                                      ),
                                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xCC000000),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0x1A2196F3),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              event['icon'] as IconData? ?? Icons.fingerprint,
                                              color: Colors.blue,
                                              size: isSmallScreen ? 18 : 24,
                                            ),
                                          ),
                                          SizedBox(width: isSmallScreen ? 8 : 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  event['title']?.toString() ?? event['cbnv']?.toString() ?? 'Điểm danh',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  event['date']?.toString() ?? '',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: isSmallScreen ? 10 : 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                timeDisplay.isNotEmpty
                                                    ? timeDisplay
                                                    : (event['time']?.toString() ?? '--:--'),
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 14 : 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                event['status']?.toString()
                                                    ?? event['lydodiemdanhho']?.toString()
                                                    ?? 'Bình thường',
                                                style: TextStyle(
                                                  color: Colors.greenAccent,
                                                  fontSize: isSmallScreen ? 10 : 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 5),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 0 : 20,
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                                child: SwipeableButtonView(
                                  buttonText: context
                                      .read<AttendanceProvider>()
                                      .isCheckedIn
                                      ? "Vuốt để ra"
                                      : "Vuốt để vào",
                                  buttonWidget: AnimatedSwitcher(
                                    duration:
                                    const Duration(milliseconds: 250),
                                    child: Icon(
                                      CupertinoIcons.chevron_forward,
                                      key: ValueKey(
                                        context
                                            .read<AttendanceProvider>()
                                            .isCheckedIn,
                                      ),
                                      color: Colors.blue,
                                    ),
                                  ),
                                  activeColor: context
                                      .read<AttendanceProvider>()
                                      .isCheckedIn
                                      ? Colors.redAccent
                                      : const Color(0xff4390fd),
                                  isFinished: isFinished,
                                  onWaitingProcess: () {
                                    setState(() {
                                      isFinished = true;
                                    });
                                  },
                                  onFinish: () async {
                                    if (!context
                                        .read<AttendanceProvider>()
                                        .isCheckedIn) {
                                      checkIn();
                                    } else {
                                      await HelperFunction()
                                          .handleCheckOut(context);
                                    }

                                    setState(() {
                                      isFinished = false;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}