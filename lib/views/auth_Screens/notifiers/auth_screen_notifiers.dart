import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/view.dart';

enum AppAuthState { idle, loading } // Reused for both login and logout

class AuthStateNotifier extends ChangeNotifier {
  AppAuthState _state = AppAuthState.idle;

  AppAuthState get state => _state;

  final AuthScreen _authScreen = AuthScreen();

  void setState(AppAuthState state) {
    _state = state;
    notifyListeners(); // Notify widgets listening to this state
  }

  // Login function with state management
  Future<String?> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    setState(AppAuthState.loading);
    await Future.delayed(Duration(seconds: 2));
    final error = await _authScreen.login(context, email, password);
    // Add this critical refresh
    await Supabase.instance.client.auth.refreshSession();
    setState(AppAuthState.idle); // Reset state after login

    return error; // Return the error (if any)
  }

  // Logout function with state management
  Future<void> logout(BuildContext context) async {
    setState(AppAuthState.loading);
    await Future.delayed(Duration(seconds: 2)); // Simulate loading
    await _authScreen.logout(context);
    setState(AppAuthState.idle);
  }
}
