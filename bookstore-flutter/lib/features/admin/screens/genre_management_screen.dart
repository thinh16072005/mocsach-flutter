import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_ui.dart';

class GenreManagementScreen extends StatefulWidget {
  const GenreManagementScreen({super.key});

  @override
  State<GenreManagementScreen> createState() => _GenreManagementScreenState();
}

class _GenreManagementScreenState extends State<GenreManagementScreen> {
  final controller = Get.put(AdminController());
  final _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    controller.fetchGenres();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _filteredGenres() {
    if (_keyword.trim().isEmpty) return controller.genres;
    return controller.genres
        .where((g) => adminMatchesKeyword(_keyword, [g['nameGenre']?.toString()]))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _keyword.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý thể loại')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(controller),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          AdminSearchBar(
            controller: _searchCtrl,
            hint: 'Tìm theo tên thể loại...',
            onChanged: (v) => setState(() => _keyword = v),
          ),
          if (searching)
            Obx(() => AdminFilterResultBar(count: _filteredGenres().length)),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = _filteredGenres();
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    searching
                        ? 'Không tìm thấy thể loại với "$_keyword"'
                        : 'Chưa có thể loại nào.',
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final genre = items[i];
                  return Card(
                    child: ListTile(
                      title: Text(genre['nameGenre'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showDialog(controller, genre: genre),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(controller, genre['idGenre']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showDialog(AdminController controller, {dynamic genre}) {
    final ctrl = TextEditingController(text: genre?['nameGenre'] ?? '');
    final isEdit = genre != null;

    Get.dialog(AlertDialog(
      title: Text(isEdit ? 'Sửa thể loại' : 'Thêm thể loại'),
      content: adminDialogField(controller: ctrl, label: 'Tên thể loại'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
        ElevatedButton(
          onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isEmpty) return;
            final success = isEdit
                ? await controller.updateGenre(genre['idGenre'], name)
                : await controller.createGenre(name);
            Get.back();
            if (success) Get.snackbar('Thành công', 'Đã lưu');
          },
          child: const Text('Lưu'),
        ),
      ],
    ));
  }

  void _confirmDelete(AdminController controller, int id) {
    Get.dialog(AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: const Text('Bạn có chắc muốn xóa thể loại này?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            final ok = await controller.deleteGenre(id);
            Get.back();
            if (ok) Get.snackbar('Thành công', 'Đã xóa thể loại');
          },
          child: const Text('Xóa'),
        ),
      ],
    ));
  }
}
