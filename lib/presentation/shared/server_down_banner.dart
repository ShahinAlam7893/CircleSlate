// lib/presentation/widgets/server_down_screen.dart

import 'package:flutter/material.dart';

class ServerDownScreen extends StatelessWidget {
  const ServerDownScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.98),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 100,
              color: Colors.red[700],
            ),
            const SizedBox(height: 32),
            const Text(
              "Server Unavailable",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "We're having trouble connecting to the server.\nPlease try again in a few minutes.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}