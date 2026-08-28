import 'package:flutter/material.dart';
import '../services/face_id_service.dart';

class FaceIDAttendancePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const FaceIDAttendancePage({
    super.key,
    required this.user,
  });

  @override
  State<FaceIDAttendancePage> createState() => _FaceIDAttendancePageState();
}

class _FaceIDAttendancePageState extends State<FaceIDAttendancePage> {
  bool _isAuthenticating = false;
  String? _message;
  bool? _authenticationSuccess;
  bool _supportsFaceID = false;

  @override
  void initState() {
    super.initState();
    _checkFaceIDSupport();
  }

  Future<void> _checkFaceIDSupport() async {
    bool supportsFace = await FaceIDService.supportsFaceRecognition();
    bool canAuth = await FaceIDService.canAuthenticateWithBiometrics();

    setState(() {
      _supportsFaceID = supportsFace && canAuth;
    });

    if (!_supportsFaceID && mounted) {
      setState(() {
        _message = 'Thiết bị này không hỗ trợ nhận diện khuôn mặt hoặc sinh trắc học.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chấm công bằng FaceID'),
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF4361EE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4361EE).withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.face,
                    size: 64,
                    color: const Color(0xFF4361EE),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Xác thực bằng khuôn mặt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isAuthenticating
                        ? 'Đang xác thực...'
                        : 'Hãy nhìn vào camera để xác thực',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _authenticationSuccess ?? false
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _authenticationSuccess ?? false
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _authenticationSuccess ?? false
                          ? Icons.check_circle
                          : Icons.info,
                      color: _authenticationSuccess ?? false
                          ? Colors.green
                          : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _authenticationSuccess ?? false
                              ? Colors.green
                              : Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
            if (_authenticationSuccess == true)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Xác thực thành công',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nhân viên: ${widget.user['name'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Thời gian: ${DateTime.now().toString().substring(0, 19)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            if (!_supportsFaceID)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thiết bị không hỗ trợ FaceID hoặc sinh trắc học',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ElevatedButton(
                onPressed:
                _isAuthenticating || _authenticationSuccess == true
                    ? null
                    : _authenticateWithFaceID,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4361EE),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isAuthenticating
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  _authenticationSuccess == true
                      ? 'Xác thực thành công'
                      : 'Xác thực bằng FaceID',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_authenticationSuccess == true) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _confirmFaceIDAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận chấm công',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _authenticateWithFaceID() async {
    setState(() => _isAuthenticating = true);

    try {
      bool isAuthenticated = await FaceIDService.authenticateWithFaceID(
        reason: 'Vui lòng xác thực bằng khuôn mặt để chấm công',
      );

      setState(() {
        _authenticationSuccess = isAuthenticated;
        if (isAuthenticated) {
          _message = 'Xác thực khuôn mặt thành công!';
        } else {
          _message = 'Xác thực thất bại. Vui lòng thử lại.';
        }
      });
    } catch (e) {
      setState(() {
        _message = 'Lỗi xác thực: $e';
        _authenticationSuccess = false;
      });
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _confirmFaceIDAttendance() async {
    try {
      Map<String, dynamic>? result =
      await FaceIDService.authenticateAttendance(
        widget.user['id'] ?? 'unknown',
        reason: 'Xác nhận chấm công',
      );

      if (result != null && result['success'] == true) {
        // TODO: Gửi dữ liệu lên server
        print('Ghi lại chấm công FaceID: $result');

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chấm công thất bại!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
