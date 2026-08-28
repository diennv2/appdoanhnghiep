import 'package:attendee/pages/activity_page.dart';
import 'package:attendee/pages/attendance_options_page.dart';
import 'package:attendee/pages/home_page.dart';
import 'package:attendee/pages/user_salary_page.dart';
import 'package:attendee/pages/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class UserMainPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const UserMainPage({super.key, required this.user});

  @override
  State<UserMainPage> createState() => _UserMainPageState();
}

class _UserMainPageState extends State<UserMainPage> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomePage(user: widget.user),
      const ActivityPage(),
      const UserSalaryPage(),
      const ProfilePage(),
    ];
  }

  /// Kiểm tra xem quyền vị trí đã được cấp chưa
  Future<bool> _hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always &&
            isLocationServiceEnabled;
  }

  /// Hiển thị Prominent Disclosure trước khi yêu cầu quyền
  void _showLocationDisclosureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin về quyền truy cập vị trí'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ứng dụng Chấm Công cần truy cập vị trí của bạn để:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Xác minh bạn đang tại nơi làm việc được phép'),
                    SizedBox(height: 8),
                    Text('• Ghi nhận vị trí và thời gian chấm công'),
                    SizedBox(height: 8),
                    Text('• Đảm bảo tính xác thực của bản ghi công việc'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn có thể:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Cho phép truy cập vị trí bất cứ lúc nào'),
                    SizedBox(height: 8),
                    Text('• Từ chối quyền này bất cứ lúc nào trong Cài đặt'),
                    SizedBox(height: 8),
                    Text('• Chọn "Chỉ khi sử dụng" để hạn chế truy cập'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Dữ liệu vị trí của bạn được bảo vệ theo chính sách bảo mật của chúng tôi.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // TextButton(
          //   onPressed: () {
          //     Navigator.pop(context);
          //     // Người dùng từ chối - không làm gì cả
          //   },
          //   child: const Text('Từ chối'),
          // ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Sau khi hiểu rõ, tiến hành request quyền
              _proceedWithLocationPermission();
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  /// Xử lý yêu cầu quyền và chuyển trang
  Future<void> _proceedWithLocationPermission() async {
    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Yêu cầu quyền vị trí
    bool hasPermission = await _requestLocationPermission();

    // Đóng loading
    if (mounted) {
      Navigator.pop(context);
    }

    // Nếu có quyền, chuyển đến trang chấm công
    if (hasPermission && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceOptionsPage(user: widget.user),
        ),
      );
    }
  }

  Future<bool> _requestLocationPermission() async {
    // Kiểm tra quyền vị trí hiện tại
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Quyền chưa được cấp, yêu cầu từ người dùng
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Người dùng từ chối yêu cầu
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Người dùng từ chối vĩnh viễn, cần mở cài đặt
      if (mounted) {
        _showPermissionPermanentlyDeniedDialog();
      }
      return false;
    }

    // Kiểm tra GPS có bật không
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      if (mounted) {
        _showLocationServiceDisabledDialog();
      }
      return false;
    }

    return true;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu quyền vị trí'),
        content: const Text(
          'Ứng dụng cần quyền truy cập vị trí để chấm công. Vui lòng cấp quyền để tiếp tục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Hiển thị lại disclosure trước khi yêu cầu lần nữa
              _showLocationDisclosureDialog();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quyền vị trí bị từ chối'),
        content: const Text(
          'Quyền vị trí đã bị từ chối vĩnh viễn. Vui lòng vào Cài đặt > Ứng dụng > Chấm công > Quyền để cấp quyền vị trí.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS chưa được bật'),
        content: const Text(
          'Vui lòng bật GPS để sử dụng tính năng chấm công.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Bật GPS'),
          ),
        ],
      ),
    );
  }

  void _onAttendanceButtonPressed() async {
    // Kiểm tra xem đã có quyền chưa
    bool hasPermission = await _hasLocationPermission();

    if (!mounted) return;

    if (hasPermission) {
      // Đã có quyền, trực tiếp vào trang chấm công
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceOptionsPage(user: widget.user),
        ),
      );
    } else {
      // Chưa có quyền, hiển thị disclosure
      _showLocationDisclosureDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: isDark ? Colors.white : const Color(0xFF161B22),
      systemNavigationBarIconBrightness:
      isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: _onAttendanceButtonPressed,
        backgroundColor: const Color(0xFF4361EE),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location),
        label: const Text('Chấm công'),
      )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        height: 65,
        backgroundColor: isDark ? Colors.white : const Color(0xFF161B22),
        indicatorColor: const Color(0xFF4361EE).withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF4361EE)),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon:
            Icon(Icons.timeline_rounded, color: Color(0xFF4361EE)),
            label: 'Hoạt động',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon:
            Icon(Icons.payments_rounded, color: Color(0xFF4361EE)),
            label: 'Lương',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF4361EE)),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
