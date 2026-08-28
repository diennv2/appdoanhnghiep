







  // class AuthHelper {
  //
  //
  //   /// Sign-up function to register a new user
  //   Future<void> signUp({required String email, required String password, required BuildContext context, required String name, String? fullPhoneNumber,}) async {
  //     if (email.isEmpty || password.isEmpty || name.isEmpty) {
  //       if (context.mounted) {
  //         CustomSnackbar.show(context: context, label: "Fields can't be null");
  //       }
  //       return;
  //     }
  //
  //     try {
  //       FirebaseAuth auth = FirebaseAuth.instance;
  //       UserCredential userCred = await auth.createUserWithEmailAndPassword(
  //         email: email,
  //         password: password,
  //       );
  //
  //
  //
  //
  //
  //
  //       // Updating Firebase Name
  //       await userCred.user?.updateDisplayName(name);
  //       await userCred.user?.reload();
  //
  //       final user = auth.currentUser;
  //
  //       if (user != null && !user.emailVerified) {
  //         try {
  //           await user.sendEmailVerification();
  //
  //           // Navigate to Verification Page
  //           if (context.mounted) {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => VerificationPage(user: user),
  //               ),
  //             );
  //           }
  //         } on FirebaseAuthException catch (error) {
  //           if (context.mounted) {
  //             CustomSnackbar.show(
  //               context: context,
  //               label: getFirebaseErrorMessage(error.code),
  //             );
  //           }
  //         }
  //       } else if (user?.emailVerified ?? false) {
  //         if (context.mounted) {
  //           String lastName =
  //               name.split(' ').isNotEmpty ? name.split(' ').last : "";
  //           CustomAlertBox().showCustomAnimatedAlert(
  //             context: context,
  //             title: "🎉 Congratulations $lastName",
  //             label: "Your account is ready to use",
  //             user: userCred.user!,
  //           );
  //         }
  //       }
  //     } on FirebaseAuthException catch (error) {
  //       if (context.mounted) {
  //         CustomSnackbar.show(
  //           context: context,
  //           label: getFirebaseErrorMessage(error.code),
  //         );
  //       }
  //     }
  //   }
  //
  //   // Send Verification Link
  //   static Future<void> sendVerificationEmail(BuildContext context) async {
  //     try {
  //       final  user = FirebaseAuth.instance.currentUser;
  //
  //       if (user == null) {
  //         if (context.mounted) {
  //           CustomSnackbar.show(
  //             context: context,
  //             label: "No user is logged in. Please log in first.",
  //           );
  //         }
  //         return;
  //       } else if (!user.emailVerified) {
  //         await user.sendEmailVerification();
  //         if (context.mounted) {
  //           CustomSnackbar.show(
  //             title: '🎉 Woohoo! All Done!',
  //             context: context,
  //             label: 'Verification email sent successfully!',
  //             color: Color(0xE04CAF50),
  //             svgColor: Color(0xE0178327),
  //           );
  //         }
  //       }
  //     } on FirebaseAuthException catch (e) {
  //       if (context.mounted) {
  //         CustomSnackbar.show(
  //           context: context,
  //           label: getFirebaseErrorMessage(e.code),
  //         );
  //       }
  //     }
  //   }
  //
  //   static const int maxRetries = 3;
  //   static int retryCount = 0;
  //   Future<void> logIn(
  //     BuildContext context,
  //     String email,
  //     String password,
  //   ) async {
  //     try {
  //       UserCredential userCred = await FirebaseAuth.instance
  //           .signInWithEmailAndPassword(email: email, password: password);
  //
  //
  //
  //       if (context.mounted) {
  //         String lastName = userCred.user?.displayName?.split(' ').last ?? "";
  //         CustomAlertBox().showCustomAnimatedAlert(
  //           context: context,
  //           title: "Welcome back, $lastName",
  //           label: "The office missed you. Let’s get productive!",
  //           user: userCred.user!,
  //         );
  //       }
  //     } on FirebaseAuthException catch (error) {
  //       retryCount++;
  //       if (context.mounted) {
  //         CustomSnackbar.show(
  //           context: context,
  //           label: getFirebaseErrorMessage(error.code),
  //         );
  //       }
  //       if (retryCount > maxRetries || error.code == 'too-many-requests') {
  //         if (context.mounted) {
  //           CustomSnackbar.show(
  //             context: context,
  //             label: "Too many failed attempts. Please try again later.",
  //           );
  //         }
  //         retryCount = 0;
  //       }
  //     }
  //   }
  //
  //   static String getFirebaseErrorMessage(String errorCode) {
  //     switch (errorCode) {
  //       case 'invalid-email':
  //         return 'Invalid email format. Please enter a valid email.';
  //       case 'user-not-found':
  //         return 'No user found with this email. Please check or sign up.';
  //       case 'wrong-password':
  //         return 'Incorrect password. Please try again.';
  //       case 'email-already-in-use':
  //         return 'This email is already registered. Try logging in.';
  //       case 'weak-password':
  //         return 'Password is too weak. Use at least 6 characters.';
  //       case 'too-many-requests':
  //         return 'Too many failed login attempts. Please try again later.';
  //       default:
  //         return 'An unexpected error occurred. Please try again.';
  //     }
  //   }
  //
  //   Future<void> loginWithGoogle(BuildContext context) async {
  //     try {
  //       final googleUser = await GoogleSignIn().signIn();
  //       if (googleUser == null) {
  //         if (context.mounted) {
  //           CustomSnackbar.show(
  //             context: context,
  //             label: "Sign-in canceled. Please try again.",
  //           );
  //         }
  //         return;
  //       }
  //       final googleAuth = await googleUser.authentication;
  //       if (googleAuth.idToken == null || googleAuth.accessToken == null) {
  //         if (context.mounted) {
  //           CustomSnackbar.show(
  //             context: context,
  //             label: "Authentication failed. Please try again.",
  //           );
  //         }
  //         return;
  //       }
  //
  //       final googleCredential = GoogleAuthProvider.credential(
  //         idToken: googleAuth.idToken,
  //         accessToken: googleAuth.accessToken,
  //       );
  //
  //
  //
  //
  //
  //
  //
  //       UserCredential userCredential = await FirebaseAuth.instance
  //           .signInWithCredential(googleCredential);
  //
  //
  //
  //       await userCredential.user?.updateDisplayName(googleUser.displayName);
  //       await userCredential.user?.reload();
  //
  //       if (context.mounted) {
  //         String lastName =
  //             userCredential.user?.displayName?.split(' ').last ?? "";
  //         CustomAlertBox().showCustomAnimatedAlert(
  //           context: context,
  //           title: "🎉 Welcome, $lastName!",
  //           label: "Your account is successfully created using Google.",
  //           user: userCredential.user!,
  //         );
  //       }
  //     } on FirebaseAuthException catch (e) {
  //       if (context.mounted) {
  //         CustomSnackbar.show(
  //           context: context,
  //           label: getFirebaseErrorMessage(e.code),
  //         );
  //       }
  //     }
  //   }
  //
  //   Future<bool> isUserSignedInWithGoogle() async {
  //     final user = FirebaseAuth.instance.currentUser;
  //
  //     if (user != null) {
  //       for (var profile in user.providerData) {
  //         if (profile.providerId == "google.com") {
  //           return true;
  //         }
  //       }
  //     }
  //
  //     return false;
  //   }
  //
  //   Future<void> resetPassword({
  //     required BuildContext context,
  //     required String email,
  //   }) async {
  //     if (email.isEmpty) {
  //       if (context.mounted) {
  //         CustomSnackbar.show(context: context, label: "Email can't be null");
  //       }
  //       return;
  //     }
  //
  //     try {
  //       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  //       if (context.mounted) {
  //         CustomSnackbar.show(
  //           context: context,
  //           label: "📩 Boom! Reset instructions are flying to your inbox now!",
  //           color: Color(0xE04CAF50),
  //           svgColor: Color(0xE0178327),
  //         );
  //       }
  //     } on FirebaseAuthException catch (error) {
  //       if (context.mounted) {
  //         CustomSnackbar.show(
  //           context: context,
  //           label: getFirebaseErrorMessage(error.code),
  //         );
  //       }
  //     }
  //   }
  // }
