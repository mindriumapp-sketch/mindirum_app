import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:intl/intl.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

import 'package:gad_app_team/navigation/navigation.dart';
// import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/mongo_provider.dart';

import 'package:gad_app_team/widgets/card_container.dart';
import 'package:gad_app_team/widgets/task_tile.dart';

import 'treatment_screen.dart';
import 'mindrium_screen.dart';
import 'report_screen.dart';
import 'myinfo_screen.dart';

/// 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  int daysSinceJoin = 0;
  final String date = DateFormat('yyyy년 MM월 dd일').format(DateTime.now());
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid') ?? 'local_user';
      debugPrint('[home] uid: $uid');

      if (!mounted) return;
      await context.read<MongoProvider>().init(uid);
    });
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: _buildBody(),
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _homePage();
      case 1:
        return const TreatmentScreen();
      case 2:
        return const MindriumScreen();
      case 3:
        return const ReportScreen();
      case 4:
        return const MyInfoScreen();
      default:
        return _homePage();
    }
  }

  Widget _homePage() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal:AppSizes.padding),
        children: [
          _buildHeader(),
          const SizedBox(height: AppSizes.space),
          // _buildReportSummary(),
          Text('summary'),
          const SizedBox(height: AppSizes.space),
          _buildTodayTasks(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final mongo = context.watch<MongoProvider>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${(mongo.userName.isNotEmpty ? mongo.userName : '사용자')}님, \n좋은 하루 되세요!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),    
              Text(
                '${mongo.daysSinceJoin}일째 되는 날',
                style: const TextStyle(fontSize: AppSizes.fontSize, color: AppColors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Navigator.pushNamed(context, '/contents'),
        ),
      ],
    );
  }

  Widget _buildTodayTasks() {
    final tasks = ['일일 과제1', '일일 과제2', '일일 과제3', '일일 과제4', '일일 과제5'];

    return CardContainer(
      title: '오늘의 할일',
      child: Column(
        children: List.generate(tasks.length, (index) => TaskTile(title: tasks[index], route: '/pretest',)),
      ),
    );
  }

  

  // Widget _buildReportSummary() {
  //   return FutureBuilder<Map<String, List<_SudEntry>>>(
  //     future: _fetchSudEntries(),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const CardContainer(
  //           title: '주간 불안감 변화',
  //           child: Center(child: CircularProgressIndicator()),
  //         );
  //       }

  //       if (snapshot.hasError ||
  //           !snapshot.hasData ||
  //           (snapshot.data!['before']!.isEmpty && snapshot.data!['after']!.isEmpty)) {
  //         return const CardContainer(
  //           title: '주간 불안감 변화',
  //           child: Center(child: Text('데이터가 없습니다')),
  //         );
  //       }

  //       final beforeEntries = snapshot.data!['before']!;
  //       final afterEntries  = snapshot.data!['after']!;

  //       final combinedEntries = [...beforeEntries, ...afterEntries];
  //       combinedEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  //       final indexOfTs = {
  //         for (var i = 0; i < combinedEntries.length; i++)
  //           combinedEntries[i].createdAt : i
  //       };

  //       final beforeSpots = beforeEntries
  //           .map((e) => FlSpot(indexOfTs[e.createdAt]!.toDouble(), e.sud.toDouble()))
  //           .toList();

  //       final afterSpots = afterEntries
  //           .map((e) => FlSpot(indexOfTs[e.createdAt]!.toDouble(), e.sud.toDouble()))
  //           .toList();

  //       return CardContainer(
  //         title: '최근 불안감 변화',
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             SizedBox(
  //               height: 120,
  //               child: LineChart(
  //                 LineChartData(
  //                   minY: -1,
  //                   maxY: 11,
  //                   gridData: FlGridData(
  //                     show: true,
  //                     drawVerticalLine: false,
  //                     horizontalInterval: 2,
  //                     getDrawingHorizontalLine: (value) => FlLine(
  //                       color: AppColors.grey300,
  //                       strokeWidth: 1,
  //                     ),
  //                   ),
  //                   titlesData: FlTitlesData(
  //                     leftTitles: AxisTitles(
  //                       sideTitles: SideTitles(
  //                         showTitles: true,
  //                         interval: 2,
  //                         getTitlesWidget: (value, meta) {
  //                           // Hide 0 and any odd numbers
  //                           if (value % 2 != 0) return const SizedBox.shrink();
  //                           return Text(
  //                             value.toInt().toString(),
  //                             style: const TextStyle(fontSize: 8),
  //                             textAlign: TextAlign.center,
  //                           );
  //                         },
  //                       ),
  //                     ),
  //                     rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //                     topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
  //                     bottomTitles: AxisTitles(
  //                       sideTitles: SideTitles(
  //                         showTitles: true,
  //                         interval: 1,
  //                         getTitlesWidget: (value, meta) {
  //                           final idx = value.toInt();
  //                           if (idx < 0 || idx >= combinedEntries.length) {
  //                             return const SizedBox.shrink();
  //                           }
  //                           return Text(
  //                             DateFormat('MM/dd\nHH:mm').format(combinedEntries[idx].createdAt),
  //                             style: const TextStyle(fontSize: 8),
  //                           );
  //                         },
  //                       ),
  //                     ),
  //                   ),
  //                   borderData: FlBorderData(show: false),
  //                   lineBarsData: [
  //                     LineChartBarData(
  //                       spots: beforeSpots,
  //                       isCurved: true,
  //                       color: Colors.indigo,
  //                       barWidth: 2,
  //                       dotData: FlDotData(show: false),
  //                       belowBarData: BarAreaData(show: false),
  //                     ),
  //                     LineChartBarData(
  //                       spots: afterSpots,
  //                       isCurved: true,
  //                       color: Colors.redAccent,
  //                       barWidth: 2,
  //                       dotData: FlDotData(show: false),
  //                       belowBarData: BarAreaData(show: false),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: AppSizes.space),
  //             // Text(
  //             //   '최근 평균 SUD: '
  //             //   '${(combinedEntries.map((e) => e.sud).reduce((a, b) => a + b) / combinedEntries.length).toStringAsFixed(1)}점',
  //             //   style: const TextStyle(color: AppColors.grey),
  //             // ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }  
}
