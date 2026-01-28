import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ilaba/providers/auth_provider.dart';
import 'package:ilaba/providers/mobile_booking_provider.dart';
import 'package:ilaba/providers/settings_provider.dart';
import 'package:ilaba/providers/notifications_provider.dart';
import 'package:ilaba/services/auth_service.dart';
import 'package:ilaba/services/api_client.dart';
import 'package:ilaba/services/services_repository.dart';
import 'package:ilaba/services/products_repository.dart';
import 'package:ilaba/services/mobile_order_service.dart';
import 'package:ilaba/services/gcash_receipt_service.dart';
import 'package:ilaba/services/loyalty_service.dart';
import 'package:ilaba/screens/auth/login_screen.dart';
import 'package:ilaba/screens/navigation/home_menu_screen.dart';

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
        // Auth Service
        Provider<AuthService>(
          create: (_) => AuthServiceImpl(supabaseClient: supabaseClient),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) =>
              AuthProvider(authService: context.read<AuthService>()),
        ),
        // API Client
        Provider<ApiClient>(
          create: (_) => ApiClientImpl(supabase: supabaseClient),
        ),
        // Mobile Booking Services
        Provider<ServicesRepository>(
          create: (context) =>
              ServicesRepository(apiClient: context.read<ApiClient>()),
        ),
        Provider<ProductsRepository>(
          create: (context) =>
              ProductsRepository(apiClient: context.read<ApiClient>()),
        ),
        Provider<MobileOrderService>(
          create: (context) =>
              MobileOrderService(apiClient: context.read<ApiClient>()),
        ),
        Provider<GCashReceiptService>(
          create: (_) => GCashReceiptService(supabase: supabaseClient),
        ),
        Provider<LoyaltyService>(
          create: (context) =>
              LoyaltyService(authService: context.read<AuthService>()),
        ),
        // Settings Provider
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        // Mobile Booking Provider
        ChangeNotifierProvider<MobileBookingProvider>(
          create: (context) => MobileBookingProvider(
            servicesRepository: context.read<ServicesRepository>(),
            productsRepository: context.read<ProductsRepository>(),
            mobileOrderService: context.read<MobileOrderService>(),
            gcashReceiptService: context.read<GCashReceiptService>(),
            loyaltyService: context.read<LoyaltyService>(),
          ),
        ),
        // Notifications Provider
        ChangeNotifierProvider<NotificationsProvider>(
          create: (_) => NotificationsProvider(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            title: 'iLaba',
            theme: settingsProvider.getCustomTheme(),
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
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/home':
                  return MaterialPageRoute(
                    builder: (context) => const HomeMenuScreen(),
                  );
                case '/login':
                  return MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  );
                default:
                  return null;
              }
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
