import 'package:aps/config/components/reuseable_buttons.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:aps/config/controllers/forgot_pass_controllers.dart';
import 'package:aps/config/view.dart';

class PasswordResetFlowScreen extends StatefulWidget {
  const PasswordResetFlowScreen({super.key});

  @override
  State<PasswordResetFlowScreen> createState() =>
      _PasswordResetFlowScreenState();
}

class _PasswordResetFlowScreenState extends State<PasswordResetFlowScreen> {
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
                return Container(
                  alignment: Alignment.center,
                  width: double.infinity,
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
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: IndexedStack(
                      alignment: Alignment.center,
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
          'Enter Email to reset your pass!',
          style: GoogleFonts.aBeeZee(
            fontSize: 15.sp,
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
        SizedBox(height: 20.sp),
        SizedBox(
          width: Adaptive.w(40),
          child: TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              labelText: 'Email',
              errorText: provider.error,
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        SizedBox(height: 20.sp),
        SizedBox(
          width: 17.w,
          child: AuthRoundBtn(
            title: 'Send OTP',
            onTap: () => provider.sendOTP(context, emailController.text.trim()),
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
          'Enter the OTP sent to\n${emailController.text}',
          textAlign: TextAlign.center,
          style: GoogleFonts.aBeeZee(
            fontSize: 13.sp,
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

        SizedBox(height: 20.sp),
        SizedBox(
          width: Adaptive.w(40),
          child: TextFormField(
            controller: otpController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              labelText: '6-digit OTP',
              errorText: provider.error,
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_clock),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
        ),
        SizedBox(height: 20.sp),
        SizedBox(
          // width: double.infinity,
          child: AuthRoundBtn(
            title: 'Verify OTP',
            onTap: () => provider.verifyOTP(context, otpController.text.trim()),
          ),
        ),
        TextButton(
          onPressed: () {
            // provider.currentStep = 0; // Reset to email step
            provider.sendOTP(
              context,
              emailController.text.trim(),
            ); // Resend OTP
          },
          child: Text('Resend OTP', style: TextStyle(fontSize: 14.sp)),
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
        SizedBox(
          width: Adaptive.w(40),
          child: TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),

              labelText: 'New Password',
              errorText: provider.error,
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            onChanged: provider.updateNewPassword,
          ),
        ),
        SizedBox(height: 20.sp),

        SizedBox(
          width: Adaptive.w(40),
          child: TextFormField(
            controller: confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_reset),
            ),
            obscureText: true,
            onChanged: provider.updateConfirmPassword,
          ),
        ),
        SizedBox(height: 20.sp),
        SizedBox(
          // width: double.infinity,
          child: AuthRoundBtn(
            title: 'Reset Password',
            onTap: () => provider.resetPassword(context),
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
