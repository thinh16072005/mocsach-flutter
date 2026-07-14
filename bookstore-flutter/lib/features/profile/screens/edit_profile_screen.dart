import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../shared/widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final controller = Get.find<ProfileController>();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  String? _dateOfBirth;
  String? _gender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = controller.user.value;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _addressCtrl = TextEditingController(text: user?.deliveryAddress ?? '');
    
    if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) {
      _dateOfBirth = user.dateOfBirth!.substring(0, 10);
    }
    if (user?.gender != null && user!.gender!.isNotEmpty) {
      _gender = user.gender!.toUpperCase();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Họ đệm',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập họ đệm' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final initial = _dateOfBirth != null
                      ? DateTime.tryParse(_dateOfBirth!) ?? DateTime(2000)
                      : DateTime(2000);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _dateOfBirth =
                        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày sinh',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  child: Text(_dateOfBirth ?? 'Chọn ngày sinh'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'Giới tính',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Nam')),
                  DropdownMenuItem(value: 'F', child: Text('Nữ')),
                ],
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => v == null ? 'Vui lòng chọn giới tính' : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Lưu thay đổi',
                isLoading: _isSaving,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isSaving = true);
                  final success = await controller.updateProfile({
                    'firstName': _firstNameCtrl.text.trim(),
                    'lastName': _lastNameCtrl.text.trim(),
                    'phoneNumber': _phoneCtrl.text.trim(),
                    'deliveryAddress': _addressCtrl.text.trim(),
                    if (_dateOfBirth != null) 'dateOfBirth': _dateOfBirth,
                    if (_gender != null) 'gender': _gender,
                  });
                  setState(() => _isSaving = false);
                  if (success) {
                    Get.back();
                    Get.snackbar('Thành công', 'Cập nhật thông tin thành công!');
                  } else {
                    Get.snackbar(
                      'Lỗi',
                      controller.errorMessage.value.isNotEmpty
                          ? controller.errorMessage.value
                          : 'Cập nhật thất bại',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
