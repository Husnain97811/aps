import 'package:aps/config/components/reuseable_buttons.dart';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? accessToken;
  final String? refreshToken;

  const ResetPasswordScreen({super.key, this.accessToken, this.refreshToken});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent,
              const Color.fromARGB(173, 245, 127, 23),
              AppColors.lightgolden,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Forgot Pass?',
                  style: GoogleFonts.aBeeZee(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black45,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15.sp),
                SizedBox(
                  width: Adaptive.w(40),

                  child: TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: Adaptive.w(40),

                  child: TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: Adaptive.w(20),
                  child: AuthRoundBtn(
                    title: 'Reset',
                    onTap: () {
                      _updatePassword(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updatePassword(BuildContext context) async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Please enter and confirm your new password.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Passwords do not match.',
      );
      return;
    }

    final loadingProvider = context.read<LoadingProvider>();
    loadingProvider.startLoading(); // Start loading

    try {
      // Update the user's password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // Show success message
      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Password updated successfully.',
      );

      // Navigate back to the login screen
      Navigator.pop(context);
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      loadingProvider.stopLoading(); // Stop loading
    }
  }
}
