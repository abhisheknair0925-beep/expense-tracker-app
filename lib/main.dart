import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/account_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/bill_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/transaction_provider.dart';
import 'features/insights/providers/insights_provider.dart';
import 'features/reports/providers/report_provider.dart';
import 'providers/session_provider.dart';
import 'screens/lock_screen.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.primaryDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase
  await Firebase.initializeApp();

  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProxyProvider2<UserProvider, SessionProvider, AuthProvider>(
          create: (context) => AuthProvider(context.read<UserProvider>(), context.read<SessionProvider>()),
          update: (context, userProvider, sessionProvider, previous) => previous ?? AuthProvider(userProvider, sessionProvider),
        ),
        ChangeNotifierProxyProvider<UserProvider, TransactionProvider>(
          create: (context) => TransactionProvider(),
          update: (context, userProvider, previous) {
            final p = previous ?? TransactionProvider();
            // Optional: Trigger reload if profile changed
            // p.loadForProfile(userProvider.selectedProfile?.profileId);
            return p;
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, AccountProvider>(
          create: (context) => AccountProvider(),
          update: (context, userProvider, previous) => previous ?? AccountProvider(),
        ),
        ChangeNotifierProxyProvider<UserProvider, BillProvider>(
          create: (context) => BillProvider(),
          update: (context, userProvider, previous) => previous ?? BillProvider(),
        ),
        ChangeNotifierProxyProvider<UserProvider, BudgetProvider>(
          create: (context) => BudgetProvider(),
          update: (context, userProvider, previous) => previous ?? BudgetProvider(),
        ),
        ChangeNotifierProvider(create: (_) => InsightsProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AuthGate(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/home': (_) => const LockScreen(child: ShellScreen()),
        },
      ),
    );
  }
}

/// Auth gate — routes to login or main app based on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();

    if (!auth.isSignedIn) {
      return const LoginScreen();
    }

    // Session validation
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (!session.isSessionValid) {
          // Trigger check if not already validated
          session.checkSession();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (userProvider.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (userProvider.needsOnboarding) {
          return const OnboardingScreen();
        }

        return const LockScreen(child: ShellScreen());
      },
    );
  }
}
