import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/cart_controller.dart';
import '../../home/controllers/main_layout_controller.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CartController());

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.cartItems.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Giỏ hàng trống!'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    try {
                      Get.find<MainLayoutController>().changeTab(1);
                    } catch (_) {
                      Get.toNamed('/products');
                    }
                  },
                  child: const Text('Mua sách ngay'),
                ),
              ],
            ),
          );
        }
        
        final lines = controller.lines;
        final selectedCount = controller.selectedItemIds.length;
        final hasSelection = selectedCount > 0;

        return Column(
          children: [
            // Bulk Operations Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: controller.isAllSelected,
                    onChanged: (val) {
                      controller.toggleSelectAll(val ?? false);
                    },
                  ),
                  const Text('Chọn tất cả', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (hasSelection) ...[
                    TextButton.icon(
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: Text('Bạn có chắc chắn muốn xóa $selectedCount sản phẩm đã chọn khỏi giỏ hàng?'),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.back();
                                  controller.removeItems(controller.selectedItemIds.toList());
                                },
                                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      label: Text('Xóa ($selectedCount)', style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
            // Cart Items List
            Expanded(
              child: ListView.builder(
                itemCount: lines.length,
                itemBuilder: (ctx, i) {
                  final line = lines[i];
                  final item = line.item;
                  final book = line.book;
                  final isSelected = controller.isSelected(item.idCartItem);

                  return Dismissible(
                    key: Key(item.idCartItem.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Xóa',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      final confirm = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Xác nhận xóa'),
                          content: Text('Bạn có chắc chắn muốn xóa "${book?.nameBook ?? 'Sách'}" khỏi giỏ hàng?'),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      return confirm;
                    },
                    onDismissed: (direction) {
                      controller.removeItem(item.idCartItem);
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  controller.toggleSelection(item.idCartItem);
                                },
                              ),
                            ),
                            SizedBox(
                              width: 56,
                              height: 72,
                              child: book?.thumbnailUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: book!.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) =>
                                          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      errorWidget: (c, u, e) => const Icon(Icons.book, size: 40),
                                    )
                                  : const Icon(Icons.book, size: 40, color: Colors.grey),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(book?.nameBook ?? 'Sách #${item.bookId}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('${(book?.sellPrice ?? 0).toStringAsFixed(0)}đ',
                                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('Thành tiền: ${line.lineTotal.toStringAsFixed(0)}đ',
                                      style: const TextStyle(
                                          color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: item.quantity > 1
                                          ? () => controller.updateQuantity(
                                              item.idCartItem, item.quantity - 1)
                                          : null,
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => controller.updateQuantity(
                                          item.idCartItem, item.quantity + 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        if (controller.cartItems.isEmpty) return const SizedBox.shrink();
        final selectedCount = controller.selectedItemIds.length;
        final displayPrice = controller.selectedTotalPrice;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCount > 0 ? 'Đã chọn $selectedCount sản phẩm' : 'Tổng cộng',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${displayPrice.toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedCount > 0
                      ? () => Get.toNamed('/checkout')
                      : null,
                  child: const Text('Đặt hàng'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
