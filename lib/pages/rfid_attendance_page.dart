import 'package:flutter/material.dart';
import '../services/nfc_rfid_service.dart';

class RFIDAttendancePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const RFIDAttendancePage({
    super.key,
    required this.user,
  });

  @override
  State<RFIDAttendancePage> createState() => _RFIDAttendancePageState();
}

class _RFIDAttendancePageState extends State<RFIDAttendancePage> {
  bool _isScanning = false;
  String? _scannedTagId;
  String? _message;
  Map<String, dynamic>? _scannedData;

  // Mock employee data - thay bằng dữ liệu từ database
  final List<Map<String, dynamic>> _employees = [
    {
      'id': '1',
      'name': 'Nguyễn Văn A',
      'rfid_tag_id': '04:D2:5A:B4:2C:51:81',
      'department': 'IT'
    },
    {
      'id': '2',
      'name': 'Trần Thị B',
      'rfid_tag_id': '04:C3:6B:C5:3D:62:92',
      'department': 'HR'
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkNFCSupport();
  }

  Future<void> _checkNFCSupport() async {
    bool isAvailable = await NFCRFIDService.isNFCAvailable();
    if (!isAvailable && mounted) {
      setState(() {
        _message = 'Thiết bị này không hỗ trợ NFC';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chấm công bằng thẻ RFID'),
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
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
                    Icons.nfc,
                    size: 48,
                    color: const Color(0xFF4361EE),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Đặt thẻ RFID gần thiết bị',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isScanning
                        ? 'Đang chờ quét thẻ...'
                        : 'Nhấn nút bên dưới để bắt đầu quét',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (_scannedTagId != null)
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
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Quét thẻ thành công',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ID Thẻ: $_scannedTagId',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (_scannedData != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Nhân viên: ${_scannedData!['employee_name'] ?? 'Không xác định'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Phòng ban: ${_scannedData!['department'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            if (_message != null) ...[
              const SizedBox(height: 20),
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
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _isScanning ? null : _startRFIDScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4361EE),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isScanning
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
                'Bắt đầu quét thẻ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (_scannedTagId != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _confirmRFIDAttendance,
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
        ),
      ),
    );
  }

  Future<void> _startRFIDScan() async {
    setState(() {
      _isScanning = true;
      _message = null;
      _scannedTagId = null;
      _scannedData = null;
    });

    try {
      Map<String, dynamic>? rfidData = await NFCRFIDService.scanRFIDTag();

      if (rfidData != null) {
        String tagId = rfidData['tagId'];

        // Tìm nhân viên từ RFID tag
        Map<String, dynamic>? employee =
        await NFCRFIDService.getEmployeeFromRFIDTag(tagId, _employees);

        setState(() {
          _scannedTagId = tagId;
          _scannedData = {
            'employee_name': employee?['name'] ?? 'Không xác định',
            'department': employee?['department'] ?? 'N/A',
          };
          _message = employee != null
              ? 'Thẻ được xác nhận - ${employee['name']}'
              : 'Thẻ không được xác nhận trong hệ thống';
        });
      } else {
        setState(() {
          _message = 'Không thể quét thẻ. Vui lòng thử lại.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Lỗi quét thẻ: $e';
      });
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _confirmRFIDAttendance() async {
    if (_scannedTagId == null) return;

    try {
      // Tìm nhân viên
      Map<String, dynamic>? employee =
      await NFCRFIDService.getEmployeeFromRFIDTag(_scannedTagId!, _employees);

      if (employee != null) {
        // Ghi lại chấm công
        Map<String, dynamic> attendanceRecord =
        NFCRFIDService.recordRFIDAttendance(
          employee['id'],
          _scannedTagId!,
          'correct', // uniform_status: 'correct', 'incorrect', 'damaged'
        );

        // TODO: Gửi dữ liệu lên server
        print('Ghi lại chấm công RFID: $attendanceRecord');

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
              content: Text('Thẻ không được xác nhận!'),
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
