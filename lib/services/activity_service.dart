// import 'package:aps/config/view.dart';
// import 'package:aps/main.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// // lib/services/activity_service.dart
// import 'dart:async';
// import 'package:flutter/material.dart';

// class ActivityService with WidgetsBindingObserver {
//   Timer? _inactivityTimer;
//   final int _inactivityTimeout = 10; // 10 seconds for testing
//   final SupabaseClient _supabase = Supabase.instance.client;
//   DateTime _lastActivityTime = DateTime.now();
//   bool _isActive = true;
//   ValueNotifier<String> status = ValueNotifier('Initializing...');

//   void startTracking() {
//     status.value = 'Tracking started';
//     _resetTimer();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   void _resetTimer() {
//     _lastActivityTime = DateTime.now();
//     _inactivityTimer?.cancel();
//     status.value = 'Timer reset at ${_lastActivityTime.second}s';

//     _inactivityTimer = Timer(
//       Duration(seconds: _inactivityTimeout),
//       _checkInactivity,
//     );
//   }

//   void _checkInactivity() {
//     final inactiveSeconds =
//         DateTime.now().difference(_lastActivityTime).inSeconds;
//     status.value = 'Checking: $inactiveSeconds/${_inactivityTimeout}s inactive';

//     if (inactiveSeconds >= _inactivityTimeout) {
//       status.value = 'Timeout reached - logging out';
//       _logout();
//     } else {
//       _inactivityTimer = Timer(
//         Duration(seconds: _inactivityTimeout - inactiveSeconds),
//         _checkInactivity,
//       );
//     }
//   }

//   void recordActivity() {
//     if (!_isActive) return;
//     status.value = 'Activity detected';
//     _resetTimer();
//   }

//   void _logout() {
//     _isActive = false;
//     _inactivityTimer?.cancel();
//     status.value = 'Logging out...';

//     _supabase.auth
//         .signOut()
//         .then((_) {
//           status.value = 'Signed out - navigating';
//           navigatorKey.currentState?.pushNamedAndRemoveUntil(
//             RouteNames.loginscreen,
//             (route) => false,
//           );
//         })
//         .catchError((e) {
//           status.value = 'Logout error: $e';
//         });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     print('[ActivityService] App state changed: $state');

//     // Only log out when app is fully terminated (detached)
//     if (state == AppLifecycleState.detached) {
//       _clearSessionOnExit();
//     } else if (state == AppLifecycleState.resumed) {
//       recordActivity(); // Reset timer on app resume
//     }
//   }

//   // New method: Clear session without navigation
//   void _clearSessionOnExit() {
//     _isActive = false;
//     _inactivityTimer?.cancel();
//     _supabase.auth.signOut(); // Critical: Clears session tokens
//     print("Session cleared on app termination");
//   }

//   void dispose() {
//     _inactivityTimer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//   }
// }

// class ActivityTrackerWrapper extends StatefulWidget {
//   final Widget child;
//   final ActivityService activityService;

//   const ActivityTrackerWrapper({
//     super.key,
//     required this.child,
//     required this.activityService,
//   });

//   @override
//   State<ActivityTrackerWrapper> createState() => _ActivityTrackerWrapperState();
// }

// class _ActivityTrackerWrapperState extends State<ActivityTrackerWrapper> {
//   final FocusNode _focusNode = FocusNode();
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();
//     _focusNode.requestFocus();
//     _scrollController.addListener(_handleScroll);
//   }

//   @override
//   void dispose() {
//     _focusNode.dispose();
//     _scrollController.removeListener(_handleScroll);
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _handleScroll() {
//     widget.activityService.recordActivity();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FocusScope(
//       autofocus: true,
//       child: Listener(
//         onPointerDown: (_) {
//           print('[ActivityTracker] Pointer down event');
//           widget.activityService.recordActivity();
//         },
//         onPointerMove: (_) {
//           print('[ActivityTracker] Pointer move event');
//           widget.activityService.recordActivity();
//         },
//         onPointerUp: (_) {
//           print('[ActivityTracker] Pointer up event');
//           widget.activityService.recordActivity();
//         },
//         child: GestureDetector(
//           behavior: HitTestBehavior.translucent,
//           onTap: () {
//             print('[ActivityTracker] Tap event');
//             widget.activityService.recordActivity();
//           },
//           onDoubleTap: () {
//             print('[ActivityTracker] Double tap event');
//             widget.activityService.recordActivity();
//           },
//           onLongPress: () {
//             print('[ActivityTracker] Long press event');
//             widget.activityService.recordActivity();
//           },
//           onPanUpdate: (_) {
//             print('[ActivityTracker] Pan update event');
//             widget.activityService.recordActivity();
//           },
//           child: MouseRegion(
//             onHover: (_) {
//               print('[ActivityTracker] Mouse hover event');
//               widget.activityService.recordActivity();
//             },
//             child: RawKeyboardListener(
//               focusNode: _focusNode,
//               onKey: (event) {
//                 print('[ActivityTracker] Key press event');
//                 widget.activityService.recordActivity();
//               },
//               child: NotificationListener<ScrollNotification>(
//                 onNotification: (notification) {
//                   print('[ActivityTracker] Scroll notification');
//                   widget.activityService.recordActivity();
//                   return false;
//                 },
//                 child: widget.child,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
