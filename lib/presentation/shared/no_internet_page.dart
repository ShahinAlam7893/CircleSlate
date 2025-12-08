// lib/presentation/shared/no_internet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
            // Big, clear icon
            Icon(
              Icons.wifi_off_rounded,
              size: 110.sp,
              color: Colors.grey[700],
            ),
            SizedBox(height: 36.h),

            // Title
            Text(
              "No Internet Connection",
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 16.h),

            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 48.w),
              child: Text(
                "Your device is not connected to the internet.\nPlease check your connection and try again.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 48.h),

            // Visual feedback: pulsing indicator
            SizedBox(
              width: 60.w,
              height: 60.w,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Waiting for connection...",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}