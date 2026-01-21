import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/providers/booking_state_provider.dart';
import 'package:ilaba/services/auth_service.dart';
import 'package:ilaba/services/pos_service_impl.dart';
import 'package:ilaba/screens/login_screen.dart';
import 'package:ilaba/screens/home_menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Error loading .env file: $e');
    debugPrint('Make sure .env file exists in the project root');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseClient = Supabase.instance.client;

    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthServiceImpl(supabaseClient: supabaseClient),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) =>
              AuthProvider(authService: context.read<AuthService>()),
        ),
        ChangeNotifierProvider<BookingStateNotifier>(
          create: (_) => BookingStateNotifier(SupabasePOSService()),
        ),
      ],
      child: MaterialApp(
        title: 'iLaba',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Show loading while checking auth state
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Route based on login state
            return authProvider.isLoggedIn
                ? const HomeMenuScreen()
                : const LoginScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
