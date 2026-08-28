import 'dart:async';
import 'package:attendee/auth/supabase_auth.dart';
import 'package:attendee/pages/login_page.dart';
import 'package:attendee/widgets/custom_alert_box.dart';
import 'package:attendee/widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/database_helper.dart';

class VerificationPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  final bool? isReset;
  final String? email;
  final String? phone;

  const VerificationPage({
    super.key,
    this.user,
    this.isReset,
    this.email,
    this.phone,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool isSend = false;
  late String lastName;
  late String email;
  Timer? _emailCheckTimer;
  int _resendTime = 0;
  Timer? _resendTimer;

  void resendLink() async {
    setState(() {
      isSend = true;
      _resendTime = 30;
    });

    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTime > 0) {
          _resendTime--;
        } else {
          timer.cancel();
        }
      });
    });

    try {
      await OauthHelper.sendVerificationEmail(context);

      if (kDebugMode) {
        print("Resend type: ${widget.isReset ?? false ? 'Password Reset' : 'Email Verification'}");
      }
    } finally {
      setState(() {
        isSend = false;
      });
    }
  }

  void resetPassword() {
    setState(() {
      isSend = true;
      _resendTime = 30;
    });
    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTime > 0) {
          _resendTime--;
        } else {
          timer.cancel();
        }
      });
    });

    try {
      email = widget.email?.trim() ?? '';
      OauthHelper().resetPassword(context: context, email: email);
    } finally {
      setState(() {
        isSend = false;
      });
    }
  }

  Future<void> _updateField(
      BuildContext context,
      String key,
      String value,
      ) async {
    try {
      await Provider.of<DatabaseHelperProvider>(
        context,
        listen: false,
      ).updateUserField(key, value);
      print("All Data UPDATED");
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    lastName = "";
    final nameFromMeta = widget.user?['name'];
    email = widget.user?['email'] ?? "";

    if (nameFromMeta != null &&
        nameFromMeta is String &&
        nameFromMeta.trim().isNotEmpty) {
      lastName = nameFromMeta.trim().split(' ').last;
    }

    if (!(widget.isReset ?? false)) {
      _emailCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          // Check if email is verified
          // Since we're using API now, we'll just check if the user exists in the database
          // This is a simplified version - you may need to adjust based on your backend

          if (mounted) {
            if (widget.phone != null && widget.phone!.isNotEmpty) {
              await _updateField(context, 'phone', widget.phone!);
            }

            if (mounted) {
              CustomAlertBox().showCustomAnimatedAlert(
                context: context,
                title: "🎉 Congratulations $lastName",
                label: "Your account is ready to use",
                user: widget.user,
              );
            }
          }

          timer.cancel();
        } catch (e) {
          print("Error checking email verification: $e");
        }
      });
    }
  }

  @override
  void dispose() {
    _emailCheckTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> openEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          label: 'Could not launch email app',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReset ?? false ? "Password Recovery" : "Email Verification",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3C57A4),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
        forceMaterialTransparency: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3C57A4),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/mail.png",
                width: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                "Hi, $lastName",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Welcome to Attendee",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              widget.isReset ?? false
                  ? const Text(
                "📩 Boom! Reset instructions are flying to your inbox now!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              )
                  : const Text(
                "We have sent you an email verification link.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: widget.isReset ?? false
                    ? Text(
                  "Click on the Reset link sent to\n${widget.email ?? " "}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: Colors.white70,
                  ),
                )
                    : Text(
                  "Click on the verification link sent to\n$email",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the email?",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  TextButton(
                    onPressed: widget.isReset ?? false
                        ? (_resendTime > 0 || isSend)
                        ? null
                        : resetPassword
                        : (_resendTime > 0 || isSend)
                        ? null
                        : resendLink,
                    child: isSend
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(),
                    )
                        : Text(
                      _resendTime > 0
                          ? "Send Again ($_resendTime s)"
                          : "Send Again",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _resendTime > 0 ? Colors.grey : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: openEmail,
                icon: const Icon(
                  Icons.email_outlined,
                  color: Colors.white,
                  size: 23,
                ),
                label: const Text(
                  "Open Email",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                        (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  "🔑 Unlock Your Dashboard",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}