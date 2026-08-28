import 'dart:convert';
import 'dart:io';

import 'package:attendee/auth/supabase_auth.dart';
import 'package:attendee/pages/privacy_policy.dart';
import 'package:attendee/pages/profile.dart';
import 'package:attendee/pages/team_member_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/login_page.dart';
import '../provider/profile_image_provider.dart';
import '../services/api_service.dart';
import 'legal_page.dart';

class SettingPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const SettingPage({super.key, required this.user});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late final Map<String, dynamic> userInfo;
  late final String fullName;

  @override
  void initState() {
    super.initState();
    userInfo = widget.user;
    fullName = (userInfo['name'] ?? 'Người dùng').toString().trim();
  }
  String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // Nếu đã là URL đầy đủ thì trả luôn
    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    // Nếu là đường dẫn relative
    return 'https://chamcongdoanhnghiep.techber.vn$path';
  }
  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    final compressedBytes =
    await FlutterImageCompress.compressWithFile(
      pickedFile.path,
      quality: 85,
      rotate: 0,
      autoCorrectionAngle: true,
    );

    if (compressedBytes == null) return;

    final base64Image = base64Encode(compressedBytes);

    final prefs = await SharedPreferences.getInstance();

    final cbnvIdStr = prefs.getString('cbnv_id');

    if (cbnvIdStr == null || cbnvIdStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được ID cán bộ'),
        ),
      );
      return;
    }

    final cbnvId = int.tryParse(cbnvIdStr);

    if (cbnvId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID cán bộ không hợp lệ'),
        ),
      );
      return;
    }

    final result = await ApiService.uploadPhoto(
      cbnvId: cbnvId,
      imageBase64: base64Image,
    );

    if (result['success'] == true) {
      if (mounted) {
        Provider.of<ProfileImageProvider>(
          context,
          listen: false,
        ).setImageUrl(result['imagePath'] ?? '');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh thành công'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "Lỗi upload"),
        ),
      );
    }
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final passwordController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập mật khẩu để xác nhận xóa tài khoản.'),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final password = passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mật khẩu')),
      );
      return;
    }

    // Gọi API
    final result = await ApiService.deleteAccount(password: password);

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Đã xóa tài khoản')),
      );

      // Chuyển về màn hình login (giống logout)
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Xóa tài khoản thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // 🎯 Phần hiển thị ảnh đại diện & thông tin người dùng
                Consumer<ProfileImageProvider>(
                  builder: (ctx, profileProvider, child) {
                    final imageUrl = profileProvider.imageUrl;
                    final isLoading = profileProvider.isUploading;

                    ImageProvider imageProvider;
                    if (profileProvider.cachedImageBytes != null) {
                      imageProvider = MemoryImage(
                        profileProvider.cachedImageBytes!,
                      );
                    } else if (imageUrl != null && imageUrl.isNotEmpty) {
                      imageProvider = NetworkImage(getFullImageUrl(imageUrl));
                    } else {
                      imageProvider = const AssetImage(
                        "assets/images/avatar.png",
                      );
                    }

                    return Column(
                      children: [
                        SizedBox(height: height * 0.01),
                        // 🖼️ Avatar có thể nhấn để thay đổi ảnh
                        GestureDetector(
                          onTap: () => _pickAndUploadAvatar(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // ✅ Hero animation cho ảnh
                                  Hero(
                                    tag: 'profile-image-hero',
                                    child: CircleAvatar(
                                      radius: 70,
                                      backgroundImage: imageProvider,
                                    ),
                                  ),
                                  // ✅ Hiển thị vòng tải khi đang upload
                                  if (isLoading)
                                    const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  // ✅ Nút camera khi không tải
                                  if (!isLoading)
                                    Positioned(
                                      bottom: 0,
                                      right: 12,
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.grey[200],
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 20,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // 👤 Tên người dùng
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 💼 Chức vụ
                        const Text(
                          "Nhân viên",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.1,
                            wordSpacing: 1.1,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 15),
                // ✏️ Nút chỉnh sửa hồ sơ
                SizedBox(
                  width: 350,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF3085FE),
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Chỉnh sửa hồ sơ",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 📋 Danh sách các mục menu
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      // 👤 Hồ sơ của tôi
                      MenuTile(
                        icon: Icons.person_outline,
                        title: 'Hồ sơ của tôi',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 10),
                      // 👥 Thành viên nhóm
                      MenuTile(
                        icon: Icons.people_outline,
                        title: 'Thành viên nhóm',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeamMemberPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 10),
                      // 📄 Điều khoản & Điều kiện
                      MenuTile(
                        icon: Icons.description_outlined,
                        title: 'Điều khoản & Điều kiện',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LegalScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 10),
                      // 🔒 Chính sách bảo mật
                      MenuTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Chính sách bảo mật',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                      MenuTile(
                        icon: Icons.delete_forever,
                        title: 'Xóa tài khoản',
                        iconColor: Colors.redAccent,
                        textColor: Colors.redAccent,
                        onTap: () => _confirmAndDeleteAccount(context),
                      ),
                      const Divider(height: 10),
                      const SizedBox(height: 20),
                      // 🚪 Đăng xuất
                      MenuTile(
                        icon: Icons.logout,
                        title: 'Đăng xuất',
                        iconColor: Colors.redAccent,
                        textColor: Colors.redAccent,
                        onTap: () async {
                          await OauthHelper().signOutUser(context);

                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                                  (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎨 Widget tùy chỉnh cho các mục menu
class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
