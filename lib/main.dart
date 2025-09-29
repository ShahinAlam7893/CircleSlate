import 'dart:async';
import 'package:circleslate/presentation/common_providers/server_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

// Providers
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:circleslate/presentation/common_providers/availability_provider.dart';
import 'package:circleslate/presentation/common_providers/conversation_provider.dart';
import 'package:circleslate/presentation/common_providers/user_events_provider.dart';
import 'package:circleslate/presentation/common_providers/internet_provider.dart';

// Router & Token Manager
import 'package:circleslate/presentation/routes/app_router.dart';
import 'package:circleslate/data/datasources/shared_pref/local/token_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ConversationProvider>(
          create: (context) => ConversationProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, authProvider, conversationProvider) {
            return conversationProvider!;
          },
        ),
        ChangeNotifierProvider(create: (_) => UserEventsProvider()),
        ChangeNotifierProvider(create: (_) => InternetProvider()),
        ChangeNotifierProvider(create: (_) => ServerStatusProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CircleSlate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
    final tokens = await _tokenManager.getTokens().catchError((error) {
      debugPrint('Error loading tokens: $error');
      return null;
    });

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (tokens != null) {
      authProvider.setTokens(tokens.accessToken, tokens.refreshToken);
      await authProvider.initializeUserData();
    }

    // Navigate to app router with Internet-aware wrapper
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => InternetAwareWrapper(
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              fontFamily: 'Poppins',
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class InternetAwareWrapper extends StatefulWidget {
  final Widget child;
  const InternetAwareWrapper({required this.child, Key? key}) : super(key: key);

  @override
  State<InternetAwareWrapper> createState() => _InternetAwareWrapperState();
}

class _InternetAwareWrapperState extends State<InternetAwareWrapper> {
  bool _wasDisconnected = false;

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<InternetProvider>().isConnected;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = ScaffoldMessenger.of(context);

      if (!isConnected && !_wasDisconnected) {
        _wasDisconnected = true;
        messenger.showSnackBar(
          const SnackBar(
            content: Text("No Internet Connection"),
            backgroundColor: Colors.red,
            duration: Duration(days: 1), // stays until dismissed
          ),
        );
      } else if (isConnected && _wasDisconnected) {
        _wasDisconnected = false;
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Back Online"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2), // auto dismiss
          ),
        );
      }
    });

    return ScaffoldMessenger(
      child: widget.child,
    );
  }
}
