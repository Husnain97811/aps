import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aps/config/components/reuseable_buttons.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Get Supabase client
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignUpState(),
      child: Scaffold(
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
          child: Consumer<SignUpState>(
            builder: (context, state, _) {
              return Stack(
                children: [
                  // Back button
                  Positioned(
                    top: 2.h,
                    left: 1.w,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        // size: 30.sp,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 10.h),
                              Text(
                                'Create Account',
                                style: GoogleFonts.aBeeZee(
                                  fontSize: 23.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black45,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4.h),

                              // Full Name Field
                              SizedBox(
                                width: 40.w,
                                child: TextFormField(
                                  controller: _nameController,
                                  validator:
                                      (value) =>
                                          value!.isEmpty
                                              ? 'Please enter your name'
                                              : null,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    hintText: 'Enter your full name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    prefixIcon: const Icon(Icons.person),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2.h),

                              // Email Field
                              SizedBox(
                                width: 40.w,
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value!.isEmpty)
                                      return 'Please enter your email';
                                    if (!value.contains('@'))
                                      return 'Please enter a valid email';
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
                                ),
                              ),
                              SizedBox(height: 2.h),

                              // Password Field
                              SizedBox(
                                width: 40.w,
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: state.obscurePassword,
                                  validator: (value) {
                                    if (value!.isEmpty)
                                      return 'Please enter a password';
                                    if (value.length < 6)
                                      return 'Password must be at least 6 characters';
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        state.obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed:
                                          () =>
                                              state.togglePasswordVisibility(),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2.h),

                              // Confirm Password Field
                              SizedBox(
                                width: 40.w,
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: state.obscureConfirmPassword,
                                  validator: (value) {
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    hintText: 'Confirm your password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        state.obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed:
                                          () =>
                                              state
                                                  .toggleConfirmPasswordVisibility(),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              SizedBox(height: 2.h),

                              // Account Type Dropdown
                              SizedBox(
                                width: 40.w,
                                child: DropdownButtonFormField<String>(
                                  value: state.selectedAccountType,
                                  hint: const Text('Select Account Type'),
                                  items:
                                      const [
                                            'admin',
                                            'accountant',
                                            'manager',
                                            'employee',
                                            'client',
                                          ]
                                          .map(
                                            (type) => DropdownMenuItem(
                                              value: type,
                                              child: Text(type),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (value) => state.setAccountType(value!),
                                  validator:
                                      (value) =>
                                          value == null
                                              ? 'Please select an account type'
                                              : null,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    prefixIcon: const Icon(Icons.account_tree),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                              SizedBox(height: 4.h),

                              // Sign Up Button with Loading State
                              Consumer<LoadingProvider>(
                                builder: (context, loadingProvider, _) {
                                  return MouseRegion(
                                    onEnter: (_) => state.setHovering(true),
                                    onExit: (_) => state.setHovering(false),
                                    child: AuthRoundBtn(
                                      title: 'Sign Up',
                                      onTap:
                                          loadingProvider.isLoading
                                              ? null
                                              : () => _submitForm(context),
                                      backgroundColor:
                                          state.isHovering
                                              ? Colors.blueAccent
                                              : Colors.blue,
                                      loading: loadingProvider.isLoading,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 2.h),

                              // Login Redirect
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Already have an account? Sign In',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.white,
                                    shadows: const [
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final state = Provider.of<SignUpState>(context, listen: false);
    if (state.selectedAccountType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account type')),
      );
      return;
    }

    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startLoading();

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final accountType = state.selectedAccountType!;

      // Check if user already exists
      final existingUsers = await supabase
          .from('profiles')
          .select()
          .eq('email', email);

      if (existingUsers.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User already exists. Please sign in.')),
        );
        return;
      }

      // Create user in Supabase Auth with metadata
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'account_type': accountType, 'full_name': name},
        emailRedirectTo: 'YOUR_APP_REDIRECT_URL',
      );

      final user = res.user;
      if (user == null) {
        // Handle email confirmation needed case
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your email for confirmation!')),
        );
        return;
      }

      // // Try to insert profile, handle duplicate key error
      // try {
      //   await supabase.from('profiles').insert({
      //     'id': user.id,
      //     'email': email,
      //     'full_name': name,
      //     'account_type': accountType,
      //     'created_at': DateTime.now().toIso8601String(),
      //   });
      // } on PostgrestException catch (e) {
      //   if (e.code == '23505') {
      //     // Duplicate key error
      //     debugPrint('Profile already exists, skipping insertion');
      //   } else {
      //     rethrow;
      //   }
      // }

      // Show success message
      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Account created successfully!',
      );

      // Navigate to home/dashboard
      Navigator.pushReplacementNamed(context, RouteNames.sidebar);
    } on AuthException catch (e) {
      // Handle specific errors
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Something went wrong.\n Contact Developer',
      );
    } on PostgrestException catch (e) {
      // Handle PostgREST errors
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Something went wrong.\n Contact Developer for db error solution\n $e',
      );
    } catch (e) {
      // Handle generic errors
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Something went wrong.\n Contact Developer',
      );
    } finally {
      loadingProvider.stopLoading();
    }
  }
}

class SignUpState extends ChangeNotifier {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isHovering = false;
  String? _selectedAccountType;

  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get isHovering => _isHovering;
  String? get selectedAccountType => _selectedAccountType;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void setHovering(bool value) {
    _isHovering = value;
    notifyListeners();
  }

  void setAccountType(String value) {
    _selectedAccountType = value;
    notifyListeners();
  }
}
