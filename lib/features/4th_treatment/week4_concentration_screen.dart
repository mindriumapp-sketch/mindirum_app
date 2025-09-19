import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/features/4th_treatment/week4_classfication_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Week4ConcentrationScreen extends StatefulWidget {
  final List<String> bListInput;
  final int beforeSud;
  final List<String> allBList;
  final String? abcId;

  const Week4ConcentrationScreen({
    super.key,
    required this.bListInput,
    required this.beforeSud,
    required this.allBList,
    this.abcId
  });

  @override
  State<Week4ConcentrationScreen> createState() =>
      _Week4ConcentrationScreenState();
}

class _Week4ConcentrationScreenState extends State<Week4ConcentrationScreen> {
  bool _isNextEnabled = false;
  int _secondsLeft = 10;
  Map<String, dynamic>? _abcModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // abcId가 전달되면 해당 문서를, 없으면 기존(최신) 로직으로 불러온다
    final id = widget.abcId;
    if (id != null && id.isNotEmpty) {
      _fetchAbcModelById(id);
    } else {
      _fetchLatestAbcModel();
    }
  }

  /// 최신(가장 최근 createdAt) ABC 모델 1건을 불러온다.
  Future<void> _fetchLatestAbcModel() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 정보 없음');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_models')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        setState(() {
          _abcModel = null;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _abcModel = snapshot.docs.first.data();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 특정 abcId 의 ABC 모델 문서를 불러온다.
  Future<void> _fetchAbcModelById(String abcId) async {
    try {
      if (mounted) setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 정보 없음');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_models')
          .doc(abcId)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        setState(() {
          _abcModel = null;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _abcModel = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      if (_secondsLeft > 0) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return false;
        setState(() {
          _secondsLeft--;
        });
        return true;
      } else {
        setState(() {
          _isNextEnabled = true;
        });
        return false;
      }
    });
  }

  String _getFirstBelief(dynamic belief) {
    if (belief == null) return '';

    // 문자열인 경우 쉼표로 분리하여 첫번째 요소 반환
    if (belief is String) {
      final parts =
          belief
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      return parts.isNotEmpty ? parts.first : '';
    }

    // 리스트인 경우 첫번째 요소 반환
    if (belief is List) {
      return belief.isNotEmpty ? belief.first.toString() : '';
    }

    // 기타 타입은 문자열로 변환 후 처리
    final beliefStr = belief.toString();
    final parts =
        beliefStr
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    return parts.isNotEmpty ? parts.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: const CustomAppBar(title: '4주차 - 인지 왜곡 찾기'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 48.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$userName님',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5B3EFF),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color(0xFF5B3EFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Column(
                        children: [
                          Text(
                            _abcModel != null
                                ? "'${_abcModel!['activatingEvent'] ?? ''}' (라)는 상황을 잠시 집중해보겠습니다."
                                : '이때의 상황을\n자세하게 집중해 보세요.',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              height: 1.6,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_abcModel != null &&
                              _abcModel!['belief'] != null &&
                              _abcModel!['belief'].toString().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              "'${_getFirstBelief(_abcModel!['belief'])}'\n생각에 대해 얼마나 강하게 믿고 계신지 알아볼게요.",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5B3EFF),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            Text(
                              '위 생각에 대해 어느 정도 믿음을 가지고 있는지 알아볼게요.',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5B3EFF),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 32),
                    if (!_isNextEnabled)
                      Text(
                        '$_secondsLeft초 후에 다음 버튼이 활성화됩니다',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFB0B0B0),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: NavigationButtons(
          onBack: () => Navigator.pop(context),
          onNext:
              _isNextEnabled
                  ? () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (_, __, ___) => Week4ClassificationScreen(
                              bListInput:
                                  widget.allBList, // 모든 B 생각들을 전달 (건너뛴 생각들 포함)
                              beforeSud: widget.beforeSud,
                              allBList: widget.allBList,
                              abcId: widget.abcId
                            ),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  }
                  : null,
        ),
      ),
    );
  }
}
