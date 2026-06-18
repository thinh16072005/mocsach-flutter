import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/book_controller.dart';
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên sách...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _GenreFilter(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.books.isEmpty) {
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: _gridDelegate,
                  itemCount: 6,
                  itemBuilder: (_, __) => const BookCardSkeleton(),
                );
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
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: _gridDelegate,
                      itemCount: controller.books.length,
                      itemBuilder: (ctx, i) => BookCard(book: controller.books[i]),
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
