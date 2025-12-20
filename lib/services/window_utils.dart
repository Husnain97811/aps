// import 'package:flutter/material.dart';
// import 'package:window_manager/window_manager.dart';

// class WindowUtils {
//   static Future<void> ensureWindowVisible() async {
//     try {
//       await windowManager.ensureInitialized();
//       await windowManager.setAsFrameless();
//       await windowManager.setSize(const Size(1, 1));
//       await windowManager.setPosition(Offset.zero);
//       await windowManager.show();
//       await windowManager.focus();
//       await windowManager.setAlwaysOnTop(true);
//       await Future.delayed(const Duration(milliseconds: 100));
//       await windowManager.setAlwaysOnTop(false);
//       await windowManager.setSize(const Size(1280, 720));
//       await windowManager.center();
//     } catch (e) {
//       debugPrint('Window visibility error: $e');
//     }
//   }
// }
