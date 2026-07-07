import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/book_controller.dart';
import '../../../core/models/book_model.dart';
import '../../../shared/widgets/book_card.dart';
import '../../../shared/widgets/shimmer_loading.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final controller = Get.put(BookController());
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      controller.search(value, genreId: controller.selectedGenreId.value);
    });
  }

  // Grid responsive: web/màn rộng nhiều cột, mobile ~2 cột (maxCrossAxisExtent 180).
  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 190,
    mainAxisExtent: 320,
    crossAxisSpacing: 14,
    mainAxisSpacing: 18,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá sách'),
        actions: [
          Obx(() => IconButton(
                icon: Icon(controller.isGridView.value
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded),
                tooltip: controller.isGridView.value ? 'Xem dạng danh sách' : 'Xem dạng lưới',
                onPressed: () => controller.isGridView.toggle(),
              )),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Lọc & Sắp xếp',
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _GenreFilter(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.books.isEmpty) {
                return controller.isGridView.value
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: _gridDelegate,
                        itemCount: 6,
                        itemBuilder: (_, __) => const BookCardSkeleton(),
                      )
                    : const ListSkeleton(count: 6);
              }
              if (controller.errorMessage.value.isNotEmpty && controller.books.isEmpty) {
                return _ErrorState(
                  message: controller.errorMessage.value,
                  onRetry: () => controller.fetchBooks(reset: true),
                );
              }
              if (controller.books.isEmpty) {
                return const _EmptyState();
              }
              return Column(
                children: [
                  Expanded(
                    child: controller.isGridView.value
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: _gridDelegate,
                            itemCount: controller.books.length,
                            itemBuilder: (ctx, i) => BookCard(book: controller.books[i]),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: controller.books.length,
                            itemBuilder: (ctx, i) => _DetailedBookCard(book: controller.books[i]),
                          ),
                  ),
                  _Pagination(controller: controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Lọc & Sắp xếp',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Obx(() {
                final currentSort = controller.selectedSort.value;
                return Column(
                  children: [
                    _buildSortOption(
                      label: 'Mặc định (Mới nhất)',
                      value: null,
                      currentValue: currentSort,
                      icon: Icons.sort_rounded,
                      theme: theme,
                    ),
                    _buildSortOption(
                      label: 'Giá: Thấp đến Cao',
                      value: 'sellPrice,asc',
                      currentValue: currentSort,
                      icon: Icons.trending_up_rounded,
                      theme: theme,
                    ),
                    _buildSortOption(
                      label: 'Tên: A đến Z',
                      value: 'nameBook,asc',
                      currentValue: currentSort,
                      icon: Icons.sort_by_alpha_rounded,
                      theme: theme,
                    ),
                    _buildSortOption(
                      label: 'Tên: Z đến A',
                      value: 'nameBook,desc',
                      currentValue: currentSort,
                      icon: Icons.sort_by_alpha_rounded,
                      theme: theme,
                    ),
                    _buildSortOption(
                      label: 'Đánh giá: Cao nhất',
                      value: 'avgRating,desc',
                      currentValue: currentSort,
                      icon: Icons.star_rounded,
                      theme: theme,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSortOption({
    required String label,
    required String? value,
    required String? currentValue,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = currentValue == value;
    final scheme = theme.colorScheme;
    return ListTile(
      leading: Icon(icon, color: isSelected ? scheme.primary : scheme.onSurfaceVariant),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? scheme.primary : theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
          : null,
      onTap: () {
        controller.changeSort(value);
        Get.back();
      },
    );
  }
}

class _GenreFilter extends StatelessWidget {
  final BookController controller;
  const _GenreFilter({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.genres.isEmpty) return const SizedBox.shrink();
      return SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            _chip(
              label: 'Tất cả',
              selected: controller.selectedGenreId.value == null,
              onTap: () {
                controller.selectedGenreId.value = null;
                controller.fetchBooks(reset: true);
              },
            ),
            ...controller.genres.map((g) {
              final id = g['idGenre'] as int;
              return _chip(
                label: g['nameGenre'] ?? '',
                selected: controller.selectedGenreId.value == id,
                onTap: () {
                  controller.selectedGenreId.value =
                      controller.selectedGenreId.value == id ? null : id;
                  controller.fetchBooks(reset: true);
                },
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _chip({required String label, required bool selected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('Không tìm thấy sách nào', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Thử từ khoá hoặc thể loại khác.', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final BookController controller;
  const _Pagination({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.chevron_left),
                onPressed: controller.currentPage.value > 0 ? controller.prevPage : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                    'Trang ${controller.currentPage.value + 1} / ${controller.totalPages.value}'),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.chevron_right),
                onPressed: controller.currentPage.value < controller.totalPages.value - 1
                    ? controller.nextPage
                    : null,
              ),
            ],
          ),
        ));
  }
}

class _DetailedBookCard extends StatelessWidget {
  final BookModel book;

  const _DetailedBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => Get.toNamed('/book-detail', arguments: book.idBook),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        book.thumbnailUrl != null
                            ? CachedNetworkImage(
                                imageUrl: book.thumbnailUrl!,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Container(
                                  color: scheme.surfaceContainerHighest,
                                ),
                                errorWidget: (c, u, e) => Container(
                                  color: scheme.surfaceContainerHighest,
                                  child: Icon(Icons.menu_book, size: 36, color: scheme.outline),
                                ),
                              )
                            : Container(
                                color: scheme.surfaceContainerHighest,
                                child: Icon(Icons.menu_book, size: 36, color: scheme.outline),
                              ),
                        if (book.discountPercent > 0)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: scheme.error,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${book.discountPercent}%',
                                style: TextStyle(color: scheme.onError, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.nameBook,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: scheme.tertiary),
                          const SizedBox(width: 2),
                          Text(
                            book.avgRating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  Đã bán ${book.soldQuantity}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            '${book.sellPrice.toStringAsFixed(0)}đ',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
