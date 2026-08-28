import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class LocationAttendanceService {
  /// Kiểm tra quyền truy cập vị trí
  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      return result == LocationPermission.whileInUse ||
          result == LocationPermission.always;
    } else if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /// Yêu cầu quyền truy cập vị trí
  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Kiểm tra dịch vụ vị trí có bật không
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Lấy vị trí hiện tại
  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        print('Không có quyền truy cập vị trí');
        return null;
      }

      bool isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) {
        print('Dịch vụ vị trí không được bật');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
        forceAndroidLocationManager: true,
      );

      return position;
    } catch (e) {
      print('Lỗi lấy vị trí: $e');
      return null;
    }
  }

  /// Kiểm tra có ở trong bán kính văn phòng không (sử dụng Haversine formula)
  static Future<bool> isWithinOfficeRadius(
      double officeLatitude,
      double officeLongitude, {
        double radiusMeters = 100,
      }) async {
    try {
      Position? currentPosition = await getCurrentLocation();
      if (currentPosition == null) {
        return false;
      }

      double distance = _calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        officeLatitude,
        officeLongitude,
      );

      print('Khoảng cách từ vị trí hiện tại đến văn phòng: ${distance.toStringAsFixed(2)} mét');
      return distance <= radiusMeters;
    } catch (e) {
      print('Lỗi kiểm tra bán kính: $e');
      return false;
    }
  }

  /// Tính khoảng cách giữa hai điểm (Haversine formula)
  /// Trả về khoảng cách tính bằng mét
  static double _calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const earthRadiusMeters = 6371000; // 6371 km = 6371000 mét

    final dLat = _toRadian(lat2 - lat1);
    final dLon = _toRadian(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadian(lat1)) *
            math.cos(_toRadian(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusMeters * c;
  }

  /// Chuyển đổi độ sang radian
  static double _toRadian(double degree) {
    return degree * math.pi / 180;
  }

  /// Ghi lại chấm công theo vị trí
  static Map<String, dynamic> recordAttendanceLocation(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'speed': position.speed,
      'timestamp': DateTime.now().toIso8601String(),
      'method': 'LOCATION',
    };
  }

  /// Lấy khoảng cách từ vị trí hiện tại đến văn phòng
  static Future<double?> getDistanceToOffice(
      double officeLatitude,
      double officeLongitude,
      ) async {
    try {
      Position? currentPosition = await getCurrentLocation();
      if (currentPosition == null) {
        return null;
      }

      double distance = _calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        officeLatitude,
        officeLongitude,
      );

      return distance;
    } catch (e) {
      print('Lỗi tính khoảng cách: $e');
      return null;
    }
  }
}
