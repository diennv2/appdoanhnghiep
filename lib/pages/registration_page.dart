import 'package:attendee/widgets/custom_form_textfield.dart';
import 'package:attendee/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../services/api_service.dart';
import '../widgets/custom_text.dart';
import 'legal_page.dart';
import 'login_page.dart';

class RegistrationPage extends StatefulWidget {
  final String? errorMessage;
  const RegistrationPage({super.key, this.errorMessage});
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController fullName = TextEditingController();
  final TextEditingController emailTextController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();
  final TextEditingController fullPhoneNumber =
  TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Form Key

  // Status Variables
  bool _isSubmitted = false;
  bool _obscureText = true;
  bool isEmailValid = false;
  bool validPass = false;
  bool isChecked = false;

  // Submission state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    emailTextController.addListener(validateEmail);
    passwordController.addListener(isSamePass);
    confirmPasswordController.addListener(isSamePass);
  }

  @override
  void dispose() {
    emailTextController.removeListener(validateEmail);
    passwordController.removeListener(isSamePass);
    confirmPasswordController.removeListener(isSamePass);
    emailTextController.dispose();
    passwordController.dispose();
    fullName.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void validateEmail() {
    final email = emailTextController.text;
    final bool isValid = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
    setState(() {
      isEmailValid = isValid;
    });
  }

  void isSamePass() {
    final pass = passwordController.text.toString().trim();
    final confirmPass = confirmPasswordController.text.toString().trim();
    setState(() {
      validPass =
          pass.isNotEmpty && confirmPass.isNotEmpty && pass == confirmPass;
    });
  }

  Future<void> _registerUser() async {
    // Mark submitted so validators show messages
    setState(() {
      _isSubmitted = true;
    });

    // Trigger validators
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Save form (IntlPhoneField.onSaved will set fullPhoneNumber)
    _formKey.currentState!.save();

    String email = emailTextController.text.trim();
    String username = fullName.text.trim();
    String password = passwordController.text.trim();
    String name = fullName.text.toString().trim();
    String phone = fullPhoneNumber.text.toString().trim();

    if (username.isEmpty || password.isEmpty || name.isEmpty || email.isEmpty) {
      CustomSnackbar.show(
        context: context,
        label: "Vui lòng điền đầy đủ thông tin",
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Call ApiService.signup with email field (no address2)
      final result = await ApiService.signup(
        username: username,
        password: password,
        email: email, // send email explicitly
        phone: phone,
        address: '', // optional
      );

      final success = result['success'] == true || result['status'] == true;
      final message = result['message']?.toString() ?? 'Đăng ký thất bại';

      if (success) {
        CustomSnackbar.show(
          context: context,
          title: '🎉 Thành công!',
          label: message,
          color: const Color(0xE04CAF50),
          svgColor: const Color(0xE0178327),
        );

        // Optionally navigate to login page after short delay
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
                (Route<dynamic> route) => false,
          );
        }
      } else {
        CustomSnackbar.show(
          context: context,
          label: message,
        );
      }
    } catch (e) {
      CustomSnackbar.show(
        context: context,
        label: "Lỗi: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          //Change the focus from the keyboard
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                screenHeight - (MediaQuery.of(context).padding.top + kToolbarHeight),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    /*Logo*/
                    SizedBox(
                      width: screenHeight * 0.14,
                      height: screenHeight * 0.1,
                      child: Image.asset('assets/images/logo.png'),
                    ),

                    const SizedBox(height: 10),

                    const CustomText(text: 'Đăng Ký Tài Khoản'),

                    Row(
                      children: const [
                        CustomText(text: 'để tiếp tục sử dụng ứng dụng '),
                        CustomText(text: '', color: Color(0xFF3085FE)),
                      ],
                    ),

                    const SizedBox(height: 6),

                    const CustomText(
                      text: 'Xin chào, hãy đăng ký để tiếp tục',
                      fontSize: 12,
                      color: Color(0xFFACAFB5),
                    ),

                    const SizedBox(height: 16),

                    // Full Name Field
                    CustomFormTextField(
                      textController: fullName,
                      textKeyboardType: TextInputType.name,
                      labelText: 'Tên tài khoản',
                      hintText: "Nhập tên tài khoản",
                      validator: (value) {
                        if (!_isSubmitted) return null;
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên tài khoản';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _isSubmitted = false;
                          _formKey.currentState!.validate();
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Email Text Field
                    CustomFormTextField(
                      textController: emailTextController,
                      textKeyboardType: TextInputType.emailAddress,
                      labelText: 'Địa chỉ Email',
                      suffixIcon: Icon(
                        isEmailValid ? Icons.check_circle : Icons.email_outlined,
                        color: isEmailValid ? Colors.green : Colors.grey,
                      ),
                      hintText: "vidu@email.com",
                      validator: (value) {
                        if (!_isSubmitted) return null;
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập Email';
                        }
                        if (!isEmailValid) {
                          return 'Vui lòng nhập Email hợp lệ';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _isSubmitted = false;
                          _formKey.currentState!.validate();
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    /*Phone Number */
                    CustomFormTextField(
                      textController: fullPhoneNumber,   // controller riêng cho phone
                      textKeyboardType: TextInputType.number,
                      labelText: 'Số điện thoại',
                      hintText: "Nhập số điện thoại (VD: 0389293955)",
                      suffixIcon: const Icon(
                        Icons.local_phone_outlined,
                        color: Colors.grey,
                      ),
                      // Không dùng obscureText
                      obscureText: false,
                      validator: (value) {
                        if (!_isSubmitted) return null;
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        String number = value.replaceAll(RegExp(r'\s+'), '');
                        // Chấp nhận số 10 chữ số bắt đầu 0
                        if (!RegExp(r'^0\d{9}$').hasMatch(number)) {
                          return 'Số điện thoại không hợp lệ (VD: 0389293955)';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() => _isSubmitted = false);
                        _formKey.currentState?.validate();
                      },
                    ),

                    const SizedBox(height: 12),

                    // Password Field
                    CustomFormTextField(
                      textController: passwordController,
                      obscureText: _obscureText,
                      labelText: 'Mật khẩu',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscureText = !_obscureText);
                        },
                        icon: Icon(
                          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                      ),
                      suffix: (validPass)
                          ? const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      )
                          : null,
                      validator: (value) {
                        if (!_isSubmitted) return null;
                        if (value == null || value.isEmpty) {
                          return "Mật khẩu không được để trống!";
                        }
                        if ((value?.length ?? 0) < 6) {
                          return "Mật khẩu phải tối thiểu 6 ký tự";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _isSubmitted = false;
                          _formKey.currentState!.validate();
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Confirm_Password Field
                    CustomFormTextField(
                      textController: confirmPasswordController,
                      obscureText: _obscureText,
                      labelText: 'Xác nhận mật khẩu',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        icon: Icon(
                          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                      ),
                      suffix: (validPass)
                          ? const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      )
                          : null,
                      validator: (value) {
                        if (!_isSubmitted) return null;
                        if (value == null || value.isEmpty) {
                          return "Mật khẩu không được để trống!";
                        }
                        if (value != passwordController.text) {
                          return "Mật khẩu xác nhận không khớp";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _isSubmitted = false;
                          _formKey.currentState!.validate();
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Checkbox with text
                          Checkbox(
                            value: isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isChecked = value ?? false;
                                if (isChecked) {
                                  CustomSnackbar.show(
                                    context: context,
                                    title: "Xác nhận điều khoản",
                                    label: "Đã chấp nhận Điều khoản & Điều kiện",
                                    color: const Color(0xE04CAF50),
                                    svgColor: const Color(0xE0178327),
                                  );
                                }
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            side: const BorderSide(
                              color: Color(0xFF3085FE),
                              width: 1.5,
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LegalScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Tôi đồng ý với Điều khoản & Điều kiện",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xBB3085FE),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Registration Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isChecked && !_isSubmitting
                            ? () {
                          setState(() {
                            _isSubmitted = true;
                          });

                          if (_formKey.currentState!.validate()) {
                            _registerUser();
                          }
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3085FE),
                          padding: const EdgeInsets.all(15),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Đăng ký',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Đã có tài khoản? ",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFACAFB5),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                                    (Route<dynamic> route) => false,
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                color: Color(0xFF3085FE), // Blue color
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}