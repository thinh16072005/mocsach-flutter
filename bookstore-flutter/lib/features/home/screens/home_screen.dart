import 'dart:ui';
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
import '../controllers/main_layout_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToTab(int index, String routeName) {
    try {
      final mainLayoutController = Get.find<MainLayoutController>();
      mainLayoutController.changeTab(index);
    } catch (_) {
      Get.toNamed(routeName);
    }
  }

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
            expandedHeight: 320,
            collapsedTitle: 'Mộc Sách',
            background: Obx(() {
              final hero =
                  controller.bestsellers.isNotEmpty ? controller.bestsellers.first : null;
              return _HeroBackground(coverUrl: hero?.thumbnailUrl);
            }),
            foreground: _HeroContent(onExplore: () => _navigateToTab(1, '/products')),
          ),

          // Sách bán chạy
          SliverToBoxAdapter(
            child: SectionTitle(
              title: 'Sách bán chạy',
              actionLabel: 'Xem tất cả',
              onAction: () => _navigateToTab(1, '/products'),
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
              onAction: () => _navigateToTab(1, '/products'),
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
                  SizedBox(
                    height: 105,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.genres.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) {
                        final g = controller.genres[i];
                        final name = g['nameGenre'] ?? '';
                        final id = g['idGenre'] as int;
                        return _GenreCard(
                          name: name,
                          id: id,
                          index: i,
                          onTap: () {
                            controller.selectedGenreId.value = id;
                            controller.fetchBooks(reset: true);
                            _navigateToTab(1, '/products');
                          },
                        );
                      },
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
    final profileController = Get.put(ProfileController());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Personalized Greeting
        Obx(() {
          String greeting = 'Chào bạn!';
          if (profileController.isLoggedIn.value && profileController.user.value != null) {
            final user = profileController.user.value!;
            final name = (user.firstName != null && user.firstName!.isNotEmpty)
                ? user.firstName!
                : (user.fullName.isNotEmpty ? user.fullName : user.email);
            greeting = 'Chào $name!';
          }
          return Text(
            greeting,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          );
        }),
        const SizedBox(height: 4),
        Text(
          'Khám phá thế giới\nqua từng trang sách',
          style: textTheme.displaySmall?.copyWith(
            color: Colors.white,
            height: 1.25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Glassmorphic Search Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          ),
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

class _GenreCard extends StatelessWidget {
  final String name;
  final int id;
  final int index;
  final VoidCallback onTap;

  const _GenreCard({
    required this.name,
    required this.id,
    required this.index,
    required this.onTap,
  });

  IconData _getGenreIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('truyện') || n.contains('tiểu thuyết')) return Icons.menu_book;
    if (n.contains('khoa học') || n.contains('công nghệ')) return Icons.science_outlined;
    if (n.contains('kinh tế') || n.contains('tài chính') || n.contains('kinh doanh')) return Icons.trending_up;
    if (n.contains('văn học')) return Icons.history_edu;
    if (n.contains('lịch sử') || n.contains('địa lý')) return Icons.auto_stories;
    if (n.contains('kỹ năng') || n.contains('phát triển') || n.contains('tự lực')) return Icons.psychology;
    if (n.contains('ngoại ngữ') || n.contains('tiếng')) return Icons.translate;
    if (n.contains('thiếu nhi') || n.contains('trẻ em')) return Icons.child_care;
    if (n.contains('nghệ thuật') || n.contains('đời sống')) return Icons.palette_outlined;
    return Icons.bookmark_outline;
  }

  List<Color> _getGenreGradient(int index) {
    final gradients = [
      [const Color(0xFF0F4C5C), const Color(0xFF1F8A96)], // Teal
      [const Color(0xFF1B263B), const Color(0xFF415A77)], // Navy
      [const Color(0xFF6A4C93), const Color(0xFF8E7DBE)], // Purple
      [const Color(0xFF8B2635), const Color(0xFFC04B5C)], // Deep Red
      [const Color(0xFFD66800), const Color(0xFFE0A458)], // Orange/Gold
      [const Color(0xFF386641), const Color(0xFF6A994E)], // Forest Green
      [const Color(0xFF2C3E50), const Color(0xFF34495E)], // Charcoal
    ];
    return gradients[index % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGenreGradient(index),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                _getGenreIcon(name),
                size: 64,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    _getGenreIcon(name),
                    color: Colors.white,
                    size: 24,
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
