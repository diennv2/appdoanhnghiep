import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_attendance_service.dart';

class LocationAttendancePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const LocationAttendancePage({
    super.key,
    required this.user,
  });

  @override
  State<LocationAttendancePage> createState() => _LocationAttendancePageState();
}

class _LocationAttendancePageState extends State<LocationAttendancePage> {
  bool _isLoading = false;
  String? _message;
  bool? _isWithinRadius;
  Position? _currentPosition;

  // Tọa độ văn phòng (ví dụ: Hà Nội)
  final double _officeLatitude = 21.0285;
  final double _officeLongitude = 105.8542;
  final double _radiusMeters = 100; // 100 mét

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chấm công theo vị trí'),
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildInfoCard(
              isDark,
              'Thông tin vị trí văn phòng',
              'Vĩ độ: $_officeLatitude\nKinh độ: $_officeLongitude\nBán kính: ${_radiusMeters.toStringAsFixed(0)} mét',
            ),
            const SizedBox(height: 20),
            if (_currentPosition != null)
              _buildInfoCard(
                isDark,
                'Vị trí hiện tại',
                'Vĩ độ: ${_currentPosition!.latitude}\nKinh độ: ${_currentPosition!.longitude}\nĐộ chính xác: ${_currentPosition!.accuracy.toStringAsFixed(2)} mét',
              ),
            const SizedBox(height: 20),
            if (_isWithinRadius != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isWithinRadius!
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                    _isWithinRadius! ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isWithinRadius! ? Icons.check_circle : Icons.cancel,
                      color: _isWithinRadius! ? Colors.green : Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isWithinRadius!
                            ? 'Bạn đang trong vùng làm việc'
                            : 'Bạn không trong vùng làm việc',
                        style: TextStyle(
                          color: _isWithinRadius! ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  _message!,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkLocationAndAttend,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4361EE),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Chấm công',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      bool isDark,
      String title,
      String content,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4361EE),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkLocationAndAttend() async {
    setState(() => _isLoading = true);

    try {
      // Lấy vị trí hiện tại
      Position? position = await LocationAttendanceService.getCurrentLocation();

      if (position != null) {
        setState(() => _currentPosition = position);

        // Kiểm tra có trong vùng làm việc không
        bool isWithinRadius =
        await LocationAttendanceService.isWithinOfficeRadius(
          _officeLatitude,
          _officeLongitude,
          radiusMeters: _radiusMeters,
        );

        setState(() => _isWithinRadius = isWithinRadius);

        if (isWithinRadius) {
          // Ghi lại chấm công
          Map<String, dynamic> attendanceRecord =
          LocationAttendanceService.recordAttendanceLocation(position);

          setState(() {
            _message =
            'Chấm công thành công!\nThời gian: ${attendanceRecord['timestamp']}';
          });

          // Gửi dữ liệu lên server
          _submitAttendance(attendanceRecord);

          // Hiển thị thông báo thành công
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Chấm công thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        } else {
          setState(() {
            _message = 'Bạn không ở trong vùng làm việc.\nVui lòng di chuyển đến văn phòng.';
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bạn không ở trong vùng làm việc!'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        setState(() {
          _message = 'Không thể lấy được vị trí của bạn. Vui lòng kiểm tra quyền truy cập GPS.';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi lấy vị trí!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _message = 'Lỗi: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAttendance(Map<String, dynamic> attendanceRecord) async {
    try {
      // TODO: Gửi dữ liệu lên Firebase/Backend
      print('Ghi lại chấm công: $attendanceRecord');
      // Ví dụ:
      // await firebaseService.recordAttendance({
      //   'user_id': widget.user['id'],
      //   'attendance_data': attendanceRecord,
      // });
    } catch (e) {
      print('Lỗi ghi lại chấm công: $e');
    }
  }
}
