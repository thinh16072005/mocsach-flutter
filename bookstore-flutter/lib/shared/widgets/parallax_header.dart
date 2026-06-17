import 'package:flutter/material.dart';

/// SliverAppBar có nền parallax: ảnh nền dịch chuyển chậm hơn nội dung khi cuộn,
/// kèm lớp gradient overlay và phần nội dung nổi ở đáy (tiêu đề hero / thông tin sách).
///
/// Dùng trong CustomScrollView: `slivers: [ ParallaxSliverHeader(...), ... ]`.
class ParallaxSliverHeader extends StatelessWidget {
  final double expandedHeight;
  final Widget background; // thường là ảnh (CachedNetworkImage)
  final Widget? foreground; // nội dung nổi ở đáy header khi mở rộng
  final String? collapsedTitle; // tiêu đề hiện khi thu gọn
  final List<Widget>? actions;
  final Widget? leading;
  final double parallaxFactor; // 0..1 — mức ảnh nền "chậm" hơn

  const ParallaxSliverHeader({
    super.key,
    required this.expandedHeight,
    required this.background,
    this.foreground,
    this.collapsedTitle,
    this.actions,
    this.leading,
    this.parallaxFactor = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      leading: leading,
      actions: actions,
      foregroundColor: Colors.white,
      backgroundColor: scheme.primary,
      surfaceTintColor: Colors.transparent,
      stretchTriggerOffset: 120,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
        centerTitle: false,
        title: collapsedTitle == null
            ? null
            : _CollapsedTitle(title: collapsedTitle!),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh nền parallax: dịch chuyển chậm theo độ thu gọn.
            _ParallaxBackground(factor: parallaxFactor, child: background),
            // Gradient overlay để chữ nổi.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0x00000000), Color(0xCC000000)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            if (foreground != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: foreground!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Hiển thị tiêu đề thu gọn (mờ dần khi mở rộng) dựa trên trạng thái collapse.
class _CollapsedTitle extends StatelessWidget {
  final String title;
  const _CollapsedTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    double opacity = 1;
    if (settings != null) {
      final deltaExtent = settings.maxExtent - settings.minExtent;
      // t: 0 khi mở rộng hoàn toàn, 1 khi thu gọn.
      final t = deltaExtent <= 0
          ? 1.0
          : (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent)
              .clamp(0.0, 1.0);
      // Chỉ hiện rõ khi đã thu gọn gần hết.
      opacity = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
    }
    return Opacity(
      opacity: opacity,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// Dịch ảnh nền theo trục dọc một phần so với mức cuộn → cảm giác chiều sâu.
class _ParallaxBackground extends StatelessWidget {
  final Widget child;
  final double factor;
  const _ParallaxBackground({required this.child, required this.factor});

  @override
  Widget build(BuildContext context) {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    double translateY = 0;
    if (settings != null) {
      final deltaExtent = settings.maxExtent - settings.minExtent;
      final shrink = (settings.maxExtent - settings.currentExtent).clamp(0.0, deltaExtent);
      // Ảnh đi xuống một phần quãng cuộn → trông như chuyển động chậm hơn nội dung.
      translateY = shrink * factor;
    }
    return Transform.translate(
      offset: Offset(0, translateY),
      child: child,
    );
  }
}
