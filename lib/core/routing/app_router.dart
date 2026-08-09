import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/admin/presentation/users_screen.dart';
import '../../features/auth/presentation/launch_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/diagnosis/presentation/diagnosis_screen.dart';
import '../../features/passport/presentation/passport_screen.dart';
import '../../features/products/presentation/product_registration_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/qr_scanner/presentation/scan_screen.dart';
import '../../features/repairs/presentation/repair_detail_screen.dart';
import '../../features/repairs/presentation/repairs_screen.dart';
import '../widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LaunchScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/app/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/app/products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/app/scan',
            builder: (context, state) => const ScanScreen(),
          ),
          GoRoute(
            path: '/app/repairs',
            builder: (context, state) => const RepairsScreen(),
          ),
          GoRoute(
            path: '/app/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/products/new',
        builder: (context, state) => const ProductRegistrationScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: '/passport/:productId',
        builder: (context, state) => PassportScreen(
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(
        path: '/diagnosis/:productId',
        builder: (context, state) => DiagnosisScreen(
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(
        path: '/repairs/:repairId',
        builder: (context, state) => RepairDetailScreen(
          repairId: state.pathParameters['repairId']!,
        ),
      ),
    ],
  ),
);
