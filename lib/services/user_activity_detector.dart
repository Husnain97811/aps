// user_activity_detector.dart
import 'package:flutter/material.dart';
import 'package:aps/services/session_service.dart';
import 'package:flutter/services.dart';

class UserActivityDetector extends StatefulWidget {
  final Widget child;

  const UserActivityDetector({super.key, required this.child});

  @override
  State<UserActivityDetector> createState() => _UserActivityDetectorState();
}

class _UserActivityDetectorState extends State<UserActivityDetector> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      SessionService.resetInactivityTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: Focus(
        focusNode: _focusNode,
        canRequestFocus: true,
        skipTraversal: true,
        onKey: (node, event) {
          // Reset timer on any key press
          if (event is RawKeyDownEvent) {
            SessionService.resetInactivityTimer();
          }
          return KeyEventResult.ignored;
        },
        child: Listener(
          onPointerDown: (_) => SessionService.resetInactivityTimer(),
          onPointerMove: (_) => SessionService.resetInactivityTimer(),
          onPointerHover: (_) => SessionService.resetInactivityTimer(),
          onPointerUp: (_) => SessionService.resetInactivityTimer(),

          behavior: HitTestBehavior.translucent,
          child: widget.child,
        ),
      ),
    );
  }
}
