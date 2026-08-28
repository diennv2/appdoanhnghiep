import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/supabase_auth.dart';
import '../database/database_helper.dart';
import '../services/api_service.dart';
import '../widgets/custom_info.dart';

class ProfileDetails extends StatefulWidget {
  const ProfileDetails({super.key});

  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  String? _activeField;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DatabaseHelperProvider>();

      // 1. Lấy thông tin người dùng từ Supabase (hành vi hiện có)
      await provider.fetchUserProfile();

      // 2. Cập nhật dữ liệu từ API backend mới để đảm bảo
      //    họ tên / số điện thoại luôn được đồng bộ ngay cả khi
      //    dữ liệu Supabase khác biệt.
      try {
        final result = await ApiService.getUserInfo();
        if (result['success'] == true) {
          final userInfo =
              (result['userInfo'] as Map<String, dynamic>?) ?? {};
          if (userInfo.isNotEmpty) {
            provider.syncApiUserInfo(userInfo);
          }
        }
      } catch (_) {
        // Lỗi đồng bộ API không nghiêm trọng; dữ liệu Supabase vẫn được hiển thị.
      }
    });
  }

  Future<void> _updateField(BuildContext context, String key, dynamic value) async {
    await Provider.of<DatabaseHelperProvider>(context, listen: false)
        .updateUserField(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final dbProvider = Provider.of<DatabaseHelperProvider>(context);
    final profile = dbProvider.profile;

    return SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _activeField = null);
        },
        child: dbProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : profile == null
            ? const Center(child: Text('Không có dữ liệu hồ sơ.'))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(5),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoTile(
                    value: profile["full_name"] ?? "",
                    readOnly: true,
                    title: "Họ và tên",
                    fieldKey: "full_name",
                    activeField: _activeField,
                    onChanged: (newValue) {
                      _updateField(context, "full_name", newValue);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "full_name" : null);
                    },
                  ),
                  InfoTile(
                    value: profile["email"] ?? "",
                    readOnly: true,
                    title: "Địa chỉ Email",
                    fieldKey: "email",
                    activeField: _activeField,
                    onChanged: (newValue) {},
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "email" : null);
                    },
                  ),
                  InfoTile(
                    value: profile["phone"] ?? "",
                    title: "Số điện thoại",
                    readOnly: false,
                    fieldKey: "phone",
                    activeField: _activeField,
                    onChanged: (newValue) {
                      _updateField(context, "phone", newValue);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "phone" : null);
                    },
                  ),
                  InfoTile(
                    value: profile["age"]?.toString() ?? "",
                    title: "Tuổi",
                    fieldKey: "age",
                    activeField: _activeField,
                    onChanged: (newValue) {
                      _updateField(context, "age", newValue);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "age" : null);
                    },
                  ),
                  InfoTile(
                    value: profile["address"] ?? "",
                    title: "Địa chỉ",
                    fieldKey: "address",
                    activeField: _activeField,
                    onChanged: (newValue) {
                      _updateField(context, "address", newValue);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "address" : null);
                    },
                  ),

                  InfoTile(
                    isDropdown: true,
                    value: profile["gender"] ?? "",
                    title: "Giới tính",
                    fieldKey: "gender",
                    activeField: _activeField,
                    onItemChanged: (newValue) {
                      _updateField(context, "gender", newValue!);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "gender" : null);
                    },
                  ),
                  InfoTile(
                    value: profile["emergency_contact"] ?? "",
                    title: "Liên hệ khẩn cấp",
                    fieldKey: "emergency_contact",
                    activeField: _activeField,
                    onChanged: (newValue) {
                      _updateField(context, "emergency_contact", newValue);
                    },
                    onFocusChange: (isFocused) {
                      setState(() => _activeField = isFocused ? "emergency_contact" : null);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}