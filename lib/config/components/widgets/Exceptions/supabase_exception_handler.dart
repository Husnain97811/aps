import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class SupabaseExceptionHandler {
  static final Logger _logger = Logger();

  static String handleSupabaseError(dynamic error) {
    _logger.e("Supabase Error: $error");

    if (error is SocketException) {
      return "Network error. Please check your internet connection.";
    } else if (error is PostgrestException) {
      return _handlePostgrestError(error);
    } else if (error is AuthException) {
      return _handleAuthError(error);
    } else if (error is StorageException) {
      return "Storage error: ${error.message}";
    } else {
      return "An unexpected error occurred. Please try again.";
    }
  }

  static String _handlePostgrestError(PostgrestException error) {
    final status = error.code;
    final message = error.message;

    switch (status) {
      case '23505':
        return "Duplicate entry. This record already exists.";
      case '42501':
        return "Permission denied. You don't have access to this resource.";
      case 'P0001':
        return "Database error: $message";
      default:
        return "Database error: ${message ?? 'Unknown error'}";
    }
  }

  static String _handleAuthError(AuthException error) {
    switch (error.statusCode) {
      case '400':
        return "Invalid authentication details";
      case '401':
        return "Unauthorized. Please login again.";
      case '403':
        return "Forbidden. You don't have permission.";
      case '404':
        return "User not found";
      default:
        return "Authentication error: ${error.message}";
    }
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}
