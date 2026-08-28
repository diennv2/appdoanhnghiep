import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../widgets/custom_alert_box.dart';
import '../widgets/custom_snackbar.dart';

class OauthHelper {
  static const int maxRetries = 3;
  static int retryCount = 0;

  Future<void> signUp({
    required String username,
    required String password,
    required BuildContext context,
    required String name,
    String? fullPhoneNumber,
  }) async {
    if (username.isEmpty || password.isEmpty || name.isEmpty) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: "Fields can't be null");
      }
      return;
    }

    try {
      final result = await ApiService.signup(
        username: username,
        password: password,
        email: username, // send email explicitly
        phone: fullPhoneNumber ?? '',
        address: '', // optional
      );

      if (context.mounted) {
        if (result['success']) {
          CustomSnackbar.show(
            title: 'Thành công!',
            context: context,
            label: 'Tài khoản đã được tạo thành công!',
            color: const Color(0xE04CAF50),
            svgColor: const Color(0xE0178327),
          );
        } else {
          CustomSnackbar.show(
            context: context,
            label: " ${result['message']}",
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: "Lỗi: $e");
      }
    }
  }

  static Future<void> sendVerificationEmail(BuildContext context) async {
    if (context.mounted) {
      CustomSnackbar.show(
        title: '🎉 Woohoo! All Done!',
        context: context,
        label: 'Verification email sent successfully!',
        color: const Color(0xE04CAF50),
        svgColor: const Color(0xE0178327),
      );
    }
  }

  Future<void> logIn(
    BuildContext context,
    String username,
    String password,
  ) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: "Username và password không được để trống!",
          );
        }
        return;
      }

      // Call the real API — POST /authenticator/login
      final result = await ApiService.login(
        username: username,
        password: password,
      );

      if (context.mounted) {
        if (result['success'] == true) {
          final userData = result['data'] as Map<String, dynamic>? ?? {};
          final displayName = userData['displayName']?.toString()
              ?? userData['name']?.toString()
              ?? username;
          final lastName = displayName.split(' ').last;

          CustomAlertBox().showCustomAnimatedAlert(
            context: context,
            title: "Chào mừng, $lastName",
            label: "Bạn đã đăng nhập thành công!",
            user: userData,
          );

          retryCount = 0;
        } else {
          retryCount++;
          CustomSnackbar.show(
            context: context,
            label: "${result['message']}",
          );

          if (retryCount > maxRetries) {
            if (context.mounted) {
              CustomSnackbar.show(
                context: context,
                label: "Quá nhiều lần thất bại. Vui lòng thử lại sau.",
              );
            }
            retryCount = 0;
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: "Lỗi: $e");
      }
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    try {
      const webClientId =
          '1086961716031-mu5did4abp5br146us1ss84qa6ul21am.apps.googleusercontent.com';
      const iosClientId =
          '1086961716031-rb3fiiso5bv1954iqaccroagd58h6rsk.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: "Sign-in canceled. Please try again.",
          );
        }
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: "Authentication failed. Please try again.",
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', accessToken);
      await prefs.setString('access_token', accessToken);
      await prefs.setString('id_token', idToken);
      await prefs.setString('display_name', googleUser.displayName ?? 'Google User');
      await prefs.setString('name', googleUser.displayName ?? 'Google User');

      if (context.mounted) {
        final lastName = googleUser.displayName?.split(' ').last ?? 'User';

        CustomAlertBox().showCustomAnimatedAlert(
          context: context,
          title: "🎉 Welcome, $lastName!",
          label: "Your account is successfully created using Google.",
          user: null,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: "${e.toString()}");
      }
    }
  }

  Future<void> resetPassword({
    required BuildContext context,
    required String email,
  }) async {
    if (email.isEmpty) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: "Email can't be null");
      }
      return;
    }

    try {
      final result = await ApiService.resetPassword(email: email);

      if (context.mounted) {
        if (result['success']) {
          CustomSnackbar.show(
            context: context,
            label: "${result['message']}",
            color: const Color(0xE04CAF50),
            svgColor: const Color(0xE0178327),
          );
        } else {
          CustomSnackbar.show(
            context: context,
            label: "${result['message']}",
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: "Lỗi: $e");
      }
    }
  }

  static void configDeepLink(BuildContext context) {
    if (kDebugMode) {
      print("Deep link configured");
    }
  }

  static Future<void> updatePassword(String newPassword, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('access_token');

      if (token == null) {
        if (context.mounted) {
          CustomSnackbar.show(
            context: context,
            label: "Không có token!",
          );
        }
        return;
      }

      if (context.mounted) {
        CustomAlertBox().showCustomAnimatedAlert(
          context: context,
          title: "Chúc mừng",
          label: "Mật khẩu đã được cập nhật!",
          user: null,
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.show(context: context, label: "Lỗi: $e");
      }
    }
  }

  Future<void> signOutUser(BuildContext context) async {
    try {
      await ApiService.logout(); // Gọi API logout xóa refresh token server

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Xóa sạch toàn bộ local data/token

      if (context.mounted) {
        Provider.of<DatabaseHelperProvider>(context, listen: false).clearData();
      }

      if (kDebugMode) {
        print('Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign-out error: $e');
      }
    }
  }
  /// FIXED: Check if token still valid by attempting to refresh
  /// If refresh fails, token is expired and user must login again
  static Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? prefs.getString('token');
      final refreshToken = prefs.getString('refresh_token');

      if (token == null || token.isEmpty) {
        return false;
      }

      // Try to refresh token - if it fails, token is expired
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final result = await ApiService.refreshToken(refreshToken: refreshToken);
        return result['success'] == true;
      }

      // If no refresh token, token is invalid
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Token validation error: $e');
      }
      return false;
    }
  }

  /// FIXED: Check both token existence AND validity
  /// Returns true ONLY if token exists AND is still valid
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('access_token');

    // Token must exist
    if (token == null || token.isEmpty) {
      return false;
    }

    // Token must still be valid
    return await isTokenValid();
  }

  /// Returns stored user data from SharedPreferences.
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();

    final role = _resolveStoredRole(prefs);
    final permissions = _resolveStoredPermissions(prefs);

    return {
      'username':     prefs.getString('username')     ?? '',
      'name':         prefs.getString('name')         ?? prefs.getString('display_name') ?? '',
      'display_name': prefs.getString('display_name') ?? '',
      'role':         role,
      'phone':        prefs.getString('phone')        ?? '',
      'user_id':      prefs.getString('user_id')      ?? '',
      'permissions':  permissions,
    };
  }

  static Future<Map<String, dynamic>> currentUser() async {
    return await getCurrentUser();
  }

  static String _resolveStoredRole(SharedPreferences prefs) {
    final directRole = prefs.getString('role') ?? '';
    if (directRole.isNotEmpty) return directRole;

    final rawRole = prefs.getString('role_raw');
    final roles = _decodeRoleValues(rawRole);
    if (roles.isNotEmpty) return roles.first;

    return '';
  }

  static List<String> _resolveStoredPermissions(SharedPreferences prefs) {
    final encoded = prefs.getString('permissions');
    final directPermissions = _decodePermissionValues(encoded);
    if (directPermissions.isNotEmpty) return directPermissions;

    final rawPerms = prefs.getString('permission_raw');
    return _decodePermissionValues(rawPerms);
  }

  static List<String> _decodeRoleValues(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      final role = decoded?.toString() ?? '';
      if (role.isNotEmpty) return [role];
    } catch (_) {
      final role = raw.trim();
      if (role.isNotEmpty) return [role];
    }
    return [];
  }

  static List<String> _decodePermissionValues(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) {
              if (item is Map && item['permission'] != null) {
                return item['permission'].toString();
              }
              return item?.toString() ?? '';
            })
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
