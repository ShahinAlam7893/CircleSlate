import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common_providers/internet_provider.dart';


class InternetAwareScaffold extends StatelessWidget {
  final Widget child;
  const InternetAwareScaffold({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<InternetProvider>().isConnected;

    return Stack(
      children: [
        child,
        if (!isConnected)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.red,
              padding: const EdgeInsets.all(8),
              child: const Text(
                "No Internet Connection",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
