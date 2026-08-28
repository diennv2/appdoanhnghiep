import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        centerTitle: true,
        forceMaterialTransparency: true,

      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16,bottom: 16,right: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align text properly
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
                      _sectionTitle("📅 Last Updated: April 4, 2025\n\n", context),
                      _normalText("Welcome to Attendee! These Terms & Conditions (“Terms”) govern your use of our attendee application. By using our app, you agree to be bound by these Terms.\n\n"),

                      _sectionTitle("📌 1. Use of the App\n", context),
                      _bulletPoint("This app tracks employee attendance, including office entry, breaks, and exits."),
                      _bulletPoint("Users must provide accurate data while using the app."),
                      _bulletPoint("Admins have access to attendance records, location data, and salary details."),
                      _bulletPoint("We reserve the right to suspend or terminate accounts violating our policies."),

                      _sectionTitle("\n📍 2. Attendance & Location Tracking\n", context),
                      _bulletPoint("The app uses GPS to track attendance, check-ins, and early departures."),
                      _bulletPoint("Admins receive notifications when employees are late or leave early."),
                      _bulletPoint("Location tracking is only active during work hours as per company policy."),
                      _bulletPoint("Employees must enable location services for accurate tracking."),

                      _sectionTitle("\n💰 3. Employee Salary & Payroll\n", context),
                      _bulletPoint("Admins track salary payments and update salary slips."),
                      _bulletPoint("Employees can view salary history and download slips."),
                      _bulletPoint("Salary calculations and confirmations are employer-managed."),

                      _sectionTitle("\n🔐 4. Privacy & Data Collection\n", context),
                      _bulletPoint("We collect personal data (location, attendance, salary details) for work tracking."),
                      _bulletPoint("Your data is only shared with employers/admins for official use."),
                      _bulletPoint("All sensitive data is securely encrypted and stored."),

                      _sectionTitle("\n⚠️ 5. Limitation of Liability\n", context),
                      _bulletPoint("We are not responsible for incorrect salary calculations or attendance errors."),
                      _bulletPoint("We do not guarantee GPS accuracy in poor network conditions."),
                      _bulletPoint("Salary or attendance disputes must be resolved between employees and employers."),

                      _sectionTitle("\n🔄 6. Changes to These Terms\n", context),
                      _bulletPoint("We reserve the right to modify these Terms at any time."),
                      _bulletPoint("Users will be notified of significant changes."),

                      _sectionTitle("\n🔒 7. User Authentication & Data Security\n", context),
                      _bulletPoint("User credentials (email, password, etc.) are securely stored and encrypted."),
                      _bulletPoint("We utilize industry-standard encryption protocols to ensure the safety of your login information."),
                      _bulletPoint("Passwords are never stored in plaintext and are securely hashed."),
                      _bulletPoint("Users are required to provide valid credentials during sign-up and sign-in processes."),
                      _bulletPoint("We may implement multi-factor authentication (MFA) for additional security."),
                      _bulletPoint("You are responsible for maintaining the confidentiality of your account credentials."),

                      _normalText("\nBy using Attendee, you acknowledge that you have read, understood, and agreed to these Terms & Conditions.\n\n"),





                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Contact Section
              Center(
                child: Column(
                  children: [
                    Text(
                      "📩 Contact Us",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade400), // Subtle line
                    SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: _contactEmail(email: "mharif8484@gmail.com",text: "Need Help? Write to Us"),
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

  // Enhanced Section Title with Icon and Divider
  TextSpan _sectionTitle(String text, BuildContext context) {
    return TextSpan(
      children: [
        TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.blueAccent
                : Colors.lightBlueAccent,
          ),
        ),
      ]
    );
  }

  // Improved Contact Email
  TextSpan _contactEmail({required String email,required String text}) {
    return TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email, color: Colors.blueAccent, size: 22),
              SizedBox(width: 8),
              GestureDetector(
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
            ],
          ),
        ),
      ],
    );
  }

  // Normal Text
  TextSpan _normalText(String text) {
    return TextSpan(text: text);
  }

  // Improved Bullet Point UI
  TextSpan _bulletPoint(String text) {
    return TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.circle, size: 8, color: Colors.blueAccent),
          ),
        ),
        TextSpan(
          text: "$text\n",
          style: TextStyle(height: 1.5),
        ),
      ],
    );
  }
}
