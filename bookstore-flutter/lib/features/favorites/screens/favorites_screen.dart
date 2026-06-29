import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/favorite_controller.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FavoriteController());

    return Scaffold(
      appBar: AppBar(title: const Text('Sách yêu thích')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Chưa có sách yêu thích nào.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/products'),
                  child: const Text('Khám phá sách'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.favorites.length,
          itemBuilder: (ctx, i) {
            final fav = controller.favorites[i];
            final bookId = fav['bookId'] as int;
            final book = controller.bookFor(bookId);
            return Card(
              child: ListTile(
                leading: SizedBox(
                  width: 44,
                  height: 60,
                  child: book?.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book!.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (c, u) =>
                              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (c, u, e) => const Icon(Icons.book, size: 40),
                        )
                      : const Icon(Icons.book, size: 40),
                ),
                title: Text(book?.nameBook ?? 'Sách #$bookId'),
                subtitle: book != null
                    ? Text('${book.sellPrice.toStringAsFixed(0)}đ')
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => controller.removeFavorite(bookId),
                ),
                onTap: () => Get.toNamed('/book-detail', arguments: bookId),
              ),
            );
          },
        );
      }),
    );
  }
}
