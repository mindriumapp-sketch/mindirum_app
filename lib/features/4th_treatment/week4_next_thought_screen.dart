import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/features/4th_treatment/week4_classfication_screen.dart';

class Week4NextThoughtScreen extends StatefulWidget {
  final List<String> remainingBList;
  final int beforeSud;
  final List<String> allBList;
  final List<String>? alternativeThoughts;
  final bool isFromAnxietyScreen;
  final List<String> addedAnxietyThoughts;
  final List<String>? existingAlternativeThoughts;
  final String? abcId;

  const Week4NextThoughtScreen({
    super.key,
    required this.remainingBList,
    required this.beforeSud,
    required this.allBList,
    this.alternativeThoughts,
    this.isFromAnxietyScreen = false,
    this.addedAnxietyThoughts = const [],
    this.existingAlternativeThoughts,
    this.abcId
  });

  @override
  State<Week4NextThoughtScreen> createState() => _Week4NextThoughtScreenState();
}

class _Week4NextThoughtScreenState extends State<Week4NextThoughtScreen> {
  bool _isNextEnabled = false;
  int _secondsLeft = 5;

  @override
  void initState() {
    super.initState();
    _startCountdown();
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

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;
    final nextThought =
        widget.remainingBList.isNotEmpty ? widget.remainingBList.first : '';

    // 불안한 생각을 추가한 경우의 텍스트 구성
    String mainText;
    String subText;

    if (widget.isFromAnxietyScreen && widget.addedAnxietyThoughts.isNotEmpty) {
      final anxietyThought = widget.addedAnxietyThoughts.first;
      mainText = '또 다른 불안한 생각을 추가해주셨습니다.';
      subText = "'$anxietyThought'\n생각에 대해 얼마나 강하게 믿고 계신지 알아볼게요.";
    } else {
      mainText = '잘 진행하고 계십니다!\n이제 다음 생각에 대해\n진행해보겠습니다.';
      subText = "'$nextThought' 생각에 대해 계속 진행해보겠습니다.";
    }

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
                    Text(
                      mainText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5B3EFF),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
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
                                  widget.isFromAnxietyScreen
                                      ? widget.addedAnxietyThoughts
                                      : widget.remainingBList,
                              beforeSud: widget.beforeSud,
                              allBList: widget.allBList,
                              alternativeThoughts: widget.alternativeThoughts,
                              isFromAnxietyScreen: widget.isFromAnxietyScreen,
                              existingAlternativeThoughts:
                                  widget.existingAlternativeThoughts,
                              abcId: widget.abcId,
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
