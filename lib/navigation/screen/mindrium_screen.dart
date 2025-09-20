import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/data/mongo_service.dart';

class MindriumScreen extends StatelessWidget {
  const MindriumScreen({super.key});

  Future<int> _fetchCompletedWeek() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      if (uid == null || uid.isEmpty) return 0;
      final doc = await MongoService.instance.fetchUser(userId: uid);
      return (doc?['completedWeek'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: ListView(
        children: [
          // 제목 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mindrium Plus',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '매일 걱정 일기를 작성하고 이완 훈련을 진행하고,\n실제 불안이 발생할 때 적용해요.',
                  style: TextStyle(
                    fontSize: AppSizes.fontSize,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: AppSizes.space),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        debugPrint('[MINDRIUM] push /abc  origin=training');
                        Navigator.pushNamed(
                          context, '/training'
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.padding),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          boxShadow: const [BoxShadow(color: AppColors.black12, blurRadius: 8)],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.32, // 45% of screen width
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '훈련하기',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '매주 교육에서 배운 내용을 바탕으로 훈련해봐요.'
                              )
                            ]
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSizes.space),

                    FutureBuilder<int>(
                      future: _fetchCompletedWeek(),
                      builder: (context, snap) {
                        final week = snap.data ?? 0;
                        final enabled = week >= 3;

                        final bgColor =
                            enabled ? AppColors.white : Colors.grey.shade300;
                        final txtColor =
                            enabled ? Colors.black : Colors.grey.shade500;

                        return InkWell(
                          onTap: enabled
                              ? () {
                                  debugPrint(
                                      '[MINDRIUM] push /diary_yes_or_no  origin=apply');
                                  Navigator.pushNamed(
                                    context,
                                    '/diary_yes_or_no',
                                    arguments: {
                                      'origin': 'apply',
                                      'diary': 'new'
                                    },
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(AppSizes.padding),
                            decoration: BoxDecoration(
                              color: bgColor, // 활성/비활성 배경색
                              borderRadius:
                                  BorderRadius.circular(AppSizes.borderRadius),
                              boxShadow: const [
                                BoxShadow(
                                    color: AppColors.black12, blurRadius: 8)
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: screenHeight * 0.32,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '적용하기',
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: txtColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '훈련한 내용을 바탕으로 실제 불안이 발생할 때 적용해봐요.',
                                    style: TextStyle(color: txtColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
