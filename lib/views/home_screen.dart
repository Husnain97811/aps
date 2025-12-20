import 'package:aps/config/components/widgets/loadin_widget.dart';
import 'package:aps/config/routes/routes_names.dart';
import 'package:aps/views/auth_Screens/auth_screen.dart';
import 'package:aps/views/auth_Screens/notifiers/auth_screen_notifiers.dart';
import 'package:aps/views/auth_Screens/signUp_Screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class HomeScreen extends StatelessWidget {
  final AuthScreen _authScreen = AuthScreen();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove appBar for full-screen experience
      body: Container(
        constraints: BoxConstraints.expand(), // Full screen
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/logopng.png'),
            fit: BoxFit.cover, // Fill entire screen
            // colorFilter: ColorFilter.mode(
            //   Colors.black.withOpacity(0.3), // Optional overlay
            //   BlendMode.darken,
            // ),
          ),
        ),

        child: Padding(
          padding: EdgeInsets.only(top: 11.sp, right: 13.sp),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // create user
              IconButton(
                onPressed: () {
                  // integrate signup functionality here
                  Navigator.pushNamed(
                    context,
                    RouteNames.signupscreen,
                  ); // Navigate to signup screen
                },
                icon: Icon(Icons.account_box_outlined, size: 15.sp),
              ),
              // Add other widgets on top of the image
              Consumer<AuthStateNotifier>(
                builder: (context, authnotifier, child) {
                  if (authnotifier.state == AppAuthState.loading) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  } else {
                    return IconButton(
                      onPressed: () {
                        authnotifier.logout(context); // Trigger logout
                      },
                      icon: Icon(Icons.logout, size: 15.sp),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
