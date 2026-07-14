import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../../core/models/book_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../favorites/controllers/favorite_controller.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/parallax_header.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _dio = DioClient.instance;
  final _cartController = Get.put(CartController());
  final _favoriteController = Get.put(FavoriteController());

  BookModel? _book;
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  int _quantity = 1;
  int _heroIndex = 0; // ảnh đang hiển thị ở header

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookId = Get.arguments as int;
    try {
      final bookResp = await _dio.get(ApiEndpoints.bookById(bookId));
      if (bookResp.data['success'] == true) {
        _book = BookModel.fromJson(bookResp.data['data']);
      }
      final reviewResp = await _dio.get(ApiEndpoints.reviewsByBook(bookId));
      if (reviewResp.data['success'] == true) {
        _reviews = reviewResp.data['data'] as List;
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể tải chi tiết sách');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Danh sách URL ảnh (thumbnail trước).
  List<String> _imageUrls(BookModel book) {
    final images = book.images;
    if (images == null || images.isEmpty) return [];
    return images
        .map((e) => BookModel.secureImageUrl(e['urlImage']))
        .whereType<String>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_book == null || _book!.isDeleted) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy sách')));
    }
    final book = _book!;
    final urls = _imageUrls(book);
    final heroUrl = urls.isNotEmpty ? urls[_heroIndex.clamp(0, urls.length - 1)] : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header parallax ảnh bìa (kiểu Apple Books).
          ParallaxSliverHeader(
            expandedHeight: 360,
            collapsedTitle: book.nameBook,
            actions: [
              Obx(() => IconButton(
                    tooltip: 'Yêu thích',
                    icon: Icon(
                      _favoriteController.isFavorite(book.idBook)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.white,
                    ),
                    onPressed: () => _favoriteController.toggleFavorite(book.idBook),
                  )),
              const SizedBox(width: 4),
            ],
            background: heroUrl != null
                ? CachedNetworkImage(
                    imageUrl: heroUrl,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: scheme.surfaceContainerHighest),
                    errorWidget: (c, u, e) => Container(
                      color: scheme.primary,
                      child: const Icon(Icons.menu_book, size: 96, color: Colors.white54),
                    ),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primary, scheme.secondary],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.menu_book, size: 96, color: Colors.white54),
                    ),
                  ),
            foreground: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(book.nameBook,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text('Tác giả: ${book.author}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tác giả — luôn hiển thị trong phần nội dung chính
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 18, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          book.author.isNotEmpty ? book.author : 'Chưa rõ tác giả',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Giá + giảm giá
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${book.sellPrice.toStringAsFixed(0)}đ',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      if (book.discountPercent > 0) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${book.listPrice.toStringAsFixed(0)}đ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: scheme.onSurfaceVariant,
                              )),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('-${book.discountPercent}%',
                              style: TextStyle(
                                  color: scheme.onError,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Meta chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                          icon: Icons.star_rounded,
                          label: book.avgRating.toStringAsFixed(1),
                          iconColor: scheme.tertiary),
                      _MetaChip(icon: Icons.shopping_bag_outlined, label: 'Đã bán ${book.soldQuantity}'),
                      _MetaChip(
                        icon: Icons.inventory_2_outlined,
                        label: book.quantity > 0 ? 'Còn ${book.quantity}' : 'Hết hàng',
                      ),
                    ],
                  ),

                  // Thumbnail strip nếu nhiều ảnh
                  if (urls.length > 1) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: urls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final selected = i == _heroIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _heroIndex = i),
                            child: Container(
                              width: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? scheme.primary : scheme.outline,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(imageUrl: urls[i], fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const Divider(),
                  Text('Mô tả', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(book.description ?? 'Chưa có mô tả', style: theme.textTheme.bodyLarge),
                  const Divider(),

                  Text('Đánh giá (${_reviews.length})', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (_reviews.isEmpty)
                    Text('Chưa có đánh giá nào.', style: theme.textTheme.bodySmall)
                  else
                    ..._reviews.map((r) => _ReviewTile(review: r)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),

      // CTA cố định ở đáy: số lượng + thêm vào giỏ.
      bottomNavigationBar: _BottomBar(
        quantity: _quantity,
        maxQuantity: book.quantity,
        onMinus: _quantity > 1 ? () => setState(() => _quantity--) : null,
        onPlus: _quantity < book.quantity ? () => setState(() => _quantity++) : null,
        onAddToCart: book.quantity > 0
            ? () => _cartController.addItem(book.idBook, quantity: _quantity)
            : null,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  const _MetaChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback? onAddToCart;

  const _BottomBar({
    required this.quantity,
    required this.maxQuantity,
    this.onMinus,
    this.onPlus,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            // Stepper số lượng
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outline),
                borderRadius: AppTheme.borderRadius,
              ),
              child: Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove),
                    onPressed: onMinus,
                  ),
                  Text('$quantity', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add),
                    onPressed: onPlus,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: maxQuantity > 0 ? 'Thêm vào giỏ' : 'Hết hàng',
                icon: Icons.add_shopping_cart,
                onPressed: onAddToCart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final dynamic review;
  const _ReviewTile({required this.review});

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = _formatDate(review['dateCreated'] ?? review['createdAt']);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.person, color: scheme.onPrimaryContainer, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        final rating = (review['ratingPoint'] ?? 0).toDouble();
                        return Icon(
                          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 16,
                          color: scheme.tertiary,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text('Người dùng #${review['userId'] ?? '?'}',
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(review['content'] ?? '', style: theme.textTheme.bodyMedium),
                  if (date.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(date, style: theme.textTheme.labelSmall),
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
