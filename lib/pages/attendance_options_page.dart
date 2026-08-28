import 'package:flutter/material.dart';
import 'location_attendance_page.dart';
import 'rfid_attendance_page.dart';
import 'faceid_attendance_page.dart';

class AttendanceOptionsPage extends StatelessWidget {
  final Map<String, dynamic> user;

  const AttendanceOptionsPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn phương thức chấm công'),
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Chọn một trong các phương thức chấm công:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            _buildAttendanceCard(
              context,
              icon: Icons.location_on,
              title: 'Chấm công theo vị trí',
              description: 'Sử dụng vị trí để xác nhận bạn trong vùng làm việc',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LocationAttendancePage(user: user),
                  ),
                );
              },
              isDark: isDark,
            ),
            // const SizedBox(height: 16),
            // _buildAttendanceCard(
            //   context,
            //   icon: Icons.nfc,
            //   title: 'Chấm công bằng thẻ RFID',
            //   description: 'Quét thẻ RFID để xác nhận đồng phục',
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => RFIDAttendancePage(user: user),
            //       ),
            //     );
            //   },
            //   isDark: isDark,
            // ),
            const SizedBox(height: 16),
            _buildAttendanceCard(
              context,
              icon: Icons.face,
              title: 'Chấm công bằng FaceID',
              description: 'Xác thực bằng nhận diện khuôn mặt',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FaceIDAttendancePage(user: user),
                  ),
                );
              },
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required VoidCallback onTap,
        required bool isDark,
      }) {
    return Card(
      color: isDark ? const Color(0xFF0D1117) : Colors.white,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4361EE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4361EE),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF4361EE),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
