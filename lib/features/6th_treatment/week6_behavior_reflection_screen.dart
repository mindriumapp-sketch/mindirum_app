import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'week6_classfication_screen.dart';

class Week6BehaviorReflectionScreen extends StatelessWidget {
  final String selectedBehavior;
  final String behaviorType; // 'face' 또는 'avoid'
  final double shortTermValue; // 단기 슬라이더 값
  final double longTermValue; // 장기 슬라이더 값
  final List<String>? remainingBehaviors; // 남은 행동 목록
  final List<String> allBehaviorList; // 전체 행동 목록

  const Week6BehaviorReflectionScreen({
    super.key,
    required this.selectedBehavior,
    required this.behaviorType,
    required this.shortTermValue,
    required this.longTermValue,
    this.remainingBehaviors,
    required this.allBehaviorList,
  });

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // 분류 로직 (이전 화면과 동일)
    bool isShortTermHigh = shortTermValue >= 5.0;
    bool isLongTermHigh = longTermValue >= 5.0;

    // 실제 분석 결과 (슬라이더 값 기반)
    String actualResult;
    if (isShortTermHigh && !isLongTermHigh) {
      actualResult = '불안을 회피하는 행동';
    } else if (!isShortTermHigh && isLongTermHigh) {
      actualResult = '불안을 직면하는 행동';
    } else {
      actualResult = '중립적인 행동';
    }

    // 사용자가 선택한 분류
    String userChoice = behaviorType == 'face' ? '불안을 직면하는 행동' : '불안을 회피하는 행동';

    String mainText;
    String subText;
    String? additionalText;

    // 분류 결과와 실제 분석 결과가 다른지 확인
    bool isDifferent =
        (behaviorType == 'face' && !(isShortTermHigh && !isLongTermHigh)) ||
        (behaviorType == 'avoid' && !(isShortTermHigh && !isLongTermHigh));

    if (isShortTermHigh && !isLongTermHigh) {
      // 실제로는 불안을 회피하는 행동
      mainText = '방금 보셨던 "$selectedBehavior"(라)는 $userChoice이라고 선택하셨습니다.';
      if (isDifferent) {
        subText =
            '실제로 이 행동은 분석결과 $actualResult으로 보이네요.\n이 행동이 과연 나에게 도움이 되는지 다시 한번 더 생각해보아요!';
      } else {
        subText =
            '실제로 이 행동은 분석결과 $actualResult으로 보이네요.\n이 행동이 과연 나에게 도움이 되는지 다시 한번 더 생각해보아요!';
      }
    } else if (!isShortTermHigh && isLongTermHigh) {
      // 실제로는 불안을 직면하는 행동
      mainText = '방금 보셨던 "$selectedBehavior"(라)는 $userChoice이라고 선택하셨습니다.';
      if (isDifferent) {
        subText =
            '실제로 이 행동은 분석결과 $actualResult으로 보이네요.\n이 행동이 과연 나에게 도움이 되는지 다시 한번 더 생각해보아요!';
      } else {
        subText =
            '실제로 이 행동은 분석결과 $actualResult으로 보이네요.\n이 행동이 과연 나에게 도움이 되는지 다시 한번 더 생각해보아요!';
      }
    } else if (isShortTermHigh && isLongTermHigh) {
      // 중립적인 행동 (긍정적)
      mainText = '방금 보셨던 "$selectedBehavior"(라)는 $userChoice이라고 선택하셨습니다.';
      if (isDifferent) {
        subText =
            '실제로 이 행동은 분석결과 $actualResult으로 보이네요.\n이 행동이 과연 나에게 도움이 되는지 다시 한번 더 생각해보아요!';
      } else {
        subText =
            '실제로 이 행동은 분석결과 $actualResult으로 보이네요.\n이 행동이 과연 나에게 도움이 되는지 다시 한번 더 생각해보아요!';
      }
    } else {
      // 중립적인 행동 (부정적)
      mainText = '방금 보셨던 "$selectedBehavior"(라)는 $userChoice이라고 선택하셨습니다.';
      if (isDifferent) {
        subText =
            '실제로 이 행동은 분석결과 $actualResult으로 보이네요.\n이 행동이 과연 나에게 도움이 되는지 다시 한번 더 생각해보아요!';
      } else {
        subText =
            '실제로 이 행동은 분석결과 $actualResult으로 보이네요.\n이 행동이 과연 나에게 도움이 되는지 다시 한번 더 생각해보아요!';
      }
    }

    // 추가 행동이 있는지 확인
    if (remainingBehaviors != null && remainingBehaviors!.isNotEmpty) {
      additionalText = '다음 행동도 계속 진행하겠습니다!';
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
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '단기 완화: ${shortTermValue.round()}점 | 장기 완화: ${longTermValue.round()}점',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8888AA),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (additionalText != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        additionalText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5B3EFF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
            if (remainingBehaviors != null && remainingBehaviors!.isNotEmpty) {
              // 추가 행동이 있으면 분류 화면으로 이동하여 루프 계속
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (_, __, ___) => Week6ClassificationScreen(
                        behaviorListInput: remainingBehaviors!,
                        allBehaviorList: allBehaviorList,
                      ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            } else {
              // 모든 행동을 다 처리했으면 홈 화면으로 이동
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            }
          },
        ),
      ),
    );
  }
}
