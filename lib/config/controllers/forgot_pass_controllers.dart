import 'package:flutter/material.dart';
import 'package:aps/config/view.dart';

class ForgotController extends ChangeNotifier {
  final AuthScreen _authScreen = AuthScreen();
  String? _error;
  String? _email;
  String? _otp;
  String _newPassword = '';
  String _confirmPassword = '';
  int _currentStep = 0; // 0 = email, 1 = OTP, 2 = password

  String? get error => _error;
  int get currentStep => _currentStep;

  // Step 1: Send OTP
  Future<void> sendOTP(BuildContext context, String email) async {
    final loadingProvider = context.read<LoadingProvider>();
    try {
      loadingProvider.startLoading();
      _error = null;
      notifyListeners();

      final error = await _authScreen.sendPasswordResetOTP(email);

      if (error != null) {
        _error = error;
      } else {
        _email = email;
        _currentStep = 1; // Move to OTP verification step
        SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'OTP sent to your email',
        );
      }
    } catch (e) {
      _error = SupabaseExceptionHandler.handleSupabaseError(e);
    } finally {
      loadingProvider.stopLoading();
      notifyListeners();
    }
  }

  // Step 2: Verify OTP
  Future<void> verifyOTP(BuildContext context, String otp) async {
    final loadingProvider = context.read<LoadingProvider>();
    try {
      loadingProvider.startLoading();
      _error = null;
      notifyListeners();

      final error = await _authScreen.verifyResetOTP(_email!, otp);

      if (error != null) {
        _error = error;
      } else {
        _currentStep = 2; // Move to password reset step
        SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'OTP verified successfully',
        );
      }
    } catch (e) {
      _error = SupabaseExceptionHandler.handleSupabaseError(e);
    } finally {
      loadingProvider.stopLoading();
      notifyListeners();
    }
  }

  // Step 3: Reset Password
  Future<void> resetPassword(BuildContext context) async {
    final loadingProvider = context.read<LoadingProvider>();
    try {
      loadingProvider.startLoading();
      _error = null;
      notifyListeners();

      if (_newPassword.isEmpty || _confirmPassword.isEmpty) {
        throw Exception('Please fill all fields');
      }

      if (_newPassword != _confirmPassword) {
        throw Exception('Passwords do not match');
      }

      final error = await _authScreen.updatePassword(_newPassword);

      if (error != null) {
        _error = error;
      } else {
        SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'Password reset successfully',
        );
        Navigator.pop(context); // Return to login screen
      }
    } catch (e) {
      _error = SupabaseExceptionHandler.handleSupabaseError(e);
    } finally {
      loadingProvider.stopLoading();
      notifyListeners();
    }
  }

  void updateNewPassword(String value) {
    _newPassword = value;
    notifyListeners();
  }

  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }
}
