// admin_verification.dart
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminVerification {
  static final _supabase = Supabase.instance.client;

  // List of pre-verified admin emails that don't need password
  static const List<String> _preVerifiedEmails = [
    'info.rmnsoftware@gmail.com', // Replace with your actual admin email
    'hussnainahmed97@gmail.com', // Add more as needed
  ];

  static Future<bool> showVerificationDialog({
    required BuildContext context,
    required String action,
  }) async {
    final currentUserEmail =
        _supabase.auth.currentUser?.email?.toLowerCase() ?? '';

    // Check if current user is pre-verified admin
    if (_preVerifiedEmails.contains(currentUserEmail)) {
      return true; // Automatically verified without password
    }

    // For non-preverified users, show password dialog
    return await _showPasswordVerificationDialog(
      context: context,
      action: action,
    );
  }

  static Future<bool> _showPasswordVerificationDialog({
    required BuildContext context,
    required String action,
  }) async {
    bool verified = false;
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Consumer<LoadingProvider>(
            builder: (context, loadingProvider, child) {
              return AlertDialog(
                title: const Text('Admin Verification'),
                content: LoadingOverlay(
                  // isLoading: loadingProvider.isLoading,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Enter admin password to $action'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Admin Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        loadingProvider.isLoading
                            ? null
                            : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed:
                        loadingProvider.isLoading
                            ? null
                            : () async {
                              final provider = Provider.of<LoadingProvider>(
                                context,
                                listen: false,
                              );

                              try {
                                provider.startLoading();
                                final response = await _supabase.rpc(
                                  'verify_admin_password',
                                  params: {
                                    'input_password': passwordController.text,
                                  },
                                );

                                if (response == true) {
                                  verified = true;
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid admin password'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                  ),
                                );
                              } finally {
                                provider.stopLoading();
                              }
                            },
                    child: const Text('Verify'),
                  ),
                ],
              );
            },
          ),
    );

    return verified;
  }
}
