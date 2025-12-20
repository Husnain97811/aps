import 'dart:ui';

import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';

import 'package:provider/provider.dart';

import 'dart:async'; // <<< 1. Import the async library for the Timer
import 'dart:ui';
import 'package:flutter/material.dart';

// No changes to other imports or file structure

class LoadingProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isPdfLoading = false;

  // <<< 2. Add a nullable Timer variable to hold our timeout timer.
  Timer? _loadingTimer;

  bool get isLoading => _isLoading;
  bool get isPdfLoading => _isPdfLoading;

  void startLoading() {
    _isLoading = true;
    _startTimeoutTimer(); // <<< 3. Start the timeout when loading starts
    notifyListeners();
  }

  void stopLoading() {
    _isLoading = false;
    _cancelTimeoutTimerIfNeeded(); // <<< 4. Try to cancel the timer when loading stops
    notifyListeners();
  }

  void startPdfLoading() {
    _isPdfLoading = true;
    _startTimeoutTimer(); // <<< 3. Start the timeout when loading starts
    notifyListeners();
  }

  void stopPdfLoading() {
    _isPdfLoading = false;
    _cancelTimeoutTimerIfNeeded(); // <<< 4. Try to cancel the timer when loading stops
    notifyListeners();
  }

  // <<< 5. A helper method to start the timer.
  void _startTimeoutTimer() {
    // If a timer is already running, cancel it to reset the countdown.
    _loadingTimer?.cancel();

    // Start a new 10-second timer.
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      // This code will run IF the timer is not cancelled within 10 seconds.
      print("Loading timed out after 10 seconds. Forcing stop.");

      // Check if the provider is still active before trying to update state
      if (_isLoading || _isPdfLoading) {
        _isLoading = false;
        _isPdfLoading = false;
        notifyListeners(); // Update the UI to hide the overlay
      }
    });
  }

  // <<< 6. A helper method to cancel the timer ONLY if all loading is complete.
  void _cancelTimeoutTimerIfNeeded() {
    // If there is no active loading process, we can safely cancel the timer.
    if (!_isLoading && !_isPdfLoading) {
      _loadingTimer?.cancel();
    }
  }

  // It's good practice to cancel any active timers when the provider is disposed.
  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }
}

class ProviderLoadingWidget extends StatelessWidget {
  final Color? loaderColor;
  final double? size;
  final String? loadingText;

  const ProviderLoadingWidget({
    super.key,
    this.loaderColor,
    this.size,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = loaderColor ?? theme.primaryColor;
    final loaderSize = size ?? 50.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: loaderSize,
            width: loaderSize,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.circularcolor,
                ),
                backgroundColor: AppColors.darkbrown,
              ),
            ),
          ),

          if (loadingText != null) ...[
            const SizedBox(height: 20),
            Text(
              loadingText!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final Color? overlayColor;
  final double? blur;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.overlayColor,
    this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Listen to both isLoading and isPdfLoading
        Selector<LoadingProvider, bool>(
          selector:
              (_, provider) => provider.isLoading || provider.isPdfLoading,
          builder: (context, isLoading, child) {
            if (!isLoading) return const SizedBox.shrink();

            return ModalBarrier(
              color: overlayColor ?? Colors.black.withOpacity(0.4),
              dismissible: false,
            );
          },
        ),
        // Separate selector for the loading widget to ensure it's always on top
        Selector<LoadingProvider, bool>(
          selector:
              (_, provider) => provider.isLoading || provider.isPdfLoading,
          builder: (context, isLoading, child) {
            if (!isLoading) return const SizedBox.shrink();

            return Center(child: ProviderLoadingWidget());
          },
        ),
      ],
    );
  }
}
