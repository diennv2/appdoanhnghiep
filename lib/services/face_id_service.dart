import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class FaceIDService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Kiểm tra thiết bị có hỗ trợ nhận diện khuôn mặt
  static Future<bool> canAuthenticateWithBiometrics() async {
    try {
      bool canAuthenticate = await _localAuth.canCheckBiometrics;
      return canAuthenticate;
    } catch (e) {
      print('Lỗi kiểm tra hỗ trợ sinh trắc học: $e');
      return false;
    }
  }

  /// Lấy danh sách các phương thức xác thực có sẵn
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Lỗi lấy danh sách sinh trắc học: $e');
      return [];
    }
  }

  /// Kiểm tra có hỗ trợ nhận diện khuôn mặt không
  static Future<bool> supportsFaceRecognition() async {
    try {
      List<BiometricType> biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.face);
    } catch (e) {
      print('Lỗi kiểm tra nhận diện khuôn mặt: $e');
      return false;
    }
  }

  /// Xác thực bằng FaceID
  static Future<bool> authenticateWithFaceID({
    String reason = 'Vui lòng xác thực bằng khuôn mặt của bạn',
  }) async {
    try {
      bool isFaceAvailable = await supportsFaceRecognition();
      if (!isFaceAvailable) {
        throw Exception('Thiết bị không hỗ trợ nhận diện khuôn mặt');
      }

      bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );

      return isAuthenticated;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        print('Lỗi: Sinh trắc học không khả dụng');
      } else if (e.code == 'NotEnrolled') {
        print('Lỗi: Chưa đăng ký dữ liệu sinh trắc học');
      } else if (e.code == 'LockedOut') {
        print('Lỗi: Tài khoản bị khóa tạm thời');
      } else if (e.code == 'PermanentlyLockedOut') {
        print('Lỗi: Tài khoản bị khóa vĩnh viễn');
      } else {
        print('Lỗi xác thực FaceID: ${e.message}');
      }
      return false;
    } catch (e) {
      print('Lỗi không xác định: $e');
      return false;
    }
  }

  /// Xác thực bằng sinh trắc học (FaceID, Fingerprint, hoặc Iris)
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Vui lòng xác thực danh tính của bạn',
  }) async {
    try {
      bool canAuthenticate = await canAuthenticateWithBiometrics();
      if (!canAuthenticate) {
        throw Exception('Thiết bị không hỗ trợ xác thực sinh trắc học');
      }

      bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
      );

      return isAuthenticated;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        print('Lỗi: Sinh trắc học không khả dụng');
      } else if (e.code == 'NotEnrolled') {
        print('Lỗi: Chưa đăng ký dữ liệu sinh trắc học');
      } else if (e.code == 'LockedOut') {
        print('Lỗi: Tài khoản bị khóa tạm thời');
      } else if (e.code == 'PermanentlyLockedOut') {
        print('Lỗi: Tài khoản bị khóa vĩnh viễn');
      } else {
        print('Lỗi xác thực sinh trắc học: ${e.message}');
      }
      return false;
    } catch (e) {
      print('Lỗi không xác định: $e');
      return false;
    }
  }

  /// Ghi lại chấm công bằng FaceID
  static Map<String, dynamic> recordFaceIDAttendance(
      String employeeId,
      bool authenticationSuccess,
      ) {
    return {
      'employee_id': employeeId,
      'authentication_success': authenticationSuccess,
      'authentication_method': 'FaceID',
      'attendance_time': DateTime.now().toIso8601String(),
      'method': 'FACEID',
    };
  }

  /// Xác thực chấm công với FaceID và thông tin bổ sung
  static Future<Map<String, dynamic>?> authenticateAttendance(
      String employeeId, {
        String reason = 'Vui lòng xác thực để chấm công',
      }) async {
    try {
      bool isAuthenticated = await authenticateWithFaceID(reason: reason);

      if (isAuthenticated) {
        return {
          'success': true,
          'employee_id': employeeId,
          'method': 'FACEID',
          'timestamp': DateTime.now().toIso8601String(),
          'message': 'Xác thực thành công',
        };
      } else {
        return {
          'success': false,
          'employee_id': employeeId,
          'method': 'FACEID',
          'timestamp': DateTime.now().toIso8601String(),
          'message': 'Xác thực thất bại',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'employee_id': employeeId,
        'method': 'FACEID',
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Lỗi xác thực: $e',
      };
    }
  }

  /// Dừng xác thực (nếu cần)
  static Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      print('Lỗi dừng xác thực: $e');
    }
  }
}
