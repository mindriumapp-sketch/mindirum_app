import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
// ===== FIREBASE (주석 처리: MongoDB로 대체) =====
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gad_app_team/widgets/input_text_field.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import 'package:gad_app_team/widgets/passwod_field.dart';

import 'package:gad_app_team/models/mongo_service.dart';

/// 회원가입 화면 - 이메일, 이름, 비밀번호, 마인드리움 코드로 회원가입
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  // final codeController = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;

  // MongoDB 서비스 (Firebase 대체)
  final MongoService _mongo = MongoService.instance;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Future<bool> checkMindriumCode(String inputCode) async {
  //   final code = inputCode.trim();
  //   try {
  //     await _ensureMongoOpen();
  //     return await _mongo.isCodeValid(code);
  //   } catch (e) {
  //     debugPrint("코드 확인 중 오류 발생: $e");
  //     return false;
  //   }
  // }

  Future<void> _ensureMongoOpen() async {
    await _mongo.open(); // 연결 실패 시 예외를 그대로 올려서 처리
  }
  

  Future<void> _signup() async {
    final email = emailController.text.trim().toLowerCase();
    final name = nameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    // final code = codeController.text.trim();
  
    if ([email, name, password, confirmPassword].any((e) => e.isEmpty)) {
      _showError('모든 필드를 입력해주세요.');
      return;
    }
    if (password.length < 6) {
      _showError('비밀번호는 6자리 이상이어야 합니다.');
      return;
    }
    if (password != confirmPassword) {
      _showError('비밀번호가 일치하지 않습니다.');
      return;
    }
  
    // 마인드리움 코드 확인
    // final isValidCode = await checkMindriumCode(code);
    // if (!isValidCode) {
    //   _showError('유효하지 않은 마인드리움 코드입니다.');
    //   return;
    // }
  
    try {
      await _ensureMongoOpen();
  
      // 이메일 중복 체크
      final existing = await _mongo.getUserByEmail(email);
      if (existing != null) {
        _showError('이미 등록된 이메일입니다. 로그인 화면으로 이동합니다.');
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login', arguments: {
          'email': email,
          'password': password,
        });
        return;
      }
  
      // 비밀번호를 해시 없이 원문으로 저장 (보안상 권장되지 않음)
      await _mongo.createUser(
        email: email,
        name: name,
        // code: code,
        password: password, // plain text 저장
      );
  
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다.')),
      );
      Navigator.pushReplacementNamed(context, '/login', arguments: {
        'email': email,
        'password': password
      });
    } catch (e, stack) {
      _showError('회원가입 실패: $e');
      debugPrint("Signup Exception: $e");
      debugPrint("Stack trace: $stack");
    }
  }

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      emailController.text = args['email'] ?? '';
      passwordController.text = args['password'] ?? '';
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {Navigator.pop(context);},
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          children: [
            InputTextField(
              controller: emailController, 
              fillColor:Colors.white,
              label: '이메일', 
              keyboardType: TextInputType.emailAddress
            ),
            const SizedBox(height: AppSizes.space),
            InputTextField(
              controller: nameController, 
              label: '이름',
              fillColor:Colors.white,
            ),
            const SizedBox(height: AppSizes.space),
            PasswordTextField(
              controller: passwordController,
              label: '비밀번호',
              isVisible: showPassword,
              toggleVisibility: () {
                setState(() {
                  showPassword = !showPassword;
                });
              },
            ),
            const SizedBox(height: AppSizes.space),
            PasswordTextField(
              controller: confirmPasswordController,
              label: '비밀번호 확인',
              isVisible: showConfirmPassword,
              toggleVisibility: () {
                setState(() {
                  showConfirmPassword = !showConfirmPassword;
                });
              },
            ),
            // const SizedBox(height: AppSizes.space),
            // InputTextField(
            //   controller: codeController, 
            //   label: '마인드리움 코드',
            //   fillColor:Colors.white,
            // ),
            const SizedBox(height: AppSizes.space*2),
            PrimaryActionButton(text: '회원가입', onPressed: _signup),
          ],
        ),
      ),
    );
  }
}
