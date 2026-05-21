import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/verify_account_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/how_it_works_screen.dart';
import '../../features/home/screens/categories_screen.dart';
import '../../features/home/screens/faq_screen.dart';
import '../../features/freelancer/screens/freelancer_shell.dart';
import '../../features/freelancer/screens/freelancer_home_screen.dart';
import '../../features/freelancer/screens/explore_screen.dart';
import '../../features/freelancer/screens/applications_screen.dart';
import '../../features/freelancer/screens/favorites_screen.dart';
import '../../features/freelancer/screens/profile_screen.dart';
import '../../features/freelancer/screens/portfolio_screen.dart';
import '../../features/freelancer/screens/wallet_screen.dart';
import '../../features/freelancer/screens/settings_screen.dart';
import '../../features/freelancer/screens/active_missions_screen.dart';
import '../../features/freelancer/screens/messages_screen.dart';
import '../../features/client/screens/client_shell.dart';
import '../../features/client/screens/client_home_screen.dart';
import '../../features/client/screens/client_offers_screen.dart';
import '../../features/client/screens/client_applications_screen.dart';
import '../../features/client/screens/client_missions_screen.dart';
import '../../features/client/screens/client_freelancers_screen.dart';
import '../../features/client/screens/client_wallet_screen.dart';
import '../../features/client/screens/client_settings_screen.dart';
import '../../features/client/screens/client_messages_screen.dart';
import '../../features/client/screens/freelancer_public_profile_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';
import '../../data/models/freelancer_model.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _freelancerKey = GlobalKey<NavigatorState>(debugLabel: 'freelancer');
final _clientKey = GlobalKey<NavigatorState>(debugLabel: 'client');

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final role = authProvider.user?.role;
      final loc = state.uri.path;

      final authRoutes = ['/login/freelancer', '/login/client',
                         '/register/freelancer', '/register/client'];
      final freelancerRoutes = loc.startsWith('/freelancer');
      final clientRoutes = loc.startsWith('/client');

      if (authProvider.status == AuthStatus.initial) return null;

      if (isAuth) {
        if (authRoutes.contains(loc)) {
          return role == 'CLIENT' ? '/client/dashboard' : '/freelancer/dashboard';
        }
        if (freelancerRoutes && role != 'FREELANCER') return '/client/dashboard';
        if (clientRoutes && role != 'CLIENT') return '/freelancer/dashboard';
      } else {
        if (freelancerRoutes || clientRoutes) {
          return clientRoutes ? '/login/client' : '/login/freelancer';
        }
      }
      return null;
    },
    routes: [
      // ── Pages publiques ──
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/how-it-works', builder: (_, __) => const HowItWorksScreen()),
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
      GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),

      // ── Auth ──
      GoRoute(path: '/login/freelancer', builder: (_, __) => const LoginScreen(role: 'FREELANCER')),
      GoRoute(path: '/login/client', builder: (_, __) => const LoginScreen(role: 'CLIENT')),
      GoRoute(path: '/register/freelancer', builder: (_, __) => const RegisterScreen(role: 'FREELANCER')),
      GoRoute(path: '/register/client', builder: (_, __) => const RegisterScreen(role: 'CLIENT')),
      GoRoute(
        path: '/forgot-password',
        builder: (_, state) => ForgotPasswordScreen(
          role: state.uri.queryParameters['role'] ?? 'FREELANCER',
        ),
      ),
      GoRoute(
        path: '/verify-account',
        builder: (_, state) => VerifyAccountScreen(
          email: state.uri.queryParameters['email'] ?? '',
          role: state.uri.queryParameters['role'] ?? 'FREELANCER',
        ),
      ),

      // ── Freelancer — pages autonomes (hors shell, ont leur propre AppBar) ──
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/freelancer/wallet',
        builder: (_, __) => const FreelancerWalletScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/freelancer/portfolio',
        builder: (_, __) => const PortfolioScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/freelancer/settings',
        builder: (_, __) => const FreelancerSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/freelancer/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/freelancer/messages',
        builder: (_, __) => const MessagesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/freelancer/active-missions',
        builder: (_, __) => const ActiveMissionsPage(),
      ),

      // ── Freelancer — shell avec 5 onglets ──
      ShellRoute(
        navigatorKey: _freelancerKey,
        builder: (_, __, child) => FreelancerShell(child: child),
        routes: [
          GoRoute(path: '/freelancer/dashboard', builder: (_, __) => const FreelancerHomeScreen()),
          GoRoute(path: '/freelancer/explore', builder: (_, __) => const ExploreScreen()),
          GoRoute(path: '/freelancer/applications', builder: (_, __) => const ApplicationsScreen()),
          GoRoute(path: '/freelancer/favorites', builder: (_, __) => const FavoritesScreen()),
          GoRoute(path: '/freelancer/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Client — pages autonomes (hors shell) ──
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/client/wallet',
        builder: (_, __) => const ClientWalletScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/client/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/client/settings',
        builder: (_, __) => const ClientSettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/client/messages',
        builder: (_, __) => const ClientMessagesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/client/freelancer/:id',
        builder: (_, state) => FreelancerPublicProfileScreen(
          freelancer: state.extra as FreelancerModel,
        ),
      ),

      // ── Client — shell avec 5 onglets ──
      ShellRoute(
        navigatorKey: _clientKey,
        builder: (_, __, child) => ClientShell(child: child),
        routes: [
          GoRoute(path: '/client/dashboard', builder: (_, __) => const ClientHomeScreen()),
          GoRoute(path: '/client/offers', builder: (_, __) => const ClientOffersScreen()),
          GoRoute(path: '/client/applications', builder: (_, __) => const ClientApplicationsScreen()),
          GoRoute(path: '/client/missions', builder: (_, __) => const ClientMissionsScreen()),
          GoRoute(path: '/client/freelancers', builder: (_, __) => const ClientFreelancersScreen()),
        ],
      ),
    ],
  );
}
