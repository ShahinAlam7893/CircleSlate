import 'dart:async';
import 'package:circleslate/presentation/common_providers/server_status_provider.dart';
import 'package:circleslate/presentation/shared/internet_connection_banner.dart';
import 'package:circleslate/presentation/shared/no_internet_page.dart';
import 'package:circleslate/presentation/shared/server_down_banner.dart';
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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const InternetAwareWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class InternetAwareWrapper extends StatefulWidget {
  const InternetAwareWrapper({Key? key}) : super(key: key);

  @override
  State<InternetAwareWrapper> createState() => _InternetAwareWrapperState();
}

class _InternetAwareWrapperState extends State<InternetAwareWrapper> {
  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<InternetProvider>().isConnected;

    if (!isConnected) {
      return const NoInternetPage();
    }

    return InternetAwareScaffold(
      child: ServerAwareScaffold(
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
    );
  }
}
