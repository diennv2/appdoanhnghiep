import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chính Sách Bảo Mật"),
        centerTitle: true,
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RichText(
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black87
                          : Colors.white70,
                    ),
                    children: [
                      _sectionTitle("Cập Nhật Lần Cuối: 04/06/2026\n\n", context),
                      _normalText("Chính sách bảo mật này giải thích cách Techber thu thập, sử dụng và bảo vệ thông tin cá nhân của bạn khi bạn sử dụng ứng dụng của chúng tôi.\n\n"),

                      _sectionTitle("1. Quyền Truy Cập Ảnh Đại Diện\n", context),
                      _bulletPoint("Chúng tôi yêu cầu quyền truy cập vào thư viện ảnh trên thiết bị của bạn."),
                      _bulletPoint("Ảnh đại diện bạn chọn được lưu trữ an toàn để nhận dạng trong ứng dụng."),
                      _bulletPoint("Chúng tôi không chia sẻ ảnh đại diện của bạn với bất kỳ dịch vụ bên thứ ba nào."),

                      _sectionTitle("\n2. Dữ Liệu Vị Trí\n", context),
                      _bulletPoint("Chúng tôi thu thập dữ liệu vị trí chỉ nhằm mục đích theo dõi điểm danh."),
                      _bulletPoint("Quyền truy cập vị trí được cấp thông qua sự cho phép của người dùng và chỉ sử dụng trong giờ làm việc."),
                      _bulletPoint("Dữ liệu vị trí của bạn không bao giờ được chia sẻ ra bên ngoài và được mã hóa trong quá trình lưu trữ."),

                      _sectionTitle("\n3. Quyền Gọi Điện\n", context),
                      _bulletPoint("Chúng tôi có thể yêu cầu quyền gọi điện để tạo điều kiện liên lạc trực tiếp giữa quản trị viên và nhân viên."),
                      _bulletPoint("Không có nhật ký cuộc gọi hoặc danh sách liên hệ nào được thu thập hoặc lưu trữ."),
                      _bulletPoint("Tính năng gọi điện được giới hạn trong phạm vi chức năng của ứng dụng."),

                      _sectionTitle("\n4. Lưu Trữ và Bảo Mật Dữ Liệu\n", context),
                      _bulletPoint("Tất cả dữ liệu cá nhân (ảnh đại diện, vị trí và danh tính) được lưu trữ an toàn."),
                      _bulletPoint("Chúng tôi sử dụng mã hóa tiêu chuẩn ngành và các biện pháp lưu trữ an toàn."),
                      _bulletPoint("Thông tin đăng nhập của người dùng được mã hóa và không bao giờ được lưu trữ dưới dạng văn bản thuần túy."),

                      _sectionTitle("\n5. Chia Sẻ Dữ Liệu\n", context),
                      _bulletPoint("Dữ liệu của bạn chỉ được chia sẻ với quản trị viên được ủy quyền cho các mục đích chính thức."),
                      _bulletPoint("Chúng tôi không bán, cho thuê hoặc phân phối dữ liệu cá nhân cho bất kỳ bên thứ ba nào."),

                      _sectionTitle("\n6. Thay Đổi Chính Sách Bảo Mật\n", context),
                      _bulletPoint("Chúng tôi có thể cập nhật chính sách này theo thời gian."),
                      _bulletPoint("Người dùng sẽ được thông báo về những thay đổi quan trọng."),

                      _normalText("\nBằng cách sử dụng Chấm công doanh nghiệp - TECHBER VN, bạn đồng ý với các hoạt động dữ liệu được nêu trong Chính sách bảo mật này.\n\n"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Column(
                  children: [
                    Text(
                      "Liên Hệ Với Chúng Tôi",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade400),
                    SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: _contactEmail(
                        email: "ketoan@techber.vn",
                        text: "Có câu hỏi? Liên hệ với chúng tôi",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _sectionTitle(String text, BuildContext context) {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.blueAccent
            : Colors.lightBlueAccent,
      ),
    );
  }

  TextSpan _normalText(String text) {
    return TextSpan(text: text);
  }

  TextSpan _bulletPoint(String text) {
    return TextSpan(
      children: [
        TextSpan(
          text: "  •  ",
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: "$text\n",
          style: const TextStyle(height: 1.5),
        ),
      ],
    );
  }

  TextSpan _contactEmail({required String email, required String text}) {
    return TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () async {
              final Uri emailUri = Uri(scheme: 'mailto', path: email);
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              }
            },
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}