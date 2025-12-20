import 'package:aps/services/splash_services/splash_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../config/view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SplashServices().isLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // color: AppColors.blackcolor
          gradient: AppColors.rmncolor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/logo.png',
                height: 60.sp,
                width: 60.sp,
              ),

              SizedBox(height: 1.5.h),
              Text(
                'Developed by UH Tech Solution'.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3.h),
              ProviderLoadingWidget(),
              // LoadingWidget(), // Assuming LoadingWidget displays a loading indicator
            ],
          ),
        ),
      ),
    );
  }
}
