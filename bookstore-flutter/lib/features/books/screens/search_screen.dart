import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/book_controller.dart';
import '../../../core/models/book_model.dart';
import '../../../shared/widgets/book_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = Get.find<BookController>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  bool get _isSearching =>
      _searchController.text.isNotEmpty ||
      controller.selectedGenreId.value != null;

  @override
  void initState() {
    super.initState();
    _searchController.text = controller.searchName.value;
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (controller.searchName.value != _searchController.text) {
        controller.search(_searchController.text);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      controller.loadMoreBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sách, tác giả...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Obx(() {
                  final showClear = _searchController.text.isNotEmpty ||
                      controller.searchName.value.isNotEmpty;
                  return showClear
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _debounce?.cancel();
                            _searchController.clear();
                            controller.search('');
                          },
                        )
                      : const SizedBox.shrink();
                }),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (value) {
                _debounce?.cancel();
                controller.search(value);
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Lọc & Sắp xếp',
            onPressed: () => _showFilterBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (!_isSearching) {
          return _buildInitialState(context);
        }

        if (controller.isLoading.value && controller.books.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tìm kiếm sách...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        if (controller.books.isEmpty) {
          final hasGenre = controller.selectedGenreId.value != null;
          final hasSort = controller.selectedSort.value != null;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 80,
                    color: scheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Không tìm thấy kết quả',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hãy thử tìm kiếm với từ khoá khác hoặc xoá bộ lọc đang áp dụng.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  if (hasGenre || hasSort || _searchController.text.isNotEmpty)
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Xoá bộ lọc và thiết lập lại'),
                      onPressed: () {
                        _debounce?.cancel();
                        _searchController.clear();
                        controller.searchName.value = '';
                        controller.selectedGenreId.value = null;
                        controller.selectedSort.value = null;
                        controller.fetchBooks(reset: true);
                      },
                    ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            _buildActiveFilters(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.fetchBooks(reset: true),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: controller.books.length + (controller.isLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.books.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final book = controller.books[index];
                    return SearchBookCard(book: book);
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInitialState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thể loại nổi bật
          if (controller.genres.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'Khám phá thể loại',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.genres.length,
                itemBuilder: (context, index) {
                  final genre = controller.genres[index];
                  final name = genre['nameGenre'] ?? '';
                  final id = genre['idGenre'] as int;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(name),
                      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                      onPressed: () {
                        controller.selectedGenreId.value = id;
                        controller.fetchBooks(reset: true);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Gợi ý sách bán chạy
          if (controller.bestsellers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                'Sách bán chạy nhất',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.bestsellers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => SizedBox(
                  width: 140,
                  child: BookCard(
                    book: controller.bestsellers[i],
                    isBestseller: true,
                    onTap: () => Get.toNamed('/book-detail', arguments: controller.bestsellers[i].idBook),
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                'Gợi ý cho bạn',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 280,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(BuildContext context) {
    final hasGenre = controller.selectedGenreId.value != null;
    final hasSort = controller.selectedSort.value != null;

    if (!hasGenre && !hasSort) return const SizedBox.shrink();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      alignment: Alignment.centerLeft,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (hasGenre) ...[
            InputChip(
              label: Text(
                'Thể loại: ${_getGenreNameById(controller.selectedGenreId.value)}',
                style: const TextStyle(fontSize: 12),
              ),
              onDeleted: () {
                controller.selectedGenreId.value = null;
                controller.fetchBooks(reset: true);
              },
            ),
            const SizedBox(width: 8),
          ],
          if (hasSort) ...[
            InputChip(
              label: Text(
                'Sắp xếp: ${_getSortName(controller.selectedSort.value)}',
                style: const TextStyle(fontSize: 12),
              ),
              onDeleted: () {
                controller.selectedSort.value = null;
                controller.fetchBooks(reset: true);
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _getGenreNameById(int? id) {
    if (id == null) return '';
    final g = controller.genres.firstWhere(
      (element) => element['idGenre'] == id,
      orElse: () => null,
    );
    return g != null ? g['nameGenre'] ?? '' : 'Thể loại #$id';
  }

  String _getSortName(String? sort) {
    if (sort == null) return '';
    switch (sort) {
      case 'sellPrice,asc':
        return 'Giá tăng dần';
      case 'nameBook,asc':
        return 'Tên A-Z';
      case 'nameBook,desc':
        return 'Tên Z-A';
      case 'avgRating,desc':
        return 'Đánh giá cao';
      default:
        return 'Mặc định';
    }
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lọc & Sắp xếp',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          controller.selectedGenreId.value = null;
                          controller.selectedSort.value = null;
                          controller.fetchBooks(reset: true);
                          Get.back();
                        },
                        child: const Text('Thiết lập lại'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Thể loại',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Obx(() {
                  if (controller.genres.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Đang tải thể loại...', style: TextStyle(fontSize: 12)),
                    );
                  }
                  return SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: controller.genres.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == 0) {
                          final isSelected = controller.selectedGenreId.value == null;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Tất cả'),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  controller.selectedGenreId.value = null;
                                  controller.fetchBooks(reset: true);
                                }
                              },
                            ),
                          );
                        }
                        final g = controller.genres[i - 1];
                        final name = g['nameGenre'] ?? '';
                        final id = g['idGenre'] as int;
                        final isSelected = controller.selectedGenreId.value == id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                controller.selectedGenreId.value = id;
                              } else {
                                controller.selectedGenreId.value = null;
                              }
                              controller.fetchBooks(reset: true);
                            },
                          ),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Sắp xếp theo',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
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
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: scheme.primary) : null,
      onTap: () {
        controller.changeSort(value);
        Get.back();
      },
    );
  }
}

class SearchBookCard extends StatelessWidget {
  final BookModel book;

  const SearchBookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => Get.toNamed('/book-detail', arguments: book.idBook),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Thumbnail with Shadow & Discount Badge
              SizedBox(
                width: 90,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                                  child: Icon(Icons.menu_book_rounded, size: 36, color: scheme.outline),
                                ),
                              )
                            : Container(
                                color: scheme.surfaceContainerHighest,
                                child: Icon(Icons.menu_book_rounded, size: 36, color: scheme.outline),
                              ),
                        if (book.discountPercent > 0)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: scheme.error,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${book.discountPercent}%',
                                style: TextStyle(
                                  color: scheme.onError,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Book Details
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
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            book.avgRating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  Đã bán ${book.soldQuantity}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${book.sellPrice.toStringAsFixed(0)}đ',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
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