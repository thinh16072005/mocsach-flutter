import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../books/controllers/book_controller.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_ui.dart';
import '../../../core/models/book_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';

class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({super.key});

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  final bookController = Get.put(BookController());
  final adminController = Get.put(AdminController());
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    adminController.fetchGenres();
    bookController.fetchBooksForAdmin(reset: true);
    bookController.fetchAllBooksForAdminSearch();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      bookController.loadMoreAdminBooks();
    }
  }

  List<BookModel> _displayBooks() {
    final searching = _keyword.trim().isNotEmpty;
    if (!searching) return bookController.adminBooks;
    final source = bookController.adminAllBooks.isNotEmpty
        ? bookController.adminAllBooks
        : bookController.adminBooks;
    return source
        .where((b) => adminMatchesKeyword(_keyword, [b.nameBook, b.author]))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _keyword.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý sách')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => BookFormScreen(bookController: bookController)),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          AdminSearchBar(
            controller: _searchCtrl,
            hint: 'Tìm theo tên sách, tác giả...',
            onChanged: (v) => setState(() => _keyword = v),
          ),
          if (searching)
            Obx(() => AdminFilterResultBar(count: _displayBooks().length)),
          Expanded(
            child: Obx(() {
              if (bookController.adminLoading.value && !searching) {
                return const Center(child: CircularProgressIndicator());
              }
              final books = _displayBooks();
              if (books.isEmpty) {
                return Center(
                  child: Text(
                    searching
                        ? 'Không tìm thấy sách với "$_keyword"'
                        : 'Chưa có sách nào.',
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: books.length,
                      itemBuilder: (ctx, i) {
                        final book = books[i];
                        return Card(
                          child: ListTile(
                            leading: SizedBox(
                              width: 40,
                              height: 56,
                              child: book.thumbnailUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: book.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (c, u, e) => const Icon(Icons.book),
                                    )
                                  : const Icon(Icons.book, size: 40),
                            ),
                            title: Text(book.nameBook),
                            subtitle:
                                Text('${book.sellPrice.toStringAsFixed(0)}đ • SL: ${book.quantity}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => Get.to(() =>
                                      BookFormScreen(bookController: bookController, book: book)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(book.idBook),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (bookController.isLoadingMoreAdminBooks.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (bookController.adminPage.value < bookController.adminTotalPages.value - 1 && !searching)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextButton.icon(
                        onPressed: () => bookController.loadMoreAdminBooks(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tải thêm sách'),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    Get.dialog(AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: const Text('Bạn có chắc muốn xóa sách này?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            try {
              await DioClient.instance.delete(ApiEndpoints.bookById(id));
              Get.back();
              bookController.fetchBooksForAdmin();
              bookController.fetchAllBooksForAdminSearch();
              Get.snackbar('Thành công', 'Đã xóa sách');
            } on DioException catch (e) {
              Get.back();
              Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Xóa thất bại');
            }
          },
          child: const Text('Xóa'),
        ),
      ],
    ));
  }
}

class BookFormScreen extends StatefulWidget {
  final BookController bookController;
  final BookModel? book;

  const BookFormScreen({super.key, required this.bookController, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dio = DioClient.instance;
  final _adminController = Get.find<AdminController>();

  late TextEditingController _nameCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _discountCtrl;

  final List<int> _selectedGenreIds = [];
  final List<XFile> _newImages = [];
  // Ảnh cũ: idImage -> urlImage; _keepImageIds = ảnh muốn giữ lại khi lưu.
  final Map<int, String> _existingImages = {};
  final Set<int> _keepImageIds = {};
  bool _isSaving = false;

  bool get _isEdit => widget.book != null;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _nameCtrl = TextEditingController(text: b?.nameBook ?? '');
    _authorCtrl = TextEditingController(text: b?.author ?? '');
    _descCtrl = TextEditingController(text: b?.description ?? '');
    _priceCtrl = TextEditingController(text: b?.listPrice.toStringAsFixed(0) ?? '');
    _quantityCtrl = TextEditingController(text: b?.quantity.toString() ?? '');
    _discountCtrl = TextEditingController(text: b?.discountPercent.toString() ?? '0');
    if (b?.genres != null) {
      _selectedGenreIds.addAll((b!.genres!).map((g) => g['idGenre'] as int));
    }
    if (b?.images != null) {
      for (final img in b!.images!) {
        final id = img['idImage'] as int?;
        final url = img['urlImage'] as String?;
        if (id != null && url != null) {
          _existingImages[id] = url;
          _keepImageIds.add(id); // mặc định giữ tất cả
        }
      }
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      setState(() => _newImages.addAll(images));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGenreIds.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng chọn ít nhất một thể loại');
      return;
    }
    setState(() => _isSaving = true);

    try {
      final dataMap = {
        'nameBook': _nameCtrl.text.trim(),
        'author': _authorCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'listPrice': double.tryParse(_priceCtrl.text) ?? 0,
        'quantity': int.tryParse(_quantityCtrl.text) ?? 0,
        'discountPercent': int.tryParse(_discountCtrl.text) ?? 0,
        'genreIds': _selectedGenreIds,
      };

      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(dataMap),
          contentType: MediaType.parse('application/json'),
        ),
      });

      for (final img in _newImages) {
        final bytes = await img.readAsBytes();
        formData.files.add(MapEntry(
          _isEdit ? 'newImages' : 'images',
          MultipartFile.fromBytes(bytes, filename: img.name),
        ));
      }

      if (_isEdit) {
        // Gửi keepImageIds (query) để backend giữ/xóa ảnh cũ tương ứng.
        await _dio.put(
          ApiEndpoints.bookById(widget.book!.idBook),
          data: formData,
          queryParameters: {'keepImageIds': _keepImageIds.toList()},
        );
      } else {
        await _dio.post(ApiEndpoints.books, data: formData);
      }

      widget.bookController.fetchBooksForAdmin();
      widget.bookController.fetchAllBooksForAdminSearch();
      Get.back();
      Get.snackbar('Thành công', _isEdit ? 'Đã cập nhật sách' : 'Đã tạo sách');
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Lưu thất bại');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa sách' : 'Thêm sách')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_nameCtrl, 'Tên sách'),
              const SizedBox(height: 12),
              _field(_authorCtrl, 'Tác giả'),
              const SizedBox(height: 12),
              _field(_descCtrl, 'Mô tả', maxLines: 3, required: false),
              const SizedBox(height: 12),
              _field(_priceCtrl, 'Giá niêm yết', keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _field(_quantityCtrl, 'Số lượng', keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _field(_discountCtrl, 'Giảm giá (%)', keyboard: TextInputType.number, required: false),
              const SizedBox(height: 16),
              const Text('Thể loại', style: TextStyle(fontWeight: FontWeight.bold)),
              Obx(() => Wrap(
                    spacing: 8,
                    children: _adminController.genres.map((g) {
                      final id = g['idGenre'] as int;
                      final selected = _selectedGenreIds.contains(id);
                      return FilterChip(
                        label: Text(g['nameGenre'] ?? ''),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedGenreIds.add(id);
                          } else {
                            _selectedGenreIds.remove(id);
                          }
                        }),
                      );
                    }).toList(),
                  )),
              const SizedBox(height: 16),
              // Ảnh hiện có (chỉ khi sửa) — bỏ chọn để xóa khi lưu.
              if (_existingImages.isNotEmpty) ...[
                const Text('Ảnh hiện có (bỏ chọn để xóa)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _existingImages.entries.map((entry) {
                      final keep = _keepImageIds.contains(entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Opacity(
                              opacity: keep ? 1 : 0.35,
                              child: CachedNetworkImage(
                                imageUrl: entry.value,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) => const Icon(Icons.book, size: 40),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  if (keep) {
                                    _keepImageIds.remove(entry.key);
                                  } else {
                                    _keepImageIds.add(entry.key);
                                  }
                                }),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: keep ? Colors.red : Colors.green,
                                  child: Icon(keep ? Icons.close : Icons.add,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Text(_isEdit ? 'Thêm ảnh mới' : 'Ảnh',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Chọn ảnh'),
                  ),
                ],
              ),
              if (_newImages.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _newImages
                        .map((img) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Image.file(File(img.path), width: 80, fit: BoxFit.cover),
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEdit ? 'Cập nhật' : 'Tạo sách'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboard, int maxLines = 1, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: required ? (v) => v!.trim().isEmpty ? 'Không được để trống' : null : null,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _authorCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }
}
