import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_ui.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() => _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  final controller = Get.put(AdminController());
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _keyword = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    controller.fetchFeedbacks(page: 0);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      controller.loadMoreFeedbacks();
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _keyword = value);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isEmpty) {
        controller.fetchFeedbacks(page: 0, size: 10);
      } else {
        controller.fetchFeedbacks(page: 0, size: 200);
      }
    });
  }

  List<dynamic> _filteredFeedbacks() {
    if (_keyword.trim().isEmpty) return controller.feedbacks;
    return controller.feedbacks.where((f) {
      return adminMatchesKeyword(_keyword, [
        f['content']?.toString(),
        f['userId']?.toString(),
        f['createdAt']?.toString(),
      ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _keyword.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('Phản hồi (${controller.unreadFeedbackCount.value} chưa đọc)')),
      ),
      body: Column(
        children: [
          AdminSearchBar(
            controller: _searchCtrl,
            hint: 'Tìm theo nội dung, user ID...',
            onChanged: _onSearchChanged,
          ),
          Obx(() {
            // Reference rx variable to avoid GetX improper use error when searching is false
            final _ = controller.feedbacks.length;
            if (searching) {
              return AdminFilterResultBar(count: _filteredFeedbacks().length);
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              final items = _filteredFeedbacks();
              if (controller.isLoading.value && items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    searching
                        ? 'Không tìm thấy phản hồi với "$_keyword"'
                        : 'Chưa có phản hồi nào.',
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final f = items[i];
                        final isRead = f['read'] == true;
                        return Card(
                          color: isRead ? null : Colors.indigo.shade50,
                          child: ListTile(
                            leading: Icon(
                              isRead ? Icons.drafts : Icons.markunread,
                              color: isRead ? Colors.grey : Colors.indigo,
                            ),
                            title: Text(
                              f['content'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text('User ID: ${f['userId']} • ${_formatDate(f['createdAt'])}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isRead)
                                  IconButton(
                                    icon: const Icon(Icons.done),
                                    tooltip: 'Đánh dấu đã đọc',
                                    onPressed: () => controller.markFeedbackRead(f['idFeedback']),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(f['idFeedback']),
                                ),
                              ],
                            ),
                            onTap: () => _showDetailsDialog(f, isRead),
                          ),
                        );
                      },
                    ),
                  ),
                  if (controller.isLoadingMoreFeedbacks.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (controller.feedbackPage.value < controller.feedbackTotalPages.value - 1 && !searching)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextButton.icon(
                        onPressed: () => controller.loadMoreFeedbacks(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tải thêm phản hồi'),
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

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    if (s.contains('T')) {
      final parts = s.split('T');
      final date = parts[0];
      final time = parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
      return '$date $time';
    }
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  void _confirmDelete(int id) {
    Get.dialog(AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: const Text('Bạn có chắc muốn xóa phản hồi này?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            controller.deleteFeedback(id);
            Get.back();
          },
          child: const Text('Xóa'),
        ),
      ],
    ));
  }

  void _showDetailsDialog(dynamic f, bool isRead) {
    Get.dialog(AlertDialog(
      title: Text('Phản hồi từ User #${f['userId']}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDate(f['createdAt']),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(f['content'] ?? ''),
          ],
        ),
      ),
      actions: [
        if (!isRead)
          ElevatedButton(
            onPressed: () {
              controller.markFeedbackRead(f['idFeedback']);
              Get.back();
            },
            child: const Text('Đánh dấu đã đọc'),
          ),
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Đóng'),
        ),
      ],
    ));
  }
}
