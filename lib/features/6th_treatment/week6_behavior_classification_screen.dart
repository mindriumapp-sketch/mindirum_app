import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'week6_behavior_reflection_screen.dart';

class Week6BehaviorClassificationScreen extends StatelessWidget {
  final String selectedBehavior;
  final String behaviorType; // 'face' 또는 'avoid'
  final double shortTermValue; // 단기 슬라이더 값
  final double longTermValue; // 장기 슬라이더 값
  final List<String>? remainingBehaviors; // 남은 행동 목록
  final List<String> allBehaviorList; // 전체 행동 목록

  const Week6BehaviorClassificationScreen({
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

    // 분류 로직
    bool isShortTermHigh = shortTermValue >= 5.0;
    bool isLongTermHigh = longTermValue >= 5.0;

    String mainText;
    String subText;

    if (isShortTermHigh && !isLongTermHigh) {
      // 단기적으로 높고 장기적으로 낮음 → 불안을 회피하는 행동
      mainText = '방금 보셨던 "$selectedBehavior"(라)는 행동을 분석해보니 불안을 회피하는 행동에 가깝습니다.';
      subText =
          '단기적으로는 불안이 많이 완화되지만 장기적으로는 적게 완화되는 패턴을 보이기 때문이에요. 이런 행동은 일시적으로 불안이 완화돼서 편안함을 주지만, 지속 시 불안을 해결하지 못할 수 있어요.';
    } else if (!isShortTermHigh && isLongTermHigh) {
      // 단기적으로 낮고 장기적으로 높음 → 불안을 직면하는 행동
      mainText = '방금 보셨던 "$selectedBehavior"(라)는 행동을 분석해보니 불안을 직면하는 행동에 가깝습니다.';
      subText =
          '단기적으로는 불안이 적게 완화되지만 장기적으로는 많이 완화되는 패턴을 보이기 때문이에요. 이런 행동은 일시적으로 불안이 높아져서 처음에는 어려울 수 있지만, 지속 시 불안을 해결하는 데 도움이 될 수 있어요!';
    } else if (isShortTermHigh && isLongTermHigh) {
      // 단기/장기 모두 높음 → 중립적
      mainText = '방금 보셨던 "$selectedBehavior"(라)는 행동을 분석해보니 중립적인 행동에 가깝습니다.';
      subText = '단기적으로도 장기적으로도 불안이 많이 완화되는 패턴을 보이기 때문이에요. (적절한 문구 생각하기)';
    } else {
      // 단기/장기 모두 낮음 → 중립적
      mainText = '방금 보셨던 "$selectedBehavior"(라)는 행동을 분석해보니 중립적인 행동에 가깝습니다.';
      subText =
          '단기적으로도 장기적으로도 불안이 적게 완화되는 패턴을 보이기 때문이에요. 이런 행동은 불안 해결에 큰 도움이 되지 않을 수 있어요.';
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
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (_, __, ___) => Week6BehaviorReflectionScreen(
                      selectedBehavior: selectedBehavior,
                      behaviorType: behaviorType,
                      shortTermValue: shortTermValue,
                      longTermValue: longTermValue,
                      remainingBehaviors: remainingBehaviors,
                      allBehaviorList: allBehaviorList,
                    ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
        ),
      ),
    );
  }
}
