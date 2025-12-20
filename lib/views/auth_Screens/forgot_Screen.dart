import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:aps/config/controllers/forgot_pass_controllers.dart';
import 'package:aps/config/view.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Password Reset'),
            backgroundColor: AppColors.darkbrown,
          ),
          body: ChangeNotifierProvider(
            create: (_) => ForgotController(),
            child: Consumer<ForgotController>(
              builder: (context, provider, child) {
                return Padding(
                  padding: EdgeInsets.all(16.sp),
                  child: IndexedStack(
                    index: provider.currentStep,
                    children: [
                      // Step 1: Email Input
                      _buildEmailStep(context, provider),
                      // Step 2: OTP Verification
                      _buildOTPStep(context, provider),
                      // Step 3: Password Reset
                      _buildPasswordStep(context, provider),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Step 1: Email Input Screen
  Widget _buildEmailStep(BuildContext context, ForgotController provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Enter your email to reset your password',
          style: TextStyle(fontSize: 14.sp),
        ),
        SizedBox(height: 20.sp),
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: provider.error,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 20.sp),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15.sp),
            ),
            onPressed:
                () => provider.sendOTP(context, emailController.text.trim()),
            child: Text('Send OTP', style: TextStyle(fontSize: 16.sp)),
          ),
        ),
      ],
    );
  }

  // Step 2: OTP Verification Screen
  Widget _buildOTPStep(BuildContext context, ForgotController provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Enter the OTP sent to ${emailController.text}',
          style: TextStyle(fontSize: 14.sp),
        ),
        SizedBox(height: 20.sp),
        TextFormField(
          controller: otpController,
          decoration: InputDecoration(
            labelText: '6-digit OTP',
            errorText: provider.error,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_clock),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        SizedBox(height: 20.sp),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15.sp),
            ),
            onPressed:
                () => provider.verifyOTP(context, otpController.text.trim()),
            child: Text('Verify OTP', style: TextStyle(fontSize: 16.sp)),
          ),
        ),
      ],
    );
  }

  // Step 3: Password Reset Screen
  Widget _buildPasswordStep(BuildContext context, ForgotController provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Set a new password', style: TextStyle(fontSize: 14.sp)),
        SizedBox(height: 20.sp),
        TextFormField(
          controller: passwordController,
          decoration: InputDecoration(
            labelText: 'New Password',
            errorText: provider.error,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
          onChanged: provider.updateNewPassword,
        ),
        SizedBox(height: 20.sp),
        TextFormField(
          controller: confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_reset),
          ),
          obscureText: true,
          onChanged: provider.updateConfirmPassword,
        ),
        SizedBox(height: 20.sp),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15.sp),
            ),
            onPressed: () => provider.resetPassword(context),
            child: Text('Reset Password', style: TextStyle(fontSize: 16.sp)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
