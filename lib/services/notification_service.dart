import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:attendee/pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../model/app_notification_model.dart';
import '../provider/notification_provider.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin localPlugin = FlutterLocalNotificationsPlugin();

  ///Initialization of everything
  Future<void> initNotificationService(BuildContext context) async {
    await Firebase.initializeApp();
    await requestUserPermission();
    if(context.mounted){
      await localNotificationInit(context);
    }
    if(context.mounted){
      firebaseInit(context);
      messageInteract(context);
    }
  }

  // Request user permissions
  Future<void> requestUserPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print("User Granted Permission");
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) print("Provisional Permission Granted");
    } else {
      ///If user don't give the permission then will open notification setting
      Future.delayed(Duration(seconds: 2), () {
        AppSettings.openAppSettings(type: AppSettingsType.notification);
      });
    }
  }

  // Get device token
  Future<String> getToken() async {
    await requestUserPermission();
    String? token = await messaging.getToken();
    if (kDebugMode) print("Device Token: $token");
    return token!;
  }

  // Initialize local notification
  Future<void> localNotificationInit(BuildContext context) async {
    var android = AndroidInitializationSettings('@mipmap/ic_launcher');
    var ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    var initSettings = InitializationSettings(android: android, iOS: ios);

    await localPlugin.initialize(
      initSettings,
      ///after clicking on notification it will open the app
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Splashscreen()));
      },
    );
  }

  // Firebase foreground notification handling
  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {

      if (Platform.isIOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      showNotification(msg);
    });
  }

  // Handle background and terminated state notifications
  Future<void> messageInteract(BuildContext context) async {
    // When the app is opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {

      if(context.mounted){
        handleMsg(context, msg);
      }

    });

    // When the app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? msg) {
      if (msg != null && msg.data.isNotEmpty && context.mounted) {
        handleMsg(context, msg);
      }
    });
  }

  // Handle message click
  Future<void> handleMsg(BuildContext context, RemoteMessage msg) async {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Splashscreen()));
  }

  // Show local notification
  Future<void> showNotification(RemoteMessage msg) async {
    String channelId = msg.notification?.android?.channelId ?? 'default_channel';
    String channelName = 'High Importance Notifications';

    // Create channel
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.high,
      playSound: true,
      showBadge: true,
    );

    await localPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Android notification details
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    // iOS notification details
    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combine both platform notification details
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await localPlugin.show(
      0,
      msg.notification?.title,
      msg.notification?.body,
      notificationDetails,
      payload: 'Demo Payload',
    );
  }








  // Custom method to show manual local notifications
  Future<void> showManualNotification({
    required String title,
    required String body,
    required NotificationProvider provider,
  }) async {

    provider.addNotification(AppNotification(
      title: title,
      body: body,
      timestamp: DateTime.now(),
    ));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'manual_channel',
      'Manual Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: 'manual_payload',
    );
  }












}
