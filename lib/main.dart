// lib/main.dart

import 'dart:async';
import 'package:circleslate/core/network/server_status_manager.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:circleslate/presentation/common_providers/availability_provider.dart';
import 'package:circleslate/presentation/common_providers/chat_list_provider.dart';
import 'package:circleslate/presentation/common_providers/conversation_provider.dart';
import 'package:circleslate/presentation/common_providers/internet_provider.dart';
import 'package:circleslate/presentation/common_providers/user_events_provider.dart';
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:circleslate/presentation/shared/no_internet_page.dart';
import 'package:circleslate/presentation/shared/server_down_banner.dart';
import 'package:circleslate/data/datasources/shared_pref/local/token_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider()),
        ChangeNotifierProvider(create: (_) => UserEventsProvider()),
        ChangeNotifierProvider(create: (_) => ChatListProvider()),
        ChangeNotifierProvider(create: (_) => InternetProvider()),
        ChangeNotifierProvider(create: (_) => ServerStatusManager()), // ← Global server status

        ChangeNotifierProxyProvider<AuthProvider, ConversationProvider>(
              create: (context) => ConversationProvider(
                Provider.of<AuthProvider>(context, listen: false),
              ),
              update: (context, authProvider, conversationProvider) {
                return conversationProvider!;
              },
            ),
      ],
      child: MaterialApp.router(
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        title: 'CircleSlate',
        theme: ThemeData(
          fontFamily: 'Poppins',
          visualDensity: VisualDensity.adaptivePlatformDensity,
          primarySwatch: Colors.blue,
        ),
        builder: (context, child) {
          return GlobalConnectionOverlays(child: child!);
        },
      ),
    );
  }
}

/// Global overlay manager — handles both No Internet & Server Down full-screen
class GlobalConnectionOverlays extends StatelessWidget {
  final Widget child;
  const GlobalConnectionOverlays({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,

        // ─── FULL-SCREEN: NO INTERNET ───
        Consumer<InternetProvider>(
          builder: (context, internetProvider, _) {
            if (internetProvider.isConnected) {
              return const SizedBox.shrink();
            }
            return const IgnorePointer(
              child: NoInternetScreen(),
            );
          },
        ),

        // ─── FULL-SCREEN: SERVER DOWN (blocks everything) ───
        Consumer<ServerStatusManager>(
          builder: (context, serverStatus, _) {
            if (!serverStatus.isServerDown) {
              return const SizedBox.shrink();
            }
            return const IgnorePointer(
              ignoring: false, // Blocks all taps
              child: Material(
                color: Colors.transparent,
                child: ServerDownScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Optional: Splash screen (if you still use it somewhere)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TokenManager _tokenManager = TokenManager();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final tokens = await _tokenManager.getTokens();

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (tokens != null) {
      authProvider.setTokens(tokens.accessToken, tokens.refreshToken);
      await authProvider.initializeUserData().catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 20),
            Text("Loading CircleSlate...", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}