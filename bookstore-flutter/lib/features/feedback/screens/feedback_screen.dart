import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/feedback_controller.dart';
import '../../../shared/widgets/custom_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _controller = Get.put(FeedbackController());
  final _contentCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await _controller.sendFeedback(_contentCtrl.text.trim());
    if (success) {
      Get.snackbar('Thành công', 'Cảm ơn phản hồi của bạn!');
      _contentCtrl.clear();
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gửi phản hồi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('Chúng tôi rất mong nhận được góp ý của bạn!'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentCtrl,
                maxLines: 6,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Nội dung phản hồi',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.length < 10) return 'Nội dung tối thiểu 10 ký tự';
                  if (text.length > 1000) return 'Nội dung tối đa 1000 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Obx(() => CustomButton(
                    text: 'Gửi',
                    icon: Icons.send,
                    isLoading: _controller.isLoading.value,
                    onPressed: _onSubmit,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
