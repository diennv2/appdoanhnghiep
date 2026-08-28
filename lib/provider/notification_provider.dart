import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/app_notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<AppNotification> get notifications => _notifications.reversed.toList();

  static const String _getNotification = 'notifications';

  Future<void> init() async {
    if (_isInitialized) return;
    await _loadFromPrefs();
    _isInitialized = true;
  }

  Future<void> addNotification(AppNotification notification) async {
    _setLoading(true);
    _notifications.add(notification);
    await _saveToPrefs();
    _setLoading(false);
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    _setLoading(true);
    _notifications.clear();
    await _saveToPrefs();
    _setLoading(false);
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_getNotification, jsonList);
    } catch (e) {
      print('Error saving notifications: $e');

    }
  }

  Future<void> _loadFromPrefs() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_getNotification);

      if (jsonList != null) {
        _notifications.clear();
        for (final item in jsonList) {
          try {
            final notification = AppNotification.fromJson(jsonDecode(item));
            _notifications.add(notification);
          } catch (e) {
            debugPrint('Error parsing notification item: $e');
          }
        }
      } else {
        debugPrint('No notifications found in storage');
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }


  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}