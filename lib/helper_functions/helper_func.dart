import 'package:attendee/auth/supabase_auth.dart';
import 'package:attendee/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../geolocation/location_helper.dart';
import '../provider/attendance_provider.dart';
import '../provider/notification_provider.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class HelperFunction {
  static const double allowedDistance = 100;
  int breakCount = 0;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 1));
  }

  Future<void> handleCheckIn(BuildContext context) async {
    if (!context.mounted) return;

    final dbProvider = Provider.of<DatabaseHelperProvider>(
      context,
      listen: false,
    );
    final profile = dbProvider.profile;
    final officelatitude = profile?["latitude"];
    final officelongitude = profile?["longitude"];
    final currUser = await OauthHelper.getCurrentUser();
    final userId = currUser['user_id'];
    final today = DateTime.now().toUtc();

    print(
      "officelatitude $officelatitude and officelongitude $officelongitude",
    );

    final startTime = profile?["start_time"];
    final endTime = profile?["end_time"];

    if (startTime == null &&
        endTime == null &&
        officelatitude == null &&
        officelongitude == null) {
      CustomSnackbar.show(
        context: context,
        label: "To Access this Feature Please Complete Your Profile",
      );
      return;
    }

    if (startTime == null && endTime == null) {
      CustomSnackbar.show(
        context: context,
        label: "To Access this Feature Please Complete Your Profile",
      );
      return;
    }
    if (officelatitude == null && officelongitude == null) {
      CustomSnackbar.show(
        context: context,
        label: "To Access this Feature Please Complete Your Profile",
      );
      return;
    }

    try {
      if (officelatitude != null && officelongitude != null) {
        final position = await LocationHelper().getCurrentPosition(context);
        if (position != null) {
          double distance = LocationHelper.distanceBetween(
            officelatitude,
            officelongitude,
            position.latitude,
            position.longitude,
          );

          print("your current location is $position");

          if (distance > allowedDistance) {
            if (context.mounted) {
              CustomSnackbar.show(
                context: context,
                label: "You are not inside office!",
              );
            }
            print("from office your distance is $distance");
            return;
          }
        }
      }

      final lastAttendance = await ApiService.getLastAttendance(userId);

      if (lastAttendance != null) {
        if (lastAttendance['check_in_time'] != null) {
          DateTime lastCheckIn = DateTime.parse(lastAttendance['check_in_time']);
          final hoursSinceLastCheckIn =
              DateTime.now().difference(lastCheckIn).inHours;

          if (hoursSinceLastCheckIn < 15) {
            if (context.mounted) {
              CustomSnackbar.show(
                context: context,
                label:
                "You can only check-in after 16 hours from your last check-in!",
              );
            }
            print("You are too early to office ! time not yet");
            return;
          }
        } else {
          print("Last check-in time is NULL, skipping 16-hour check.");
        }
      }

      final todayDateString = DateFormat('yyyy-MM-dd').format(today);
      final timeNow = DateFormat('hh:mm a').format(today.toLocal());

      final rowCheckedIn = await ApiService.getTodayAttendance(userId);

      final hasCheckedInToday = rowCheckedIn.any((record) {
        final checkInTime = record['check_in_time'];
        if (checkInTime == null) {
          return false;
        }
        final checkInDate = DateFormat('yyyy-MM-dd').format(
          DateTime.parse(checkInTime).toUtc(),
        );
        return checkInDate == todayDateString;
      });

      if (hasCheckedInToday) {
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: "You've already checked in today!",
          );
          print("already office");
        }
        return;
      } else {
        final checkInResult = await ApiService.checkIn(
          userId: userId,
          checkInTime: today,
          date: todayDateString,
        );

        if (checkInResult['success']) {
          if (context.mounted) {
            final response =
                Provider.of<DatabaseHelperProvider>(
                  context,
                  listen: false,
                ).todayAttendance;

            Provider.of<AttendanceProvider>(
              context,
              listen: false,
            ).checkIn(response?['id'], today);

            Provider.of<AttendanceProvider>(
              context,
              listen: false,
            ).setCheckedIn(true);

            final provider = Provider.of<NotificationProvider>(context, listen: false);

            NotificationServices().showManualNotification(
              title: "Attendance Alert 🚨",
              body: "You Checked in office at $timeNow",
              provider: provider,
            );

            CustomSnackbar.show(
              context: context,
              title: "You're In! ✅",
              label: "Checked in successfully!",
              color: const Color(0xE04CAF50),
              svgColor: const Color(0xE0178327),
            );

            trackUser(context);
            print("Checked in success you are in office");
          }
        } else {
          if (context.mounted) {
            CustomSnackbar.show(
              context: context,
              label: "❌ ${checkInResult['message']}",
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: 'Error: ${e.toString()}');
        print(e.toString());
        print("Error here");
      }
    }
  }

  Future<void> handleCheckOut(BuildContext context) async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    if (!provider.isCheckedIn) return;

    final currUser = await OauthHelper.getCurrentUser();
    final userId = currUser['user_id'];

    final today = DateTime.now().toUtc();
    final todayDate = DateFormat('yyyy-MM-dd').format(today);
    final timeNow = DateFormat('hh:mm a').format(today.toLocal());

    final checkOutResult = await ApiService.checkOut(
      userId: userId,
      checkOutTime: today,
      date: todayDate,
      breakDuration: provider.totalBreakDuration.inSeconds,
    );

    if (!checkOutResult['success']) {
      return;
    }

    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    NotificationServices().showManualNotification(
      title: "Attendance Alert 🚨",
      body: "You Checkout From office at $timeNow",
      provider: notificationProvider,
    );

    if (context.mounted) {
      Provider.of<AttendanceProvider>(context, listen: false).checkOut();
      Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).setCheckedIn(false);
    }

    if (context.mounted) {
      CustomSnackbar.show(
        context: context,
        title: "See you later! ✅",
        label: "Checked out successfully!",
        color: const Color(0xE04CAF50),
        svgColor: const Color(0xE0178327),
      );

      LocationHelper().stopTracking();
      print("checked out office");
    }
  }

  Future<void> trackUser(BuildContext context) async {
    final dbProvider = Provider.of<DatabaseHelperProvider>(
      context,
      listen: false,
    );
    final provider = Provider.of<AttendanceProvider>(context, listen: false);

    final profile = dbProvider.profile;
    final officelatitude = profile?["latitude"];
    final officelongitude = profile?["longitude"];
    final currUser = await OauthHelper.getCurrentUser();
    final userId = currUser['user_id'];

    DateTime? leftOfficeTime;
    Duration totalBreakTime = Duration.zero;
    bool isOutside = false;
    const double allowedRadius = 100;

    bool locationPermissionGranted = await _isLocationPermissionAllowed(
      context,
    );
    if (!locationPermissionGranted) {
      if (context.mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Location permission denied.',
        );
      }
      return;
    }

    LocationHelper().startTracking(
      onData: (Position pos) async {
        if (officelatitude != null && officelongitude != null) {
          double distance = LocationHelper.distanceBetween(
            officelatitude,
            officelongitude,
            pos.latitude,
            pos.longitude,
          );

          if (provider.isCheckedIn) {
            if (distance > allowedRadius) {
              breakCount++;
              if (!isOutside) {
                isOutside = true;
                leftOfficeTime = DateTime.now();
              } else {
                final minutesOutside =
                    DateTime.now().difference(leftOfficeTime!).inMinutes;
                if (minutesOutside >= 10) {
                  final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

                  NotificationServices().showManualNotification(
                    title: "Attendance Alert 🚨",
                    body: "You're out of office! Please check out.",
                    provider: notificationProvider,
                  );

                  if (context.mounted) {
                    CustomSnackbar.show(
                      context: context,
                      label: "You're out of office! Please check out.",
                    );
                  }
                }
              }
            } else {
              if (isOutside && leftOfficeTime != null) {
                Duration breakDuration = DateTime.now().difference(
                  leftOfficeTime!,
                );

                totalBreakTime += breakDuration;

                final today = DateTime.now().toUtc();
                final todayDate = DateFormat('yyyy-MM-dd').format(today);

                final todayData = await ApiService.getTodayAttendanceData(
                  userId,
                  todayDate,
                );

                int breakTime =
                    (todayData?["totalBreakTime"] ?? 0) +
                        totalBreakTime.inSeconds;
                int breakcnt = (todayData?["breakCount"] ?? 0) + breakCount;

                if (todayData != null) {
                  await ApiService.updateBreakCount(
                    userId: userId,
                    breakCount: breakcnt,
                    breakTime: breakTime,
                    date: todayDate,
                  );

                  print("Data Updated with response");
                } else {
                  await ApiService.insertAttendanceData(
                    userId: userId,
                    date: todayDate,
                    totalBreakTime: breakTime,
                    breakCount: breakcnt,
                  );
                }

                print("Break Duration: ${breakDuration.inMinutes} min");
                print(
                  "Total Break Time Today: ${totalBreakTime.inMinutes} min",
                );

                leftOfficeTime = null;
                isOutside = false;
              }
            }
          }
        }
      },
      onServiceStatus: (ServiceStatus status) {
        if (status == ServiceStatus.disabled) {
          _isLocationPermissionAllowed(context);
        }
      },
    );
  }

  Future<bool> _isServiceEnable() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      Geolocator.openLocationSettings();
      return false;
    } else {
      return true;
    }
  }

  Future<bool> _isLocationPermissionAllowed(BuildContext context) async {
    if (await _isServiceEnable()) {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            CustomSnackbar.show(
              context: context,
              label: 'Can\'t retrieve location—permission required.',
            );
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: 'Location permanently denied',
            actionLabel: 'Settings',
            onAction: Geolocator.openAppSettings,
          );
        }
        return false;
      }

      return true;
    }
    return false;
  }
}