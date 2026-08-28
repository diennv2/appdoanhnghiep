import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'dio_service.dart';

class ApiService {
  static final Dio _dio = DioService().dio;

  // ===================== INTERNAL HELPERS =====================

  static bool _isSuccessStatus(dynamic status) {
    if (status is bool) return status;
    if (status is String) {
      final normalized = status.toLowerCase().trim();
      return normalized == 'true' || normalized == '1' || normalized == 'ok';
    }
    if (status is num) return status != 0;
    return false;
  }

  static String _extractMessage(dynamic data, {String fallback = 'Unknown error'}) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message != null) return message.toString();
    }
    return fallback;
  }

  static List<Map<String, dynamic>> _asListMap(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  static Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final role = data['role'];
    final permission = data['permission'];
    final roleList = _extractRoleValues(role);
    final permissionList = _extractPermissionValues(permission);

    final roleValue = roleList.isNotEmpty ? roleList.first : '';

    await prefs.setString('access_token', data['token']?.toString() ?? '');
    await prefs.setString('token', data['token']?.toString() ?? '');
    await prefs.setString('refresh_token', data['refreshToken']?.toString() ?? '');
    await prefs.setString('username', data['username']?.toString() ?? '');
    await prefs.setString('name', data['displayName']?.toString() ?? '');
    await prefs.setString('display_name', data['displayName']?.toString() ?? '');
    await prefs.setString('phone', data['phone']?.toString() ?? '');
    await prefs.setString('user_id', data['userId']?.toString() ?? '');
    await prefs.setString('cbnv_id', data['cbnv_id']?.toString() ?? '');
    await prefs.setString('role', roleValue);
    await prefs.setString('permissions', jsonEncode(permissionList));

    if (role != null) {
      await prefs.setString('role_raw', jsonEncode(role));
    }

    if (permission != null) {
      await prefs.setString('permission_raw', jsonEncode(permission));
    }
  }

  static List<String> _extractRoleValues(dynamic role) {
    if (role is List) {
      return role.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (role != null) {
      final value = role.toString();
      if (value.isNotEmpty) return [value];
    }
    return [];
  }

  static List<String> _extractPermissionValues(dynamic permission) {
    if (permission is List) {
      return permission
          .map((item) {
            if (item is Map && item['permission'] != null) {
              return item['permission'].toString();
            }
            return item?.toString() ?? '';
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [];
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  static Future<String?> getRefreshTokenValue() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('refresh_token');
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null || userId.trim().isEmpty) return null;
    return userId;
  }

  static Options _authOptions(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  // ===================== AUTH - NEW API =====================

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.LOGIN,
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = _asMap(response.data) ?? {};
      final ok = _isSuccessStatus(data['status']);

      if (response.statusCode == 200 && ok) {
        await _saveAuthData(data);
        return {
          'success': true,
          'data': data,
          'message': data['message']?.toString() ?? 'Thành công',
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, fallback: 'Login failed'),
        'data': data,
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Connection error'),
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> refreshToken({
    String? refreshToken,
  }) async {
    try {
      final rf = refreshToken ?? await getRefreshTokenValue();

      if (rf == null || rf.isEmpty) {
        return {
          'success': false,
          'message': 'Refresh token is missing',
        };
      }

      final response = await _dio.post(
        ApiConfig.REFRESH_TOKEN,
        data: {
          'refreshToken': rf,
        },
      );

      final data = _asMap(response.data) ?? {};
      final ok = _isSuccessStatus(data['status']);

      if (response.statusCode == 200 && ok) {
        final prefs = await SharedPreferences.getInstance();
        if (data['token'] != null) {
          await prefs.setString('access_token', data['token'].toString());
        }

        return {
          'success': true,
          'data': data,
          'message': data['message']?.toString() ?? 'Thành công',
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, fallback: 'Refresh token failed'),
        'data': data,
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Connection error'),
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> logout({
    String? refreshToken,
  }) async {
    try {
      final rf = refreshToken ?? await getRefreshTokenValue();

      final response = await _dio.delete(
        ApiConfig.LOGOUT,
        data: {
          'refreshToken': rf ?? '',
        },
      );

      final data = _asMap(response.data) ?? {};

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('display_name');
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('name');
      await prefs.remove('phone');
      await prefs.remove('token');
      await prefs.remove('role');
      await prefs.remove('permissions');
      await prefs.remove('role_raw');
      await prefs.remove('permission_raw');
      await prefs.remove('cbnv_id');

      return {
        'success': response.statusCode == 200 || _isSuccessStatus(data['status']),
        'message': _extractMessage(data, fallback: 'Logged out'),
        'data': data,
      };
    } on DioException catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('display_name');
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('name');
      await prefs.remove('phone');
      await prefs.remove('token');
      await prefs.remove('role');
      await prefs.remove('permissions');
      await prefs.remove('role_raw');
      await prefs.remove('permission_raw');
      await prefs.remove('cbnv_id');

      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Logout failed'),
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getPermission() async {
    try {
      final token = await getAccessToken();
      if (token == null) return [];

      final response = await _dio.post(
        ApiConfig.GET_PERMISSION,
        options: _authOptions(token),
      );

      return _asListMap(response.data);
    } catch (_) {
      return [];
    }
  }

  // ===================== APP SERVICES - NEW API =====================

  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get(ApiConfig.HEALTH_CHECK);
      final data = _asMap(response.data) ?? {};

      return {
        'success': response.statusCode == 200 && _isSuccessStatus(data['status']),
        'data': data,
        'message': _extractMessage(data, fallback: 'OK'),
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Healthcheck failed'),
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Access token missing'};
      }

      final response = await _dio.get(
        ApiConfig.GET_USER_INFO,
        options: _authOptions(token),
      );

      final data = _asMap(response.data) ?? {};
      final ok = _isSuccessStatus(data['status']);

      return {
        'success': response.statusCode == 200 && ok,
        'data': data,
        'userInfo': _asMap(data['userInfo']) ?? {},
        'imageUrl': data['image'],
        'message': _extractMessage(data, fallback: 'OK'),
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Failed to get user info'),
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// NEW API
  /// NOTE: backend expects GET with JSON body.
  static Future<Map<String, dynamic>> getAttendances({
    int? userFilter,
    String? dateFilter,
    int? page,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Access token missing'};
      }

      final response = await _dio.request(
        ApiConfig.GET_ATTENDANCES,
        data: {
          if (userFilter != null) 'userFilter': userFilter,
          if (dateFilter != null && dateFilter.isNotEmpty) 'dateFilter': dateFilter,
          if (page != null) 'page': page,
        },
        options: Options(
          method: 'GET',
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = _asMap(response.data) ?? {};
      return {
        'success': response.statusCode == 200,
        'data': data,
        'dataProvider': _asListMap(data['dataProvider']),
        'count': data['count'] ?? 0,
        'itemPerPage': data['itemPerPage'] ?? 0,
        'currentPage': data['currentPage'] ?? 1,
        'pages': data['pages'] ?? 1,
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Failed to get attendances'),
        'data': data,
        'dataProvider': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'dataProvider': <Map<String, dynamic>>[],
      };
    }
  }
  /// NEW API
  /// NOTE: backend expects GET with JSON body.
  static Future<Map<String, dynamic>> getOwnedAttendances({
    int? userFilter,
    String? dateFilter,
    int? page,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Access token missing'};
      }

      final response = await _dio.request(
        ApiConfig.GET_OWNED_ATTENDANCES,
        data: {
          if (userFilter != null) 'userFilter': userFilter,
          if (dateFilter != null && dateFilter.isNotEmpty) 'dateFilter': dateFilter,
          if (page != null) 'page': page,
        },
        options: Options(
          method: 'GET',
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = _asMap(response.data) ?? {};
      return {
        'success': response.statusCode == 200,
        'data': data,
        'dataProvider': _asListMap(data['dataProvider']),
        'count': data['count'] ?? 0,
        'itemPerPage': data['itemPerPage'] ?? 0,
        'currentPage': data['currentPage'] ?? 1,
        'pages': data['pages'] ?? 1,
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Failed to get owned attendances'),
        'data': data,
        'dataProvider': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'dataProvider': <Map<String, dynamic>>[],
      };
    }
  }

  static Future<Map<String, dynamic>> getBaoCaoTong({
    String? date,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Access token missing'};
      }

      final response = await _dio.post(
        ApiConfig.BAO_CAO_TONG,
        data: {
          if (date != null && date.isNotEmpty) 'date': date,
        },
        options: _authOptions(token),
      );

      final data = _asMap(response.data) ?? {};

      return {
        'success': response.statusCode == 200,
        'data': data,
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Failed to get daily report'),
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getBangChamCong({
    int? thang,
    int? nam,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Access token missing'};
      }

      final response = await _dio.post(
        ApiConfig.BANG_CHAM_CONG,
        data: {
          if (thang != null) 'thang': thang,
          if (nam != null) 'nam': nam,
        },
        options: _authOptions(token),
      );

      final data = _asMap(response.data) ?? {};
      final ok = data.isEmpty ? false : _isSuccessStatus(data['status']);

      return {
        'success': response.statusCode == 200 || ok,
        'data': data,
        'khuvucs': _asListMap(data['khuvucs']),
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Failed to get monthly timesheet'),
        'data': data,
        'khuvucs': <Map<String, dynamic>>[],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'khuvucs': <Map<String, dynamic>>[],
      };
    }
  }
  static Future<Map<String, dynamic>> getBangChamCongCaNhan({
    int? thang,
    int? nam,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      return {'success': false, 'message': 'Access token missing'};
    }

    try {
      final response = await _dio.post(
        ApiConfig.BANG_CHAM_CONG_CA_NHAN,
        data: {
          if (thang != null) 'thang': thang,
          if (nam != null) 'nam': nam,
        },
        options: _authOptions(token),
      );

      final data = response.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(response.data)
          : {};

      return {
        'success': response.statusCode == 200 && (data['status'] == true),
        'data': data,
        'khuvucs': data['khuvucs'] ?? [],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'khuvucs': []};
    }
  }
  // ===================== BACKWARD-COMPAT METHODS =====================
  // These are kept so old code does not fail compile immediately.

  static Future<Map<String, dynamic>?> getLastAttendance(String userId) async {
    try {
      final result = await getOwnedAttendances(page: 1);
      if (result['success'] == true) {
        final list = _asListMap(result['dataProvider']);
        if (list.isNotEmpty) {
          return list.last;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getTodayAttendance(String userId) async {
    try {
      final now = DateTime.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final result = await getOwnedAttendances(
        dateFilter: date,
        page: 1,
      );

      if (result['success'] == true) {
        return _asListMap(result['dataProvider']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getTodayAttendanceData(
      String userId,
      String date,
      ) async {
    try {
      final result = await getOwnedAttendances(
        dateFilter: date,
        page: 1,
      );

      if (result['success'] == true) {
        final list = _asListMap(result['dataProvider']);
        if (list.isNotEmpty) {
          return list.first;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendanceList(
      String userId, {
        String? startDate,
        String? endDate,
      }) async {
    try {
      // Fallback mapping: use owned attendances and prefer startDate as dateFilter.
      final result = await getOwnedAttendances(
        dateFilter: startDate ?? endDate,
        page: 1,
      );

      if (result['success'] == true) {
        return _asListMap(result['dataProvider']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getMonthlyReport(
      String userId,
      String month,
      ) async {
    try {
      final parts = month.split('-');
      int? nam;
      int? thang;

      if (parts.length >= 2) {
        nam = int.tryParse(parts[0]);
        thang = int.tryParse(parts[1]);
      }

      return await getBangChamCong(
        thang: thang,
        nam: nam,
      );
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDailyReport(
      String userId,
      String date,
      ) async {
    return getBaoCaoTong(date: date);
  }

  // ===================== LEGACY / PLACEHOLDER METHODS =====================
  // Kept so old UI/features still compile if backend endpoint is not migrated yet.

  // ===================== AUTH - SIGNUP =====================

  static Future<Map<String, dynamic>> signup({
    required String username,
    required String password,
    required String email,
    String phone = '',
    String address = '',
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.SIGNUP,
        data: {
          'username': username,
          'password': password,
          'email': email,
          'phone': phone,
          // 'address' optional; backend will accept or ignore if empty
          'address': address,
        },
      );

      final data = _asMap(response.data) ?? {};
      // Backend uses 'status' boolean (or similar) — normalize
      final ok = _isSuccessStatus(data['status']);

      if (response.statusCode == 200 && ok) {
        return {
          'success': true,
          'data': data,
          'message': data['message']?.toString() ?? 'Đăng ký thành công',
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, fallback: 'Signup failed'),
        'data': data,
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Connection error'),
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.RESET_PASSWORD,
        data: {
          'email': email,
        },
      );

      return {
        'success': response.statusCode == 200,
        'data': _asMap(response.data) ?? {},
        'message': _extractMessage(response.data, fallback: 'Reset request sent'),
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Reset failed'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    // Map old API name to new user info API
    final result = await getUserInfo();
    return {
      'success': result['success'] == true,
      'data': result['userInfo'] ?? result['data'] ?? {},
      'message': result['message'] ?? '',
    };
  }
  static Future<Map<String, dynamic>> checkIn({
    required String userId,
    required DateTime checkInTime,
    required String date,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.ATTENDANCE_CHECK_IN,
        data: {
          'user_id': userId,
          'check_in_time': checkInTime.toIso8601String(),
          'date': date,
        },
      );

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': _asMap(response.data) ?? {},
        'message': _extractMessage(response.data, fallback: 'Check-in completed'),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> checkOut({
    required String userId,
    required DateTime checkOutTime,
    required String date,
    required int breakDuration,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.ATTENDANCE_CHECK_OUT,
        data: {
          'user_id': userId,
          'check_out_time': checkOutTime.toIso8601String(),
          'date': date,
          'break_duration': breakDuration,
        },
      );

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': _asMap(response.data) ?? {},
        'message': _extractMessage(response.data, fallback: 'Check-out completed'),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateBreakCount({
    required String userId,
    required int breakCount,
    required int breakTime,
    required String date,
  }) async {
    try {
      final response = await _dio.put(
        ApiConfig.ATTENDANCE_BREAK_COUNT,
        data: {
          'user_id': userId,
          'break_count': breakCount,
          'break_time': breakTime,
          'date': date,
        },
      );

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': _asMap(response.data) ?? {},
        'message': _extractMessage(response.data, fallback: 'Break count updated'),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> insertAttendanceData({
    required String userId,
    required String date,
    required int totalBreakTime,
    required int breakCount,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.ATTENDANCE_INSERT,
        data: {
          'user_id': userId,
          'date': date,
          'total_break_time': totalBreakTime,
          'break_count': breakCount,
        },
      );

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': _asMap(response.data) ?? {},
        'message': _extractMessage(response.data, fallback: 'Attendance inserted'),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> trackLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.LOCATION_TRACK,
        data: {
          'user_id': userId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': _asMap(response.data) ?? {},
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await _dio.get(
        ApiConfig.NOTIFICATION_LIST,
        queryParameters: {'user_id': userId},
      );

      final data = _asMap(response.data) ?? {};
      return _asListMap(data['data']);
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(
      String notificationId,
      ) async {
    try {
      final response = await _dio.put(
        ApiConfig.NOTIFICATION_READ,
        data: {'notification_id': notificationId},
      );

      return {
        'success': response.statusCode == 200,
        'data': _asMap(response.data) ?? {},
      };
    } catch (_) {
      return {'success': false};
    }
  }
  /// Upload avatar/profile photo for CBNV (Nhân viên)
  /// [cbnvId]: id của CBNV
  /// [imageBase64]: base64 string (có thể có tiền tố 'data:image/jpeg;base64,...' hoặc chỉ raw base64)
  static Future<Map<String, dynamic>> uploadPhoto({
    required int cbnvId,
    required String imageBase64,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Access token missing'};
      }

      final response = await _dio.post(
        '/api/uploadphoto',
        data: {
          'cbnvid': cbnvId,
          'image': imageBase64,
        },
        options: _authOptions(token),
      );

      final data = _asMap(response.data) ?? {};

      return {
        'success': data['status'] == true,
        'message': data['message'] ?? (data['status'] == true ? 'Upload thành công' : 'Upload thất bại'),
        'imagePath': data['anh'],
        'data': data,
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Lỗi upload'),
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  // Thêm vào class ApiService
  static Future<Map<String, dynamic>> getAttendanceHistory({
    int? userFilter,
    String? dateFilter,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'success': false, 'message': 'No auth token found'};
      }

      final response = await _dio.post(
        ApiConfig.LICH_SU_DIEM_DANH,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: jsonEncode({
          'page': page,
          'itemPerPage': perPage,
          if (userFilter != null) 'user_id': userFilter,
          if (dateFilter != null) 'date': dateFilter,
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['dataProvider'] != null) {
          return {
            'success': true,
            'dataProvider': data['dataProvider'],
            'count': data['count'],
            'currentPage': data['currentPage'],
            'pages': data['pages'],
          };
        }
        return {'success': false, 'message': 'Invalid response format'};
      }
      return {'success': false, 'message': 'API error: ${response.statusCode}'};
    } catch (e) {
      print('Error in getAttendanceHistory: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteAccount({
    required String password,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Access token missing'};
      }

      final response = await _dio.post(
        ApiConfig.DELETE_BY_USERID,
        data: {
          'password': password,
        },
        options: _authOptions(token),
      );

      final data = _asMap(response.data) ?? {};
      final ok = response.statusCode == 200 && _isSuccessStatus(data['status']);

      // Nếu xóa thành công thì dọn local prefs (tương tự logout)
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('display_name');
        await prefs.remove('user_id');
        await prefs.remove('username');
        await prefs.remove('name');
        await prefs.remove('phone');
        await prefs.remove('token');
        await prefs.remove('role');
        await prefs.remove('permissions');
        await prefs.remove('role_raw');
        await prefs.remove('permission_raw');
        await prefs.remove('cbnv_id');
      }

      return {
        'success': ok,
        'message': _extractMessage(data, fallback: data['status'] == true ? 'Tài khoản đã được xóa' : 'Delete failed'),
        'data': data,
      };
    } on DioException catch (e) {
      final data = _asMap(e.response?.data) ?? {};
      return {
        'success': false,
        'message': _extractMessage(data, fallback: e.message ?? 'Delete failed'),
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
