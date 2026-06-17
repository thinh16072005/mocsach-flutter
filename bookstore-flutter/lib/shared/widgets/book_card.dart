import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/book_model.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Thẻ sách dùng chung (grid sản phẩm + carousel home).
/// Ảnh bìa tỉ lệ 3:4, badge giảm giá / bán chạy, giá nổi bật, hiệu ứng nhấn.
class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onTap;
  final bool isBestseller;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.isBestseller = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Pressable(
      onTap: onTap ?? () => Get.toNamed('/book-detail', arguments: book.idBook),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boundedHeight = constraints.maxHeight.isFinite;
          final metaGap = boundedHeight ? 4.0 : 10.0;
          final priceGap = boundedHeight ? 2.0 : 6.0;
          final cover = _buildCover(scheme);

          final meta = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                book.nameBook,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  height: boundedHeight ? 1.15 : 1.2,
                  fontSize: boundedHeight ? 13 : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: boundedHeight ? 1.2 : 1.4,
                  fontSize: boundedHeight ? 11 : null,
                ),
              ),
              SizedBox(height: priceGap),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${book.sellPrice.toStringAsFixed(0)}đ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: boundedHeight ? 14 : null,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.star_rounded, size: boundedHeight ? 14 : 16, color: scheme.tertiary),
                  Text(
                    book.avgRating.toStringAsFixed(1),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: boundedHeight ? 11 : null),
                  ),
                ],
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (boundedHeight)
                Expanded(child: cover)
              else
                AspectRatio(aspectRatio: 3 / 4, child: cover),
              SizedBox(height: metaGap),
              meta,
            ],
          );
        },
      ),
    );
  }

  Widget _buildCover(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppTheme.borderRadius,
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
                      child: Icon(Icons.menu_book, size: 48, color: scheme.outline),
                    ),
                  )
                : Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(Icons.menu_book, size: 48, color: scheme.outline),
                  ),
            if (book.discountPercent > 0)
              Positioned(
                top: 8,
                left: 8,
                child: _Badge(
                  label: '-${book.discountPercent}%',
                  bg: scheme.error,
                  fg: scheme.onError,
                ),
              ),
            if (isBestseller)
              Positioned(
                top: 8,
                right: 8,
                child: _Badge(
                  label: 'Bán chạy',
                  bg: scheme.tertiary,
                  fg: scheme.onTertiary,
                  icon: Icons.local_fire_department,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  const _Badge({required this.label, required this.bg, required this.fg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 3)],
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
