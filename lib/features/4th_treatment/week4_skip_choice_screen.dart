import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'week4_concentration_screen.dart';
import 'week4_anxiety_screen.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';

class Week4SkipChoiceScreen extends StatelessWidget {
  final List<String> allBList;
  final int beforeSud;
  final List<String> remainingBList;
  final bool isFromAfterSud;
  final List<String>? existingAlternativeThoughts;
  final String? abcId;

  const Week4SkipChoiceScreen({
    super.key,
    required this.allBList,
    required this.beforeSud,
    required this.remainingBList,
    this.isFromAfterSud = false,
    this.existingAlternativeThoughts,
    this.abcId
  });

  @override
  Widget build(BuildContext context) {
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
                child: Builder(
                  builder: (context) {
                    final userName =
                        Provider.of<UserProvider>(
                          context,
                          listen: false,
                        ).userName;
                    return Column(
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
                          isFromAfterSud
                              ? "아직 불안 점수가 낮아지지 않으셨네요. 또 다른 불안한 생각이 있어서 그럴 수 있어요.\n불안을 만드는 또 다른 생각을 하나 찾아보도록 해요!"
                              : "아직 도움이 되는 생각을 찾아보지 않은 부분이 있으시네요.\n모든 생각에서 꼭 도움이 되는 생각을 찾아봐야 하는 건 아니지만,\n 그 중 하나라도 '조금 덜 불안해지는 방향'으로 바라보면 어떨까요?",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        // 상하로 배치된 버튼들
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              if (!isFromAfterSud) ...[
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Skip했던 생각들에 대해 다시 대체 생각 작성
                                      Navigator.pushReplacement(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                _,
                                                __,
                                                ___,
                                              ) => Week4ConcentrationScreen(
                                                bListInput:
                                                    allBList, // 모든 B 생각들을 전달
                                                beforeSud: beforeSud,
                                                allBList: allBList,
                                                abcId: abcId,
                                              ),
                                          transitionDuration: Duration.zero,
                                          reverseTransitionDuration:
                                              Duration.zero,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2962F6),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      '앞서 건너뛰었던 생각을\n다시 살펴볼게요!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // 새로운 불안 생각 추가
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (_, __, ___) => Week4AnxietyScreen(
                                              beforeSud: beforeSud,
                                              existingAlternativeThoughts:
                                                  existingAlternativeThoughts,
                                            ),
                                        transitionDuration: Duration.zero,
                                        reverseTransitionDuration:
                                            Duration.zero,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF2962F6),
                                    side: const BorderSide(
                                      color: Color(0xFF2962F6),
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    '불안을 만드는 또 다른 생각을\n하나 더 추가해볼게요.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
