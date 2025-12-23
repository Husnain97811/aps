import 'package:aps/config/components/reuseable_buttons.dart';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isHovering = false;
  final AuthScreen _authScreen = AuthScreen();
  final FocusNode _submitFocusNode = FocusNode();

  // Handle login button press
  void handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final error = await _authScreen.login(context, email, password);

    if (error != null) {
      // Show error message if login fails
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text(error)));
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(error);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'APS!',
                      style: GoogleFonts.aBeeZee(
                        fontSize: 23.sp,
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
                    SizedBox(height: 4.h),
                    SizedBox(
                      width: Adaptive.w(40),
                      child: TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          // Add more email validation if needed
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                        onChanged: (_) => SessionService.resetInactivityTimer(),
                        onTap: () => SessionService.resetInactivityTimer(),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    SizedBox(
                      width: Adaptive.w(40),
                      child: Focus(
                        onKey: (node, event) {
                          if (event.logicalKey == LogicalKeyboardKey.enter) {
                            _submitFocusNode.requestFocus();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            // Add more password validation if needed
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                              child: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                          ),
                          onChanged:
                              (_) => SessionService.resetInactivityTimer(),
                          onTap: () => SessionService.resetInactivityTimer(),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _isHovering = true; // Change hover state
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _isHovering = false; // Reset hover state
                        });
                      },
                      child: Consumer<AuthStateNotifier>(
                        builder: (context, authNotifier, child) {
                          if (authNotifier.state == AppAuthState.loading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return AuthRoundBtn(
                            focusNode: _submitFocusNode,

                            title: 'Login',
                            onTap: () async {
                              if (_formKey.currentState!.validate()) {
                                final email = _emailController.text.trim();
                                final password =
                                    _passwordController.text.trim();

                                // Set loading state
                                authNotifier.setState(AppAuthState.loading);

                                try {
                                  final error = await authNotifier.login(
                                    context,
                                    email,
                                    password,
                                  );

                                  if (error != null) {
                                    final errorMessage =
                                        SupabaseExceptionHandler.handleSupabaseError(
                                          error,
                                        );
                                    SupabaseExceptionHandler.showErrorSnackbar(
                                      context,
                                      errorMessage,
                                    );
                                  } else {
                                    // Refresh session after successful login
                                    await Supabase.instance.client.auth
                                        .refreshSession();
                                  }
                                } catch (e) {
                                  SupabaseExceptionHandler.showErrorSnackbar(
                                    context,
                                    'Login Failed\n $e',
                                  );
                                } finally {
                                  // Reset loading state
                                  authNotifier.setState(AppAuthState.idle);
                                }
                              }
                            },
                            backgroundColor:
                                _isHovering ? Colors.blueAccent : Colors.blue,
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 4.h),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.resetpassflowScreen,
                        );
                        // Navigate to Forgot Password screen
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 12.sp,
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () async {
            const url = 'https://www.inoverstudio.com/';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          label: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [
                  Colors.blueAccent,
                  Color.fromRGBO(98, 34, 148, 1),
                  Color.fromRGBO(98, 34, 148, 1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Text(
              '@ Inover Studio',
              style: GoogleFonts.akayaKanadaka(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white, // This will be masked by the shader
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
        ),
      ),
    );
  }
}
