import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../books/controllers/book_controller.dart';
import '../../../core/models/book_model.dart';
import '../../../shared/theme/theme_controller.dart';
import '../../../shared/widgets/book_card.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/parallax_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BookController());
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero parallax: ảnh bìa sách bán chạy làm nền (mờ + gradient) + tiêu đề serif.
          // Obx đặt TRONG background (box-context), không bọc cả sliver.
          ParallaxSliverHeader(
            expandedHeight: 280,
            collapsedTitle: 'BookStore',
            actions: const [_ThemeToggle(), _CartAction(), _ProfileAction(), SizedBox(width: 4)],
            background: Obx(() {
              final hero =
                  controller.bestsellers.isNotEmpty ? controller.bestsellers.first : null;
              return _HeroBackground(coverUrl: hero?.thumbnailUrl);
            }),
            foreground: _HeroContent(onExplore: () => Get.toNamed('/products')),
          ),

          // Sách bán chạy
          SliverToBoxAdapter(
            child: SectionTitle(
              title: 'Sách bán chạy',
              actionLabel: 'Xem tất cả',
              onAction: () => Get.toNamed('/products'),
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.bestsellers.isEmpty && controller.isLoading.value) {
                return const BookCarouselSkeleton();
              }
              if (controller.bestsellers.isEmpty) {
                return const _EmptyHint(text: 'Chưa có sách bán chạy.');
              }
              return _BookCarousel(books: controller.bestsellers, bestseller: true);
            }),
          ),

          // Mới phát hành (dùng danh sách sách mặc định)
          SliverToBoxAdapter(
            child: SectionTitle(
              title: 'Mới phát hành',
              actionLabel: 'Xem tất cả',
              onAction: () => Get.toNamed('/products'),
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.books.isEmpty && controller.isLoading.value) {
                return const BookCarouselSkeleton();
              }
              if (controller.books.isEmpty) {
                return const _EmptyHint(text: 'Chưa có sách.');
              }
              return _BookCarousel(books: controller.books.toList());
            }),
          ),

          // Theo thể loại
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.genres.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Khám phá theo thể loại'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.genres.map((g) {
                        return ActionChip(
                          label: Text(g['nameGenre'] ?? ''),
                          onPressed: () {
                            controller.selectedGenreId.value = g['idGenre'] as int;
                            controller.fetchBooks(reset: true);
                            Get.toNamed('/products');
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            }),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Text(
                'Đọc sách mỗi ngày 📚',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nền hero: ảnh bìa phủ kín; nếu không có thì gradient teal→navy.
class _HeroBackground extends StatelessWidget {
  final String? coverUrl;
  const _HeroBackground({this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
      ),
    );
    if (coverUrl == null) return gradient;
    return Stack(
      fit: StackFit.expand,
      children: [
        gradient,
        CachedNetworkImage(
          imageUrl: coverUrl!,
          fit: BoxFit.cover,
          color: Colors.black.withValues(alpha: 0.35),
          colorBlendMode: BlendMode.darken,
          errorWidget: (c, u, e) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  final VoidCallback onExplore;
  const _HeroContent({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Khám phá thế giới\nqua từng trang sách',
          style: textTheme.displaySmall?.copyWith(color: Colors.white, height: 1.2),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onExplore,
          icon: const Icon(Icons.auto_stories, size: 18),
          label: const Text('Xem tất cả sách'),
        ),
      ],
    );
  }
}

/// Carousel cuộn ngang các thẻ sách.
class _BookCarousel extends StatelessWidget {
  final List<BookModel> books;
  final bool bestseller;
  const _BookCarousel({required this.books, this.bestseller = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (ctx, i) => SizedBox(
          width: 150,
          child: BookCard(book: books[i], isBestseller: bestseller),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController(), permanent: true);
    return Obx(() => IconButton(
          tooltip: 'Chế độ sáng/tối',
          icon: Icon(themeController.isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: themeController.toggle,
        ));
  }
}

class _CartAction extends StatelessWidget {
  const _CartAction();
  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.shopping_bag_outlined),
        onPressed: () => Get.toNamed('/cart'),
      );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction();
  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.person_outline),
        onPressed: () => Get.toNamed('/profile'),
      );
}
