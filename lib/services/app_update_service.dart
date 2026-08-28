import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();

  factory AppUpdateService() {
    return _instance;
  }

  AppUpdateService._internal();

  /// Kiểm tra cập nhật cho Android (In-App Update)
  Future<void> checkAndroidUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      await InAppUpdate.checkForUpdate().then((updateInfo) {
        if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
          _showAndroidUpdateDialog(updateInfo);
        }
      }).catchError((e) {
        print('Error checking Android update: $e');
      });
    } catch (e) {
      print('Android update check failed: $e');
    }
  }

  /// Hiển thị dialog cập nhật cho Android
  void _showAndroidUpdateDialog(AppUpdateInfo updateInfo) {
    try {
      // Prioritize immediate update if available
      if (updateInfo.immediateUpdateAllowed) {
        InAppUpdate.performImmediateUpdate().catchError((e) {
          print('Error starting immediate update: $e');
        });
      }
      // Otherwise, try flexible update
      else if (updateInfo.flexibleUpdateAllowed) {
        InAppUpdate.startFlexibleUpdate().then((_) {
          // Sau khi tải xong, hoàn thành cập nhật
          completeFlexibleUpdate();
        }).catchError((e) {
          print('Error starting flexible update: $e');
        });
      }
    } catch (e) {
      print('Error showing update dialog: $e');
    }
  }

  /// Hoàn thành cập nhật linh hoạt (sau khi tải xuống)
  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      print('Error completing flexible update: $e');
    }
  }

  /// Lấy thông tin phiên bản hiện tại
  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }
}
