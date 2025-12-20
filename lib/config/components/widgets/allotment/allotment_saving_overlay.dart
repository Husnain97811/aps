import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SavingOverlay extends StatelessWidget {
  const SavingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/saving_animation.json', width: 100, height: 100),
            const SizedBox(height: 10),
            const Text('Saving PDF...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}