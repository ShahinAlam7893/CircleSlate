import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:circleslate/presentation/common_providers/auth_provider.dart';
import 'package:circleslate/presentation/common_providers/availability_provider.dart';
import 'package:circleslate/presentation/common_providers/conversation_provider.dart';
import 'package:circleslate/presentation/common_providers/user_events_provider.dart';
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
            // Just return the existing provider, no updateAuth
            return conversationProvider!;
          },
        ),
        ChangeNotifierProvider(create: (_) => UserEventsProvider()),
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

    // Navigate to your router entry
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MaterialApp.router(
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
