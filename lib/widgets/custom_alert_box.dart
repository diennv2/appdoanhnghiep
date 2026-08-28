import 'dart:convert';
import 'package:flutter/material.dart';

import '../pages/admin_dashboard.dart';
import '../pages/user_main_page.dart';
import 'custom_snackbar.dart';

class CustomAlertBox {
  Future<void> showCustomAnimatedAlert({
    required BuildContext context,
    required String title,
    required String label,
    Map<String, dynamic>? user,
  }) async {
    if (!context.mounted) return;

    final permissions = _extractPermissionCodes(
      user?['permissions'] ?? user?['permission'],
    );

    final isManager = permissions.any(
          (p) => p == 'cbnv/manageall' || p == 'cbnv/update',
    );

    CustomSnackbar.show(
      context: context,
      title: title,
      label: label,
      color: const Color(0xE04CAF50),
      svgColor: const Color(0xE0178327),
    );

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => isManager
            ? AdminDashboard(user: user ?? {})
            : UserMainPage(user: user ?? {}),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
          (route) => false,
    );
  }

  List<String> _extractPermissionCodes(dynamic value) {
    if (value is List) {
      return value
          .map(_permissionCodeFromItem)
          .where((item) => item.isNotEmpty)
          .map((item) => item.toLowerCase().trim())
          .toList();
    }

    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded
              .map(_permissionCodeFromItem)
              .where((item) => item.isNotEmpty)
              .map((item) => item.toLowerCase().trim())
              .toList();
        }
      } catch (_) {}
    }

    return [];
  }

  String _permissionCodeFromItem(dynamic item) {
    if (item is Map && item['permission'] != null) {
      return item['permission'].toString();
    }
    return item?.toString() ?? '';
  }
}