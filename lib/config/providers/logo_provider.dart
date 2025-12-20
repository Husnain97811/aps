import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LogoProvider extends ChangeNotifier {
  Uint8List? _reliableLogo;
  Uint8List? _apldLogo;

  Uint8List? get reliableLogo => _reliableLogo;
  Uint8List? get apldLogo => _apldLogo;

  Future<void> preloadLogos() async {
    // Load both logos at once
    final reliable = rootBundle.load('assets/images/logo_reliable.png');
    final apld = rootBundle.load('assets/images/apld_logo.png');
    
    final results = await Future.wait([reliable, apld]);
    
    _reliableLogo = results[0].buffer.asUint8List();
    _apldLogo = results[1].buffer.asUint8List();
    notifyListeners();
  }
}