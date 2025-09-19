import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'week6_relieve_result_screen.dart';

class Week6RelieveSliderScreen extends StatefulWidget {
  final String selectedBehavior;
  final String behaviorType; // 'face' 또는 'avoid'
  final bool isLongTerm; // 단기/장기 구분
  final double? shortTermValue; // 단기 슬라이더 값 (장기일 때만 사용)
  final List<String>? remainingBehaviors; // 남은 행동 목록
  final List<String> allBehaviorList; // 전체 행동 목록

  const Week6RelieveSliderScreen({
    super.key,
    required this.selectedBehavior,
    required this.behaviorType,
    this.isLongTerm = false, // 기본값은 단기
    this.shortTermValue, // 단기 슬라이더 값
    this.remainingBehaviors,
    required this.allBehaviorList,
  });

  @override
  State<Week6RelieveSliderScreen> createState() =>
      _Week6RelieveSliderScreenState();
}

class _Week6RelieveSliderScreenState extends State<Week6RelieveSliderScreen> {
  double _sliderValue = 5.0;

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: const CustomAppBar(title: '6주차 - 불안 직면 VS 회피'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 상단 카드
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/image/question_icon.png',
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$userName님께서 걱정일기에 작성해주신 행동을 보며 진행해주세요.',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.selectedBehavior,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 하단 카드
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.isLongTerm
                              ? '위 행동을 하신다면 장기적으로 얼마나 불안을 완화될까요?\n아래 슬라이더를 조정해 주세요.'
                              : '위 행동을 하신다면 단기적으로 얼마나 불안을 완화될까요?\n아래 슬라이더를 조정해 주세요.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        Slider(
                          value: _sliderValue,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: _sliderValue.round().toString(),
                          activeColor: Color.lerp(
                            Color(0xFFFF5252),
                            Color(0xFF4CAF50),
                            _sliderValue / 10,
                          ),
                          inactiveColor: Colors.grey[300],
                          onChanged: (v) => setState(() => _sliderValue = v),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_sliderValue.round()}점',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0점: 전혀 완화되지 않음',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFFF5252),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '10점: 매우 완화됨',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            NavigationButtons(
              onBack: () => Navigator.pop(context),
              onNext: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (_, __, ___) => Week6RelieveResultScreen(
                          selectedBehavior: widget.selectedBehavior,
                          behaviorType: widget.behaviorType,
                          sliderValue: _sliderValue,
                          isLongTerm: widget.isLongTerm, // 단기/장기 구분 전달
                          shortTermValue: widget.shortTermValue, // 단기 값 전달
                          remainingBehaviors: widget.remainingBehaviors,
                          allBehaviorList: widget.allBehaviorList,
                        ),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
