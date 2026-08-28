import 'package:attendee/auth/supabase_auth.dart';
import 'package:attendee/pages/verification_page.dart';
import 'package:attendee/widgets/custom_form_textfield.dart';
import 'package:flutter/material.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isEmailValid = false;
  bool _isSubmitted = false;

  void validateEmail() {
    final email = emailController.text;
    final bool isValid = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
    setState(() {
      isEmailValid = isValid;
    });
  }


  // // Sending Reset Password Link
  void resetPassword() {
    final email = emailController.text.toString().trim();
    OauthHelper().resetPassword(context: context,email: email);

  }




  void navigateVerificationPage(){
    final email = emailController.text.toString().trim();
    if (context.mounted) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VerificationPage(
                    isReset: true,
                    email: email,
                  ),
            ),
          );
        }
      });
    }

  }




  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          forceMaterialTransparency: true,

        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                physics: const NeverScrollableScrollPhysics(),

                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Forgot password 🤔",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFF1F1F1F)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Select the email address you want us to use to reset your password.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFF1F1F1F)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: Image.asset(
                          'assets/images/forgot_password.png',
                          height: screenHeight * 0.35,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Form(
                        key: _formKey,
                        child: CustomFormTextField(
                          labelText: "Email",
                          textController: emailController,
                          textKeyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          hintText: "example@email.com",
                          validator: (value) {
                            if (!_isSubmitted) return null;
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Email';
                            }
                            if (!isEmailValid) {
                              return 'Enter a valid Email';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            validateEmail();
                            _formKey.currentState?.validate();
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isSubmitted = true;
                              validateEmail();
                            });

                            if (_formKey.currentState!.validate()) {
                              // Send Reset Link
                              resetPassword();
                              navigateVerificationPage();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3085FE),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            "Reset Password",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
