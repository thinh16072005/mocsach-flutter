import 'package:flutter/material.dart';

/// Khoảng cách giữa các ô nhập trong dialog/form admin.
const double kAdminFieldGap = 16;

/// Cột form/dialog với khoảng cách đều giữa các field (tránh input dính nhau).
class AdminFormFields extends StatelessWidget {
  final List<Widget> children;

  const AdminFormFields({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: kAdminFieldGap),
          children[i],
        ],
      ],
    );
  }
}

/// TextField chuẩn cho dialog admin (viền outline + padding).
Widget adminDialogField({
  required TextEditingController controller,
  required String label,
  TextInputType? keyboardType,
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
  );
}

/// Thanh tìm kiếm dùng chung cho các màn quản lý (giống BookStoreSBA).
class AdminSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const AdminSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

/// Hiển thị số kết quả sau khi lọc (khi đang tìm kiếm).
class AdminFilterResultBar extends StatelessWidget {
  final int count;
  final bool visible;

  const AdminFilterResultBar({super.key, required this.count, this.visible = true});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Tìm thấy $count kết quả',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
      ),
    );
  }
}

String adminNormalize(String s) => s.toLowerCase().trim();

/// Lọc client-side: khớp nếu bất kỳ field nào chứa từ khóa (không phân biệt hoa thường).
bool adminMatchesKeyword(String keyword, Iterable<String?> fields) {
  final k = adminNormalize(keyword);
  if (k.isEmpty) return true;
  for (final f in fields) {
    if ((f ?? '').toLowerCase().contains(k)) return true;
  }
  return false;
}
