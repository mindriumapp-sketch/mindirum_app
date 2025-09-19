import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/models/mongo_service.dart';

import 'package:gad_app_team/features/settings/setting_screen.dart';
import 'package:gad_app_team/widgets/input_text_field.dart';
import 'package:gad_app_team/widgets/card_container.dart';
import 'package:gad_app_team/widgets/passwod_field.dart';
import 'package:gad_app_team/widgets/internal_action_button.dart';

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isCurrentPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  String? _uid;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      if (uid == null || uid.isEmpty) return;
      _uid = uid;

      final svc = MongoService.instance;
      await svc.open();
      final doc = await svc.fetchUser(userId: uid);
      if (doc != null) {
        final name = (doc['name'] ?? doc['userName'] ?? '') as String? ?? '';
        final email = (doc['email'] ?? '') as String? ?? '';
        _nameController.text = name;
        _emailController.text = email;

        final raw = doc['createdAt'];
        if (raw is DateTime) {
          _createdAt = raw;
        } else if (raw is String) {
          try { _createdAt = DateTime.parse(raw); } catch (_) {}
        }
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _updateUserInfo() async {
    final newName = _nameController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (_uid == null || _uid!.isEmpty) {
      _showMessage('로그인 정보가 없습니다.');
      return;
    }
    if (currentPassword.isEmpty) {
      _showMessage('기존 비밀번호를 입력해야 수정할 수 있습니다.');
      return;
    }
    if (newPassword.isNotEmpty && newPassword != confirmPassword) {
      _showMessage('새 비밀번호가 일치하지 않습니다.');
      return;
    }

    try {
      final svc = MongoService.instance;
      await svc.open();
      final doc = await svc.fetchUser(userId: _uid!);
      if (doc == null) {
        _showMessage('사용자 정보를 찾을 수 없습니다.');
        return;
      }

      final stored = (doc['passwordHash'] ?? '') as String;
      if (stored != currentPassword) {
        _showMessage('기존 비밀번호가 올바르지 않습니다.');
        return;
      }

      // 업데이트 필드 구성
      final updates = <String, dynamic>{};
      if (newName.isNotEmpty && newName != (doc['name'] ?? '')) {
        updates['name'] = newName;
      }
      if (newPassword.isNotEmpty) {
        updates['passwordHash'] = newPassword; // 평문 저장(현 정책)
        updates['passwordSalt'] = '';
      }
      if (updates.isEmpty) {
        _showMessage('변경된 내용이 없습니다.');
        return;
      }

      await svc.updateUserFields(userId: _uid!, updates: updates);

      // 화면 갱신
      if (updates.containsKey('name')) {
        _nameController.text = newName;
      }
      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }

      _showMessage('계정 정보가 성공적으로 수정되었습니다.');
    } catch (e) {
      _showMessage('수정 실패: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('uid');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal:AppSizes.padding),
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSizes.space),
            _buildInfoCard(),
            TextButton(
              onPressed: _logout,
              child: const Text('로그아웃', style: TextStyle(color: AppColors.indigo)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    final formattedDate = _createdAt != null ? DateFormat('yyyy년 MM월 dd일').format(_createdAt!) : '가입일 정보 없음';

    return CardContainer(
      title: '계정 정보',
      child: Column(
        children: [
          InputTextField(label: '이름', controller: _nameController),
          const SizedBox(height: AppSizes.space),
          InputTextField(label: '이메일', controller: _emailController, enabled: false),
          const SizedBox(height: AppSizes.space),
          Align(
            alignment: Alignment.centerRight,
            child: Text('가입일: $formattedDate', style: const TextStyle(color: AppColors.grey)),
          ),
          const Divider(thickness: 1, color: AppColors.black12),
          const SizedBox(height: AppSizes.space),

          PasswordTextField(
            label: '기존 비밀번호',
            controller: _currentPasswordController,
            isVisible: isCurrentPasswordVisible,
            toggleVisibility: () {
              setState(() {
                isCurrentPasswordVisible = !isCurrentPasswordVisible;
              });
            },
          ),
          const SizedBox(height: AppSizes.space),

          PasswordTextField(
            label: '새 비밀번호',
            controller: _newPasswordController,
            isVisible: isNewPasswordVisible,
            toggleVisibility: () {
              setState(() {
                isNewPasswordVisible = !isNewPasswordVisible;
              });
            },
          ),
          const SizedBox(height: AppSizes.space),

          PasswordTextField(
            label: '새 비밀번호 확인',
            controller: _confirmPasswordController,
            isVisible: isConfirmPasswordVisible,
            toggleVisibility: () {
              setState(() {
                isConfirmPasswordVisible = !isConfirmPasswordVisible;
              });
            },
          ),
          const SizedBox(height: AppSizes.space),
          const SizedBox(height: AppSizes.space),
          Center(child: InternalActionButton(onPressed: _updateUserInfo, text: '계정 정보 수정')),
        ],
      ),
    );
  }
}