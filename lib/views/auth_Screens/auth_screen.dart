import 'package:aps/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/view.dart';

class AuthScreen {
  final supabase = Supabase.instance.client;

  // Login function with navigation
  Future<String?> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await SessionService.startSession();
        // Use navigatorKey instead of context-based navigation
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          RouteNames.sidebar,
          (route) => false,
        );
        return null;
      }
      return 'Login failed';
    } catch (error) {
      return error.toString();
    }
  }

  // void checkAuthentication(BuildContext context) {
  //   final user = supabase.auth.currentUser;

  //   if (user != null) {
  //     SessionService.checkExistingSession().then((_) {
  //       if (supabase.auth.currentUser != null) {
  //         navigatorKey.currentState?.pushNamedAndRemoveUntil(
  //           RouteNames.sidebar,
  //           (route) => false,
  //         );
  //       }
  //     });
  //   } else {
  //     Navigator.pushNamedAndRemoveUntil(
  //       context,
  //       RouteNames.loginscreen,
  //       (route) => false,
  //     );
  //   }
  // }

  void checkAuthentication() {
    final user = supabase.auth.currentUser;

    if (user != null) {
      SessionService.checkExistingSession().then((valid) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          RouteNames.sidebar,
          (route) => false,
        );
      });
    } else {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        RouteNames.loginscreen,
        (route) => false,
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    await SessionService.manualLogout();
  }

  // Send OTP for password reset
  // Send OTP instead of magic link
  Future<String?> sendPasswordResetOTP(String email) async {
    try {
      if (!isValidEmail(email)) return 'Invalid email address';

      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,

        // options: AuthOptions(
        //   redirectTo: null, // Disable magic link
        //   otpType: OtpType.email, // Request OTP instead of magic link
        // ),
      );
      return null;
    } catch (e) {
      return SupabaseExceptionHandler.handleSupabaseError(e);
    }
  }

  // Verify OTP
  Future<String?> verifyResetOTP(String email, String otp) async {
    try {
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery, // Use recovery type for password reset
      );

      if (response.session == null) {
        return 'Invalid OTP or session expired';
      }
      return null;
    } catch (e) {
      return SupabaseExceptionHandler.handleSupabaseError(e);
    }
  }

  // Update password after OTP verification
  Future<String?> updatePassword(String newPassword) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 'Session expired. Please try again.';

      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } catch (e) {
      return SupabaseExceptionHandler.handleSupabaseError(e);
    }
  }

  // Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
