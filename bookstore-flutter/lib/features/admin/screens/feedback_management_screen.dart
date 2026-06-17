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
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    controller.fetchFeedbacks(page: 0);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _keyword = value);
    if (value.trim().isEmpty) {
      controller.fetchFeedbacks(page: 0, size: 10);
    } else {
      controller.fetchFeedbacks(page: 0, size: 200);
    }
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
            if (searching) {
              return AdminFilterResultBar(count: _filteredFeedbacks().length);
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = _filteredFeedbacks();
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    searching
                        ? 'Không tìm thấy phản hồi với "$_keyword"'
                        : 'Chưa có phản hồi nào.',
                  ),
                );
              }
              return ListView.builder(
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
                      title: Text(f['content'] ?? ''),
                      subtitle: Text('User ID: ${f['userId']} • ${f['createdAt'] ?? ''}'),
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
                            onPressed: () => controller.deleteFeedback(f['idFeedback']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          if (!searching) _Pagination(controller: controller),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final AdminController controller;
  const _Pagination({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: controller.feedbackPage.value > 0 ? controller.feedbackPrevPage : null,
            ),
            Text('Trang ${controller.feedbackPage.value + 1} / ${controller.feedbackTotalPages.value}'),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: controller.feedbackPage.value < controller.feedbackTotalPages.value - 1
                  ? controller.feedbackNextPage
                  : null,
            ),
          ],
        ));
  }
}
