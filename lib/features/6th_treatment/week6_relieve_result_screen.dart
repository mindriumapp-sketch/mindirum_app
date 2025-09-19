import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'week6_relieve_slider_screen.dart';
import 'week6_behavior_classification_screen.dart';

class Week6RelieveResultScreen extends StatelessWidget {
  final String selectedBehavior;
  final String behaviorType; // 'face' 또는 'avoid'
  final double sliderValue; // 슬라이더 값
  final bool isLongTerm; // 단기/장기 구분
  final double? shortTermValue; // 단기 슬라이더 값 (장기일 때만 사용)
  final List<String>? remainingBehaviors; // 남은 행동 목록
  final List<String> allBehaviorList; // 전체 행동 목록

  const Week6RelieveResultScreen({
    super.key,
    required this.selectedBehavior,
    required this.behaviorType,
    required this.sliderValue,
    this.isLongTerm = false, // 기본값은 단기
    this.shortTermValue, // 단기 슬라이더 값
    this.remainingBehaviors,
    required this.allBehaviorList,
  });

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    String mainText;
    String subText;

    // 슬라이더 값에 따라 불안 완화 정도 판단
    bool isHighRelief = sliderValue >= 5.0;
    String timePeriod = isLongTerm ? '장기' : '단기';

    if (behaviorType == 'face') {
      if (isHighRelief) {
        mainText =
            '방금 보셨던 "$selectedBehavior"(라)는 행동을 하게 되면\n$timePeriod적으로 불안이 많이 완화된다고 생각하시는군요.';
        subText =
            isLongTerm
                ? '잘 따라오고 계십니다! 이제 위 행동이 어떤 유형에 속하는지 알아보겠습니다.'
                : '이번에는 위 행동이 장기적으로 얼마나 불안을 완화할 수 있는지 알아볼게요!';
      } else {
        mainText =
            '방금 보셨던 "$selectedBehavior"(라)는 행동을 하게 되면\n$timePeriod적으로 불안이 적게 완화된다고 생각하시는군요.';
        subText =
            isLongTerm
                ? '잘 따라오고 계십니다! 이제 위 행동이 어떤 유형에 속하는지 알아보겠습니다.'
                : '이번에는 위 행동이 장기적으로 얼마나 불안을 완화할 수 있는지 알아볼게요!';
      }
    } else {
      if (isHighRelief) {
        mainText =
            '방금 보셨던 "$selectedBehavior"(라)는 행동을 하게 되면\n$timePeriod적으로 불안이 많이 완화된다고 생각하시는군요.';
        subText =
            isLongTerm
                ? '잘 따라오고 계십니다! 이제 위 행동이 어떤 유형에 속하는지 알아보겠습니다.'
                : '이번에는 위 행동이 장기적으로 얼마나 불안을 완화할 수 있는지 알아볼게요!';
      } else {
        mainText =
            '방금 보셨던 "$selectedBehavior"(라)는 행동을 하게 되면\n$timePeriod적으로 불안이 적게 완화된다고 생각하시는군요.';
        subText =
            isLongTerm
                ? '잘 따라오고 계십니다! 이제 위 행동이 어떤 유형에 속하는지 알아보겠습니다.'
                : '이번에는 위 행동이 장기적으로 얼마나 불안을 완화할 수 있는지 알아볼게요!';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: const CustomAppBar(title: '6주차 - 불안 직면 VS 회피'),
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
                        color: const Color(0xFF5B3EFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      mainText,
                      style: const TextStyle(
                        fontSize: 18,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5B3EFF),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
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
          onNext: () {
            if (isLongTerm && shortTermValue != null) {
              // 장기 결과에서 다음 버튼을 누르면 분류 결과 화면으로 이동
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (_, __, ___) => Week6BehaviorClassificationScreen(
                        selectedBehavior: selectedBehavior,
                        behaviorType: behaviorType,
                        shortTermValue: shortTermValue!,
                        longTermValue: sliderValue,
                        remainingBehaviors: remainingBehaviors,
                        allBehaviorList: allBehaviorList,
                      ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            } else {
              // 단기 결과에서 다음 버튼을 누르면 장기 슬라이더로 이동
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (_, __, ___) => Week6RelieveSliderScreen(
                        selectedBehavior: selectedBehavior,
                        behaviorType: behaviorType,
                        isLongTerm: true, // 장기 슬라이더로 이동
                        shortTermValue: sliderValue, // 단기 값 전달
                        remainingBehaviors: remainingBehaviors,
                        allBehaviorList: allBehaviorList,
                      ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
