import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Khối shimmer cơ bản (1 hình chữ nhật bo góc) dùng để dựng skeleton.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? radius;

  const ShimmerBox({super.key, this.width, this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: radius ?? AppTheme.borderRadius,
        ),
      ),
    );
  }
}

/// Skeleton dạng thẻ sách (ảnh + 2 dòng chữ) — dùng cho carousel/grid khi đang tải.
class BookCardSkeleton extends StatelessWidget {
  final double width;
  const BookCardSkeleton({super.key, this.width = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 3 / 4, child: ShimmerBox()),
          SizedBox(height: 8),
          ShimmerBox(height: 12, width: 120),
          SizedBox(height: 6),
          ShimmerBox(height: 12, width: 70),
        ],
      ),
    );
  }
}

/// Hàng carousel skeleton ngang.
class BookCarouselSkeleton extends StatelessWidget {
  const BookCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const BookCardSkeleton(),
      ),
    );
  }
}

/// Skeleton dạng danh sách dọc (cho màn list/orders/favorites).
class ListSkeleton extends StatelessWidget {
  final int count;
  const ListSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const Row(
        children: [
          ShimmerBox(width: 56, height: 76),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 14, width: 180),
                SizedBox(height: 8),
                ShimmerBox(height: 12, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
