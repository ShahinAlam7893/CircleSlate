import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common_providers/server_status_provider.dart';

class ServerAwareScaffold extends StatelessWidget {
  final Widget child;
  const ServerAwareScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isServerUp = context.watch<ServerStatusProvider>().isServerUp;

    return Stack(
      children: [
        child,
        if (!isServerUp)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.orange,
              padding: const EdgeInsets.all(8),
              child: const Text(
                "⚠️ Server is down. Some features may not work.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
