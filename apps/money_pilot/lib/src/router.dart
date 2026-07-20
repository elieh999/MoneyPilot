import 'package:flutter/material.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/auth.dart';
import 'package:money_pilot/src/screens/accounts_screen.dart';
import 'package:money_pilot/src/screens/auth_screen.dart';
import 'package:money_pilot/src/screens/bills_screen.dart';
import 'package:money_pilot/src/screens/budgets_screen.dart';
import 'package:money_pilot/src/screens/calendar_screen.dart';
import 'package:money_pilot/src/screens/coach_screen.dart';
import 'package:money_pilot/src/screens/dashboard_screen.dart';
import 'package:money_pilot/src/screens/goals_screen.dart';
import 'package:money_pilot/src/screens/onboarding_screen.dart';
import 'package:money_pilot/src/screens/purchase_check_screen.dart';
import 'package:money_pilot/src/screens/reports_screen.dart';
import 'package:money_pilot/src/screens/settings_screen.dart';
import 'package:money_pilot/src/screens/transactions_screen.dart';
import 'package:money_pilot/src/shell.dart';

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final _routerRefreshProvider = Provider<_RouterRefresh>((ref) {
  final refresh = _RouterRefresh();
  ref.listen<AuthState>(authControllerProvider, (_, _) => refresh.refresh());
  ref.listen<bool>(
    appControllerProvider.select((data) => data.onboardingComplete),
    (_, _) => refresh.refresh(),
  );
  ref.onDispose(refresh.dispose);
  return refresh;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);
  final initialAuth = ref.read(authControllerProvider);
  final initialOnboarded = ref.read(appControllerProvider).onboardingComplete;
  return GoRouter(
    refreshListenable: refresh,
    initialLocation: !initialAuth.initialized
        ? '/loading'
        : initialAuth.currentUser == null
        ? '/auth'
        : initialOnboarded
        ? '/dashboard'
        : '/welcome',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final onboarded = ref.read(appControllerProvider).onboardingComplete;
      final path = state.uri.path;
      if (!auth.initialized) return path == '/loading' ? null : '/loading';
      if (auth.currentUser == null) return path == '/auth' ? null : '/auth';
      final isWelcome = state.uri.path == '/welcome';
      if (!onboarded && !isWelcome) return '/welcome';
      if (onboarded && (isWelcome || path == '/auth' || path == '/loading')) {
        return '/dashboard';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined, size: 48),
            const SizedBox(height: 12),
            AppText('That page is unavailable: ${state.uri.path}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/dashboard'),
              child: const AppText('Return to dashboard'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/accounts',
            name: 'accounts',
            builder: (context, state) => const AccountsScreen(),
          ),
          GoRoute(
            path: '/budgets',
            name: 'budgets',
            builder: (context, state) => const BudgetsScreen(),
          ),
          GoRoute(
            path: '/bills',
            name: 'bills',
            builder: (context, state) => const BillsScreen(),
          ),
          GoRoute(
            path: '/goals',
            name: 'goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/coach',
            name: 'coach',
            builder: (context, state) => const CoachScreen(),
          ),
          GoRoute(
            path: '/purchase-check',
            name: 'purchase-check',
            builder: (context, state) => const PurchaseCheckScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
