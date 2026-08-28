import 'dart:async';
import 'dart:ui';
import 'package:attendee/auth/supabase_auth.dart';
import 'package:attendee/widgets/custom_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../services/api_service.dart';

class BreakManagementPage extends StatefulWidget {
  const BreakManagementPage({super.key});

  @override
  State<BreakManagementPage> createState() => _BreakManagementPageState();
}

class _BreakManagementPageState extends State<BreakManagementPage>
    with TickerProviderStateMixin {
  bool _isOnBreak = false;
  late Timer _timer;
  Duration _timeGone = Duration.zero;
  late DateTime _startTime;
  late AnimationController _animationController;
  Map<String, dynamic>? todayData;
  int breakCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.90,
      upperBound: 1.05,
    );
    _restoreBreakState();
  }

  Future<void> _restoreBreakState() async {
    final prefs = await SharedPreferences.getInstance();
    final isOnBreak = prefs.getBool('isOnBreak') ?? false;
    final startTimeMillis = prefs.getInt('breakStartTime');

    if (isOnBreak && startTimeMillis != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
      _timeGone = DateTime.now().difference(_startTime);
      _startTimer();
      _animationController.repeat(reverse: true);

      setState(() {
        _isOnBreak = true;
      });
    }
  }

  Future<void> _startBreak() async {
    final prefs = await SharedPreferences.getInstance();
    _startTime = DateTime.now();
    await prefs.setBool('isOnBreak', true);
    await prefs.setInt('breakStartTime', _startTime.millisecondsSinceEpoch);
    breakCount++;

    _timeGone = Duration.zero;
    _startTimer();
    _animationController.repeat(reverse: true);

    setState(() {
      _isOnBreak = true;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _timeGone = DateTime.now().difference(_startTime);
      });
    });
  }

  Future<void> _endBreak() async {
    final confirm = await CustomAlertBox.showBreakEndConfirmation(
      context: context,
      title: "End Break?",
      label: "Are you sure you want to end your break?",
    );

    if (!confirm) return;

    _timer.cancel();
    _animationController.stop();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isOnBreak');
    await prefs.remove('breakStartTime');

    final totalBreak = _formatDuration(_timeGone);

    final today = DateTime.now().toUtc();
    final todayDate = DateFormat('yyyy-MM-dd').format(today);

    if (mounted) {
      await Provider.of<DatabaseHelperProvider>(
        context,
        listen: false,
      ).fetchUserAttendanceByDate(todayDate);
      if (mounted) {
        todayData =
            Provider.of<DatabaseHelperProvider>(
              context,
              listen: false,
            ).todayAttendance;
      }
    }

    int breakTime = (todayData?["totalBreakTime"] ?? 0) + _timeGone.inSeconds;
    int breakcnt = (todayData?["breakCount"] ?? 0) + breakCount;

    print("breaktime new $breakTime");
    final currUser = await OauthHelper.getCurrentUser();
    final userId = currUser['user_id'];

    if (todayData != null) {
      await ApiService.updateBreakCount(
        userId: userId,
        breakCount: breakcnt,
        breakTime: breakTime,
        date: todayDate,
      );

      print("Data Updated");
    } else {
      await ApiService.insertAttendanceData(
        userId: userId,
        date: todayDate,
        totalBreakTime: breakTime,
        breakCount: breakcnt,
      );
    }

    if (mounted) {
      CustomSnackbar.show(
        context: context,
        label: "You were on Break for $totalBreak",
        color: const Color(0xE04CAF50),
        svgColor: const Color(0xE0178327),
      );
    }

    setState(() {
      _isOnBreak = false;
      _timeGone = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    if (_isOnBreak) {
      _timer.cancel();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Break Time'),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isOnBreak ? _buildBreakView() : _buildStartView(),
        ),
      ),
    );
  }

  Widget _buildStartView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.coffee, size: 100, color: Color(0xFF6F4E37)),
        const SizedBox(height: 30),
        const Text(
          'Need a Break?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _startBreak,
          icon: const Icon(
            CupertinoIcons.play_circle,
            size: 35,
            color: Colors.white,
          ),
          label: const Text(
            'Start Break',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3085FE),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          CupertinoIcons.timelapse,
          size: 100,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 30),
        ScaleTransition(
          scale: _animationController,
          child: Text(
            _formatDuration(_timeGone),
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _endBreak,
          icon: const Icon(Icons.stop, color: Colors.white, size: 32),
          label: const Text(
            'End Break',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomAlertBox {
  static Future<bool> showBreakEndConfirmation({
    required BuildContext context,
    required String title,
    required String label,
  }) async {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 400;

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      barrierLabel: "Break End Confirmation",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color:
                Theme.of(context).brightness == Brightness.light
                    ? const Color(0x4D000000)
                    : const Color(0x66FFFFFF),
              ),
            ),
            Center(
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: size.width * 0.8,
                  padding: EdgeInsets.all(size.width * 0.05),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.question_mark_rounded,
                          size: 80,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 18,
                            color:
                            Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF4A4A4E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'End Break',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1.0).animate(anim1),
            child: child,
          ),
        );
      },
    );

    return result ?? false;
  }
}