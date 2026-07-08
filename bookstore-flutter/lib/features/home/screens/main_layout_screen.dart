import 'package:bookstore_flutter/features/books/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_layout_controller.dart';
import 'home_screen.dart';
import '../../books/screens/products_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../cart/controllers/cart_controller.dart';

class MainLayoutScreen extends StatelessWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Put MainLayoutController as permanent to keep active tab state
    final controller = Get.put(MainLayoutController(), permanent: true);
    final cartController = Get.put(CartController());
    final theme = Theme.of(context);

    final List<Widget> pages = [
      const HomeScreen(),
      const ProductsScreen(),
      const SearchScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Obx(() => Scaffold(
          body: IndexedStack(
            index: controller.currentIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: controller.currentIndex,
              onDestinationSelected: controller.changeTab,
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: theme.colorScheme.primaryContainer,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: theme.colorScheme.primary),
                  label: 'Trang chủ',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book, color: theme.colorScheme.primary),
                  label: 'Sách',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.search),
                  selectedIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                  label: 'Tìm kiếm',
                ),
                NavigationDestination(
                  icon: Obx(() {
                    final count = cartController.totalItemCount;
                    return Badge(
                      label: Text(count.toString()),
                      isLabelVisible: count > 0,
                      child: const Icon(Icons.shopping_bag_outlined),
                    );
                  }),
                  selectedIcon: Obx(() {
                    final count = cartController.totalItemCount;
                    return Badge(
                      label: Text(count.toString()),
                      isLabelVisible: count > 0,
                      child: Icon(Icons.shopping_bag, color: theme.colorScheme.primary),
                    );
                  }),
                  label: 'Giỏ hàng',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: theme.colorScheme.primary),
                  label: 'Tài khoản',
                ),
              ],
            ),
          ),
        ));
  }
}
