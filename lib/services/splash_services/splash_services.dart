import 'dart:async';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';

class SplashServices {
  void isLogin() {
    final AuthScreen authScreen = AuthScreen();

    Timer(Duration(seconds: 3), () {
      authScreen.checkAuthentication();
    });
  }
}
