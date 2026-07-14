import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _admin = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
    _admin.fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem('Quản lý người dùng', Icons.people, '/admin/users'),
      _MenuItem('Quản lý sách', Icons.menu_book, '/admin/books'),
      _MenuItem('Quản lý thể loại', Icons.category, '/admin/genres'),
      _MenuItem('Quản lý đơn hàng', Icons.receipt_long, '/admin/orders'),
      _MenuItem('Quản lý mã giảm giá', Icons.local_offer, '/admin/coupons'),
      _MenuItem('Quản lý phản hồi', Icons.feedback, '/admin/feedbacks', showBadge: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.find<AuthController>().logout(),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: items
            .map((item) => Card(
                  child: InkWell(
                    onTap: () async {
                      await Get.toNamed(item.route);
                      // Quay lại dashboard → cập nhật badge unread.
                      _admin.fetchUnreadCount();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        item.showBadge
                            ? Obx(() => Badge(
                                  isLabelVisible: _admin.unreadFeedbackCount.value > 0,
                                  label: Text('${_admin.unreadFeedbackCount.value}'),
                                  child: Icon(item.icon, size: 48, color: Colors.indigo),
                                ))
                            : Icon(item.icon, size: 48, color: Colors.indigo),
                        const SizedBox(height: 12),
                        Text(item.title, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final String route;
  final bool showBadge;
  _MenuItem(this.title, this.icon, this.route, {this.showBadge = false});
}
