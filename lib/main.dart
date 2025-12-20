import 'package:aps/config/providers/discount_fields_provider.dart';
import 'package:aps/config/providers/offer_installment_provider.dart';
import 'package:aps/services/user_activity_detector.dart';
import 'package:aps/config/view.dart';
import 'package:aps/investors/investor_provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  // Initialize Hive with Windows-compatible path
  // await Hive.initFlutter();
  // if (Features.enableSessionService) {
  await SessionService.init();

  // Register DateTime adapter
  Hive.registerAdapter(DateTimeAdapter());

  // final encryptionKey = Hive.generateSecureKey();

  // // Initialize encrypted box
  // await Hive.openBox(
  //   'sessionBoxAps',
  //   encryptionCipher: HiveAesCipher(encryptionKey),
  // );

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://vodmeztkbdssrripiamu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvZG1lenRrYmRzc3JyaXBpYW11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc3ODU4OTIsImV4cCI6MjA1MzM2MTg5Mn0.tEXOZkKXYIaroTPW9yC-8Q-qw_K-sasIzg1WKFZj8bA',
  );

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Initialize user profile service
  await UserProfileService().initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStateNotifier()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => DealerProvider()),
        ChangeNotifierProvider(create: (_) => DealerProvider()),
        ChangeNotifierProvider(create: (_) => ClientsProvider()),
        ChangeNotifierProvider(create: (_) => ClientsRefundProvider()),
        ChangeNotifierProvider(create: (_) => AllotmentProvider()),
        ChangeNotifierProvider(
          create: (_) => InvestorProvider(Supabase.instance.client),
        ),
        ChangeNotifierProvider(create: (_) => LandPaymentProvider()),
        Provider(create: (context) => DocumentsProvider()),
        ChangeNotifierProvider(create: (_) => InstallmentReceiptProvider()),
        ChangeNotifierProvider(create: (_) => SpecialOfferProvider()),
        ChangeNotifierProvider(create: (_) => DiscountFieldsProvider()),
        ChangeNotifierProvider(create: (_) => PaymentPlanProvider()),
        ChangeNotifierProvider(create: (_) => LateInstallmentsOfferProvider()),
        ChangeNotifierProvider(create: (_) => PaymentDescriptionProvider()),
        ChangeNotifierProvider(create: (_) => CashFlowProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ValueVisibilityProvider()),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),

        ChangeNotifierProvider(
          create: (context) => LogoProvider()..preloadLogos(),
        ),

        // Add other providers here
      ],
      child: MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Add slight delay to ensure context is available
    Future.delayed(const Duration(milliseconds: 100), () {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      // Only check for inactivity-based session
      final lastActivityTime = await SessionService.getLastActivityTime();

      if (lastActivityTime != null) {
        final inactiveDuration = DateTime.now().difference(lastActivityTime);
        if (inactiveDuration < const Duration(minutes: 10)) {
          // Valid session
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            RouteNames.sidebar,
            (route) => false,
          );
          return;
        }
      }

      // Invalid session - force logout
      await supabase.auth.signOut();
    }

    // Go to login screen
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      RouteNames.splashscreen,
      (route) => false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // if (state == AppLifecycleState.paused) {
    //   SessionService.appPaused();
    // } else
    if (state == AppLifecycleState.resumed) {
      SessionService.appResumed();
    } else if (state == AppLifecycleState.detached) {
      // Handle app termination
      SessionService.appClosed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoadingProvider(),

      child: Sizer(
        builder: (p0, p1, p2) {
          return UserActivityDetector(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'APS',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
              ),
              // home: SplashScreen(),
              // home: TriangleScreen(),
              initialRoute: RouteNames.splashscreen,
              onGenerateRoute: Routes.generateRoute,
            ),
          );
        },
      ),
    );
  }
}
