import 'package:flutter/material.dart';

import '../../colors/app_colors.dart';

class LoadingWidget extends StatefulWidget {
  final double? size;
  const LoadingWidget({super.key, this.size});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.circularcolor),
      ),
    );
  }
}
