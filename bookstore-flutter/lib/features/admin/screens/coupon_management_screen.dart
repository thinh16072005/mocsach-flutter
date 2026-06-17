import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_ui.dart';
import '../../../core/models/coupon_model.dart';

class CouponManagementScreen extends StatefulWidget {
  const CouponManagementScreen({super.key});

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen> {
  final controller = Get.put(AdminController());
  final _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    controller.fetchCoupons(page: 0);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _keyword = value);
    if (value.trim().isEmpty) {
      controller.fetchCoupons(page: 0, size: 10);
    } else {
      controller.fetchCoupons(page: 0, size: 200);
    }
  }

  List<dynamic> _filteredCoupons() {
    if (_keyword.trim().isEmpty) return controller.coupons;
    return controller.coupons.where((c) {
      final code = (c['code'] ?? '').toString();
      final pct = (c['discountPercent'] ?? '').toString();
      return adminMatchesKeyword(_keyword, [code, pct]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _keyword.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý mã giảm giá')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(controller),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          AdminSearchBar(
            controller: _searchCtrl,
            hint: 'Tìm theo mã, % giảm...',
            onChanged: _onSearchChanged,
          ),
          Obx(() {
            if (searching) {
              return AdminFilterResultBar(count: _filteredCoupons().length);
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = _filteredCoupons();
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    searching
                        ? 'Không tìm thấy mã với "$_keyword"'
                        : 'Chưa có mã giảm giá nào.',
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final c = CouponModel.fromJson(Map<String, dynamic>.from(items[i]));
                  return Card(
                    child: ListTile(
                      title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Giảm ${c.discountPercent}% • HSD: ${c.expiryDate}'
                          '${c.isUsed ? ' • Đã dùng' : ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: c.isActive,
                            onChanged: (_) => controller.toggleCoupon(c.idCoupon),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => controller.deleteCoupon(c.idCoupon),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          if (!searching) _Pagination(controller: controller),
        ],
      ),
    );
  }

  void _showCreateDialog(AdminController controller) {
    final quantityCtrl = TextEditingController(text: '1');
    final discountCtrl = TextEditingController(text: '10');
    final expiryCtrl = TextEditingController(
        text: DateTime.now().add(const Duration(days: 30)).toString().split(' ')[0]);

    Get.dialog(AlertDialog(
      title: const Text('Tạo mã giảm giá'),
      content: AdminFormFields(
        children: [
          adminDialogField(
            controller: quantityCtrl,
            label: 'Số lượng',
            keyboardType: TextInputType.number,
          ),
          adminDialogField(
            controller: discountCtrl,
            label: '% giảm giá',
            keyboardType: TextInputType.number,
          ),
          adminDialogField(
            controller: expiryCtrl,
            label: 'Ngày hết hạn (yyyy-MM-dd)',
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
        ElevatedButton(
          onPressed: () async {
            final success = await controller.createCouponBatch(
              int.tryParse(quantityCtrl.text) ?? 1,
              int.tryParse(discountCtrl.text) ?? 10,
              expiryCtrl.text.trim(),
            );
            Get.back();
            if (success) Get.snackbar('Thành công', 'Đã tạo mã giảm giá');
          },
          child: const Text('Tạo'),
        ),
      ],
    ));
  }
}

class _Pagination extends StatelessWidget {
  final AdminController controller;
  const _Pagination({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: controller.couponPage.value > 0 ? controller.couponPrevPage : null,
            ),
            Text('Trang ${controller.couponPage.value + 1} / ${controller.couponTotalPages.value}'),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: controller.couponPage.value < controller.couponTotalPages.value - 1
                  ? controller.couponNextPage
                  : null,
            ),
          ],
        ));
  }
}
