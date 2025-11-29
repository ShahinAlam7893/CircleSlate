import 'package:circleslate/presentation/common_providers/internet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../main.dart';

class InternetConnectionBanner extends StatelessWidget {
  const InternetConnectionBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<InternetProvider>(
      builder: (context, provider, child) {
        if (provider.isConnected) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          color: Colors.grey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                "No Internet Connection",
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            ],
          ),
        );
      },
    );
  }
}
