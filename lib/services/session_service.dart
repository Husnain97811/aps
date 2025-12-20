import 'dart:async';
import 'package:aps/config/features.dart';
import 'package:aps/config/view.dart';
import 'package:aps/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static late Box _sessionBox;
  // static Timer? _sessionTimer;
  static Timer? _inactivityTimer;
  static final _supabase = Supabase.instance.client;

  // Track logout state to prevent multiple logouts
  static bool _isLoggingOut = false;
  static bool _isInitialized = false;

  static void onTextInput() {
    if (_isLoggingOut || !_isInitialized) return;
    // _resetActivityTime();
    _startInactivityTimer();
  }

  static void onFocusChange() {
    if (_isLoggingOut || !_isInitialized) return;
    // _resetActivityTime();
    _startInactivityTimer();
  }

  static DateTime? getLastActivityTime() {
    if (!_isInitialized) return null;
    try {
      return _sessionBox.get('lastActivityTime');
    } catch (e) {
      return null;
    }
  }

  static Future<void> init() async {
    try {
      _sessionBox = await _openSessionBox();
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print("Session initialization error: $e");
      }
      await _handleCorruptedBox();
      _isInitialized = true;
    }

    // Clear session data on first run
    await clearSessionData();
  }

  static Future<void> clearSessionData() async {
    if (!_isInitialized) return;

    try {
      await _sessionBox.delete('loginTime');
      await _sessionBox.delete('lastActivityTime');
    } catch (e) {
      if (kDebugMode) {
        print("Error clearing session data: $e");
      }
    }
  }

  static Future<Box> _openSessionBox() async {
    try {
      return await Hive.openBox(
        'sessionBox1',
        encryptionCipher: HiveAesCipher(Hive.generateSecureKey()),
      );
    } catch (e) {
      // Handle case where box might be already open
      if (Hive.isBoxOpen('sessionBox1')) {
        return Hive.box('sessionBox1');
      }
      rethrow;
    }
  }

  static Future<void> _handleCorruptedBox() async {
    try {
      // Close if open
      if (Hive.isBoxOpen('sessionBox1')) {
        await Hive.box('sessionBox1').close();
      }

      // Delete corrupted box
      await Hive.deleteBoxFromDisk('sessionBox1');

      // Recreate new box
      _sessionBox = await Hive.openBox(
        'sessionBox1',
        encryptionCipher: HiveAesCipher(Hive.generateSecureKey()),
      );
    } catch (e) {
      // Final fallback - use in-memory box
      _sessionBox = await Hive.openBox(
        'sessionBox1',
        encryptionCipher: HiveAesCipher(Hive.generateSecureKey()),
        // backend: HiveStorageBackendMemory(),
      );
    }
  }

  static Future<void> startSession() async {
    if (!_isInitialized) return;

    // ONLY track last activity time
    // _resetActivityTime();
    _startInactivityTimer();
  }

  // static void _startSessionTimer(DateTime loginTime) {
  //   _sessionTimer?.cancel();

  //   final logoutTime = loginTime.add(const Duration(minutes: 1));
  //   final remainingTime = logoutTime.difference(DateTime.now());

  //   if (remainingTime.isNegative) {
  //     _logout();
  //   } else {
  //     _sessionTimer = Timer(remainingTime, _logout);
  //   }
  // }

  static void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 10), _logout);
  }

  static void resetInactivityTimer() {
    if (_isLoggingOut || !_isInitialized) return;

    // _resetActivityTime();
    _startInactivityTimer();
  }

  static Future<bool> checkExistingSession() async {
    if (_isLoggingOut || !_isInitialized) return false;

    try {
      final lastActivityTime = _sessionBox.get('lastActivityTime');
      if (lastActivityTime == null) return false;

      final inactiveDuration = DateTime.now().difference(lastActivityTime);
      if (inactiveDuration >= const Duration(minutes: 10)) {
        await _logout();
        return false;
      }

      // Reset timer with remaining time
      final remainingTime = const Duration(minutes: 10) - inactiveDuration;
      _startInactivityTimer();

      return true;
    } catch (e) {
      if (kDebugMode) print("Session check error: $e");
      return false;
    }
  }

  static void appResumed() {
    if (_isLoggingOut || !_isInitialized) return;

    try {
      final lastActivityTime = _sessionBox.get('lastActivityTime');
      if (lastActivityTime != null) {
        final inactiveDuration = DateTime.now().difference(lastActivityTime);
        if (inactiveDuration >= const Duration(minutes: 10)) {
          _logout();
        } else {
          final remainingTime = const Duration(minutes: 10) - inactiveDuration;
          _startInactivityTimer();
        }
      }
    } catch (e) {
      if (kDebugMode) print("App resume error: $e");
    }
  }

  static Future<void> appClosed() async {
    if (!_isInitialized) return;

    try {
      await _sessionBox.put('wasTerminated', true);

      // Clear session data
      await _sessionBox.delete('loginTime');
      await _sessionBox.delete('lastActivityTime');

      // Sign out from Supabase
      if (_supabase.auth.currentUser != null) {
        await _supabase.auth.signOut();
      }
    } catch (e) {
      if (kDebugMode) {
        print("App close logout error: $e");
      }
    } finally {
      // _sessionTimer?.cancel();
      _inactivityTimer?.cancel();
    }
  }

  static Future<bool> wasAppTerminated() async {
    if (!_isInitialized) return false;
    try {
      final terminated = _sessionBox.get('wasTerminated', defaultValue: false);
      await _sessionBox.put('wasTerminated', false); // Reset flag
      return terminated;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      // Only sign out if user is logged in
      if (_supabase.auth.currentUser != null) {
        await _supabase.auth.signOut().then((_) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            RouteNames.loginscreen,
            (route) => false,
          );
        });
      }

      // Clear session data if box is accessible
      try {
        await _sessionBox.delete('loginTime');
        await _sessionBox.delete('lastActivityTime');
      } catch (e) {
        // Ignore box errors during logout
      }

      // _sessionTimer?.cancel();
      _inactivityTimer?.cancel();

      // Use navigatorKey for safe navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            RouteNames.loginscreen,
            (route) => false,
          );
        }
      });
    } finally {
      _isLoggingOut = false;
    }
  }

  static Future<void> manualLogout() async {
    await _logout();
  }
}
