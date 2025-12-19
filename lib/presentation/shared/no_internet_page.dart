// lib/presentation/shared/no_internet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.98),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Lottie.asset(
              'assets/animation/No Internet!.json',
              width: 220.w,
              height: 220.w,
              fit: BoxFit.contain,
              repeat: true,
            ),

            SizedBox(height: 24.h),

          ],
        ),
      ),
    );
  }
}
