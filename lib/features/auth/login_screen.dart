import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:gad_app_team/data/mongo_service.dart';

import 'package:gad_app_team/widgets/input_text_field.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';

/// 로그인 화면: 이메일과 비밀번호로 인증
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _login() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('이메일과 비밀번호를 입력해주세요.');
      return;
    }

    try {
      // 1) DB 연결
      final svc = MongoService.instance;
      await svc.open();

      // 2) 이메일로 사용자 찾기
      final userDoc = await svc.findUserByEmail(email: email);
      if (userDoc == null) {
        _showError('가입된 이메일을 찾을 수 없습니다.');
        return;
      }

      // 3) 비밀번호 검증 (해시 사용 안 함: 평문 비교)
      //    우선 nested user.password를 보고, 없으면 상위 password를 본다.
      String stored = '';
      final nestedUser = userDoc['user'];
      if (nestedUser is Map) {
        final np = nestedUser['password'];
        if (np is String) stored = np;
      }
      if (stored.isEmpty) {
        final tp = userDoc['password'];
        if (tp is String) stored = tp;
      }
      if (stored.isEmpty) {
        _showError('계정에 비밀번호 정보가 없습니다. 관리자에게 문의해주세요.');
        return;
      }
      if (stored != password) {
        _showError('비밀번호가 올바르지 않습니다.');
        return;
      }

      // 4) 로그인 유지 플래그 및 uid 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // ObjectId 또는 문자열 대응
      final rawId = userDoc['_id'];
      final uid = (rawId is ObjectId) ? rawId.oid : rawId.toString();
      await prefs.setString('uid', uid);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/tutorial');
    } catch (e) {
      _showError('로그인 중 오류가 발생했습니다. 네트워크를 확인하고 다시 시도해주세요.');
    }
  }

  void _goToSignup() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    Navigator.pushNamed(context, '/terms', arguments: {
      'email': email,
      'password': password,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSizes.space),
              Center(
                child: Image.asset(
                  'assets/image/logo.png',
                  height: 160,
                  width: 160,
                ),
              ),
              const SizedBox(height: AppSizes.space),
              InputTextField(
                controller: emailController,
                fillColor:Colors.white,
                label: '이메일',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSizes.space),
              InputTextField(
                controller: passwordController,
                fillColor:Colors.white,
                label: '비밀번호',
                obscureText: true,
              ),
              const SizedBox(height: AppSizes.space),

              PrimaryActionButton(
                text: '로그인',
                onPressed: _login,
              ),

              TextButton(
                onPressed: _goToSignup,
                child: const Text('회원가입')
              ),
            ],
          ),
        ),
      ),
    );
  }
}
