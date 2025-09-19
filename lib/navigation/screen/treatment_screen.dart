import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─── Core ───────────────────────────────────────────────────────────────

// ─── Project ────────────────────────────────────────────────────────────
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/data/mongo_provider.dart';
import 'package:gad_app_team/models/mongo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/widgets/activitiy_card.dart';
import 'package:gad_app_team/widgets/card_container.dart';

// ─── Feature Screens ────────────────────────────────────────────────────
import 'package:gad_app_team/features/1st_treatment/week1_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/abc_input_screen.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_screen.dart';
import 'package:gad_app_team/features/4th_treatment/week4_screen.dart';
import 'package:gad_app_team/features/5th_treatment/week5_screen.dart';
import 'package:gad_app_team/features/6th_treatment/week6_screen.dart';


const _kTotalWeeks = 8; // Mindrium 프로그램 총 주차

/// Mindrium 치료 프로그램 메인 화면
class TreatmentScreen extends StatelessWidget {
  const TreatmentScreen({super.key});

  Future<Map<String, int>> _loadUserProgress(BuildContext context) async {
    final mongoProvider = context.read<MongoProvider>();
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid == null || uid.isEmpty) {
      return {'completed': 0, 'weekByDays': 0};
    }

    final svc = MongoService.instance;
    await svc.open();
    final doc = await svc.fetchUser(userId: uid);
    final Map<String, dynamic>? user =
      doc?['user'] is Map ? Map<String, dynamic>.from(doc?['user'] as Map) : null;

    // completedWeek는 int 또는 문자열일 수 있으므로 안전 변환
    int completed = 0;
    final raw = user?['completedWeek'];
    if (raw is int) {
      completed = raw;
    } else if (raw != null) {
      completed = int.tryParse(raw.toString()) ?? 0;
    }

    final days = mongoProvider.daysSinceJoin;
    final weekByDays = days ~/ 7;

    return {'completed': completed, 'weekByDays': weekByDays};
  }

  /// 진행 상황 카드 위젯
  Widget _buildProgressCard(BuildContext context, Future<Map<String, int>> future) {
    final mongo = context.watch<MongoProvider>();
    if (!mongo.isReady) return const SizedBox();

    final days = mongo.daysSinceJoin;

    return FutureBuilder<Map<String, int>>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        final completed = snap.data!['completed']!;
        final progress = (completed / _kTotalWeeks).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
          child: CardContainer(
            title: '진행 상황',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$days일째',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.indigo,
                  ),
                ),
                Text(
                  '$completed / $_kTotalWeeks 주차 완료',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressFuture = _loadUserProgress(context);
    // 주차별 콘텐츠 정보
    final List<Map<String, String>> weekContents = [
      {'title': '1주차', 'subtitle': 'Progressive Relaxation \n불안에 대한 교육'},
      {'title': '2주차', 'subtitle': 'Progressive Relaxation \nABC 모델'},
      {'title': '3주차', 'subtitle': 'Release-only Relaxation \nSelf Talk'},
      {'title': '4주차', 'subtitle': 'Cue-Controlled Relaxation \n인지 왜곡 찾기'},
      {'title': '5주차', 'subtitle': 'Differential Relaxation \n불안 직면 vs 회피'},
      {'title': '6주차', 'subtitle': 'Differential Relaxation \n불안 직면 vs 회피'},
      {'title': '7주차', 'subtitle': 'Rapid Relaxation \n생활 습관 개선'},
      {'title': '8주차', 'subtitle': 'Rapid Relaxation \n인지 재구성'},
    ];

    // 주차별 연결된 화면 (추후 주차별로 추가 가능)
    final List<Widget> weekScreens = const [
      Week1Screen(), // 1주차
      AbcInputScreen(), // 2주차
      Week3Screen(), // 3주차
      Week4Screen(),
      Week5Screen(),
      Week6Screen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: ListView(
        children: [
          // 제목 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Mindrium 교육 프로그램',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '주차 별 프로그램을 진행해 주세요',
                  style: TextStyle(
                    fontSize: AppSizes.fontSize,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: AppSizes.space),
              ],
            ),
          ),

          // 진행 상황 카드
          _buildProgressCard(context, progressFuture),
          const SizedBox(height: AppSizes.space),

          // 주차별 카드 리스트 (completed_education 기반)
          FutureBuilder<Map<String, int>>(
            future: progressFuture,
            builder: (context, snap) {
              final mongo = context.watch<MongoProvider>();
              if (!mongo.isReady) return const SizedBox();
              if (!snap.hasData) return const SizedBox();
              
              final completed = snap.data!['completed']!;
              final weekByDays = snap.data!['weekByDays']!;

              return Column(
                children: List.generate(weekContents.length, (index) {
                  // final isEnabled = index <= completed && index <= weekByDays; // TODO: 주차 완료에 따라 치료 활성화
                  final isEnabled = true;
                  return Column(
                    children: [
                      ActivityCard(
                        icon: Icons.lightbulb_outline,
                        title: weekContents[index]['title']!,
                        subtitle: weekContents[index]['subtitle']!,
                        enabled: isEnabled,
                        titleFontWeight: FontWeight.bold,
                        onTap: !isEnabled
                            ? null
                            : () {
                                if (index == 1) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AbcInputScreen(),
                                    ),
                                  );
                                } else if (index < weekScreens.length) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => weekScreens[index],
                                    ),
                                  );
                                }
                              },
                      ),
                      const SizedBox(height: AppSizes.space),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
