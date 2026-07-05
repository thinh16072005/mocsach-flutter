import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/order_controller.dart';
import '../../../core/models/order_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final controller = Get.put(OrderController());

  @override
  void initState() {
    super.initState();
    controller.fetchMyOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng của tôi')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.value.isNotEmpty && controller.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                Text(controller.errorMessage.value),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.fetchMyOrders,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        if (controller.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Bạn chưa có đơn hàng nào.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/products'),
                  child: const Text('Mua sách'),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.fetchMyOrders,
          child: ListView.builder(
            itemCount: controller.orders.length,
            itemBuilder: (ctx, i) => _OrderCard(order: controller.orders[i]),
          ),
        );
      }),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'Bị huỷ':
        return Colors.red;
      case 'Hoàn thành':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text('Đơn hàng #${order.idOrder}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngày: ${order.dateCreated ?? "-"}'),
            Text('Tổng: ${order.totalPrice.toStringAsFixed(0)}đ'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(order.status,
                      style: TextStyle(color: _statusColor(order.status), fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Text(order.paymentStatus == 'PAID' ? 'Đã thanh toán' : 'Chưa thanh toán',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed('/order-detail', arguments: order.idOrder),
      ),
    );
  }
}
