import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/change_password_screen.dart';
import 'features/auth/screens/active_account_screen.dart';
import 'features/home/screens/main_layout_screen.dart';
import 'features/books/screens/products_screen.dart';
import 'features/books/screens/book_detail_screen.dart';
import 'features/cart/screens/cart_screen.dart';
import 'features/checkout/screens/checkout_screen.dart';
import 'features/checkout/screens/payment_success_screen.dart';
import 'features/checkout/screens/payos_payment_screen.dart';
import 'features/orders/screens/orders_screen.dart';
import 'features/orders/screens/order_detail_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/favorites/screens/favorites_screen.dart';
import 'features/feedback/screens/feedback_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/user_management_screen.dart';
import 'features/admin/screens/book_management_screen.dart';
import 'features/admin/screens/genre_management_screen.dart';
import 'features/admin/screens/order_management_screen.dart';
import 'features/admin/screens/coupon_management_screen.dart';
import 'features/admin/screens/feedback_management_screen.dart';
import 'features/admin/widgets/admin_route_guard.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BookStoreApp());
}

class BookStoreApp extends StatelessWidget {
  const BookStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ThemeController áp dụng theme qua Get.changeThemeMode (KHÔNG bọc app trong Obx
    // để tránh rebuild toàn bộ Navigator khi đổi theme).
    Get.put(ThemeController(), permanent: true);
    return GetMaterialApp(
      title: 'BookStore',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
      }),
      getPages: [
        // Auth
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/forgot-password', page: () => const ForgotPasswordScreen()),
        GetPage(name: '/change-password', page: () => const ChangePasswordScreen()),
        GetPage(name: '/active-account', page: () => const ActiveAccountScreen()),
        // Customer
        GetPage(name: '/home', page: () => const MainLayoutScreen()),
        GetPage(name: '/products', page: () => const ProductsScreen()),
        GetPage(name: '/book-detail', page: () => const BookDetailScreen()),
        GetPage(name: '/cart', page: () => const CartScreen()),
        GetPage(name: '/checkout', page: () => const CheckoutScreen()),
        GetPage(name: '/payment-success', page: () => const PaymentSuccessScreen()),
        GetPage(name: '/payos-payment', page: () => const PayOSPaymentScreen()),
        GetPage(name: '/orders', page: () => const OrdersScreen()),
        GetPage(name: '/order-detail', page: () => const OrderDetailScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/favorites', page: () => const FavoritesScreen()),
        GetPage(name: '/feedback', page: () => const FeedbackScreen()),
        // Admin (mọi route bọc AdminGuard — chặn khách truy cập)
        GetPage(name: '/admin', page: () => const AdminGuard(child: AdminDashboardScreen())),
        GetPage(name: '/admin/users', page: () => const AdminGuard(child: UserManagementScreen())),
        GetPage(name: '/admin/books', page: () => const AdminGuard(child: BookManagementScreen())),
        GetPage(name: '/admin/genres', page: () => const AdminGuard(child: GenreManagementScreen())),
        GetPage(name: '/admin/orders', page: () => const AdminGuard(child: OrderManagementScreen())),
        GetPage(name: '/admin/coupons', page: () => const AdminGuard(child: CouponManagementScreen())),
        GetPage(name: '/admin/feedbacks', page: () => const AdminGuard(child: FeedbackManagementScreen())),
      ],
      home: const _SplashRouter(),
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        // Dùng chung logic điều hướng với màn Login.
        await Get.find<AuthController>().navigateAfterAuth();
      } else {
        Get.offAllNamed('/home');
      }
    } catch (e) {
      Get.offAllNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
