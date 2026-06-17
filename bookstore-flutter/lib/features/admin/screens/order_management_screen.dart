import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_ui.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  static const _statuses = ['Đang xử lý', 'Đang giao', 'Hoàn thành', 'Bị huỷ'];

  final controller = Get.put(AdminController());
  final _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    controller.fetchOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _filteredOrders() {
    if (_keyword.trim().isEmpty) return controller.orders;
    return controller.orders.where((o) {
      return adminMatchesKeyword(_keyword, [
        o['fullName']?.toString(),
        o['phoneNumber']?.toString(),
        o['idOrder']?.toString(),
        o['status']?.toString(),
      ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _keyword.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý đơn hàng')),
      body: Column(
        children: [
          AdminSearchBar(
            controller: _searchCtrl,
            hint: 'Tìm theo tên khách, SĐT, mã đơn...',
            onChanged: (v) => setState(() => _keyword = v),
          ),
          if (searching)
            Obx(() => AdminFilterResultBar(count: _filteredOrders().length)),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = _filteredOrders();
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    searching
                        ? 'Không tìm thấy đơn với "$_keyword"'
                        : 'Chưa có đơn hàng nào.',
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final order = items[i];
                  return Card(
                    child: ListTile(
                      onTap: () => _showOrderDetail(controller, order['idOrder']),
                      title: Text('Đơn #${order['idOrder']} - ${order['fullName'] ?? ''}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tổng: ${(order['totalPrice'] ?? 0).toStringAsFixed(0)}đ'),
                          Text('Ngày: ${order['dateCreated'] ?? '-'}'),
                        ],
                      ),
                      trailing: DropdownButton<String>(
                        value: _statuses.contains(order['status']) ? order['status'] : null,
                        hint: const Text('Trạng thái'),
                        items: _statuses
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (newStatus) async {
                          if (newStatus != null) {
                            final ok =
                                await controller.updateOrderStatus(order['idOrder'], newStatus);
                            if (ok) Get.snackbar('Thành công', 'Đã cập nhật trạng thái đơn');
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _showOrderDetail(AdminController controller, int orderId) async {
    final order = await controller.getOrderDetail(orderId);
    if (order == null) return;
    final details = (order['listOrderDetails'] as List?) ?? [];
    Get.dialog(AlertDialog(
      title: Text('Chi tiết đơn #$orderId'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Người nhận: ${order['fullName'] ?? ''}'),
            Text('SĐT: ${order['phoneNumber'] ?? ''}'),
            Text('Địa chỉ: ${order['deliveryAddress'] ?? ''}'),
            Text('Trạng thái: ${order['status'] ?? ''}'),
            const Divider(),
            const Text('Sản phẩm:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (details.isEmpty)
              const Text('(Không có dòng sản phẩm)')
            else
              ...details.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                        'Sách #${d['bookId']} — SL ${d['quantity']} × ${(d['price'] ?? 0).toStringAsFixed(0)}đ'),
                  )),
            const Divider(),
            Text('Phí giao: ${(order['feeDelivery'] ?? 0).toStringAsFixed(0)}đ'),
            Text('Tổng: ${(order['totalPrice'] ?? 0).toStringAsFixed(0)}đ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Đóng'))],
    ));
  }
}
