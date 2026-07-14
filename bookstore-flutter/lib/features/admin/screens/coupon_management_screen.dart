import 'dart:async';
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
  final ScrollController _scrollController = ScrollController();
  String _keyword = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    controller.fetchCoupons(page: 0);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      controller.loadMoreCoupons();
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _keyword = value);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isEmpty) {
        controller.fetchCoupons(page: 0, size: 10);
      } else {
        controller.fetchCoupons(page: 0, size: 200);
      }
    });
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
            // Reference rx variable to avoid GetX improper use error when searching is false
            final _ = controller.coupons.length;
            if (searching) {
              return AdminFilterResultBar(count: _filteredCoupons().length);
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              final items = _filteredCoupons();
              if (controller.isLoading.value && items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    searching
                        ? 'Không tìm thấy mã với "$_keyword"'
                        : 'Chưa có mã giảm giá nào.',
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
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
                                  onPressed: () => _confirmDelete(c.idCoupon, c.code),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (controller.isLoadingMoreCoupons.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (controller.couponPage.value < controller.couponTotalPages.value - 1 && !searching)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextButton.icon(
                        onPressed: () => controller.loadMoreCoupons(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tải thêm mã'),
                      ),
                    ),
                ],
              );
            }),
          ),
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
            if (success) {
              Get.back();
              Get.snackbar('Thành công', 'Đã tạo mã giảm giá');
            }
          },
          child: const Text('Tạo'),
        ),
      ],
    ));
  }

  void _confirmDelete(int id, String code) {
    Get.dialog(AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: Text('Bạn có chắc muốn xóa mã giảm giá "$code"?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            controller.deleteCoupon(id);
            Get.back();
          },
          child: const Text('Xóa'),
        ),
      ],
    ));
  }
}
