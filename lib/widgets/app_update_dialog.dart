import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import '../services/app_update_service.dart';

class AppUpdateWidget extends StatefulWidget {
  final Widget child;

  const AppUpdateWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppUpdateWidget> createState() => _AppUpdateWidgetState();
}

class _AppUpdateWidgetState extends State<AppUpdateWidget> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    // Kiểm tra cập nhật Android
    await AppUpdateService().checkAndroidUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
        debugLogging: false,
        languageCode: 'vi',
        minAppVersion: '1.0.0',
        showOnlyMandatoryUpdates: false,
      ),
      child: widget.child,
    );
  }
}
