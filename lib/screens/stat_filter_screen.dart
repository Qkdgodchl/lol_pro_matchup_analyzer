// lib/screens/stat_filter_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_1/constatns/champions.dart';
import '../models/match_analysis.dart';
import 'package:flutter_application_1/services/analyzer_services.dart';

class StatFilterScreen extends StatefulWidget {
  const StatFilterScreen({super.key});

  @override
  State<StatFilterScreen> createState() => _StatFilterScreenState();
}

class _StatFilterScreenState extends State<StatFilterScreen> {
  String selectedLeague = 'ALL';
  String selectedSide = 'ALL';
  String selectedPatch = 'ALL(16시즌)';

  final List<String> leagues = ['ALL', 'LCK', 'LPL', 'LEC', 'LCS'];
  final List<String> patches = ['ALL(16시즌)', '16.01', '16.02', '16.03', '16.04', '16.05'];

  String? myTop, myJg, myMid, myAdc, mySup;
  String? enemyTop, enemyJg, enemyMid, enemyAdc, enemySup;

  String getKoName(String? enName) {
    if (enName == null || enName.isEmpty || enName == '+') return '+';
    try {
      return championMap.entries.firstWhere((e) => e.value == enName).key;
    } catch (e) {
      return enName;
    }
  }

  Future<void> _calculateWinRate() async {
    Map<String, String> myComp = {};
    if (myTop != null) myComp['top'] = myTop!;
    if (myJg != null) myComp['jng'] = myJg!;
    if (myMid != null) myComp['mid'] = myMid!;
    if (myAdc != null) myComp['bot'] = myAdc!; 
    if (mySup != null) myComp['sup'] = mySup!;

    Map<String, String> enemyComp = {};
    if (enemyTop != null) enemyComp['top'] = enemyTop!;
    if (enemyJg != null) enemyComp['jng'] = enemyJg!;
    if (enemyMid != null) enemyComp['mid'] = enemyMid!;
    if (enemyAdc != null) enemyComp['bot'] = enemyAdc!;
    if (enemySup != null) enemyComp['sup'] = enemySup!;

    if (myComp.isEmpty && enemyComp.isEmpty) return;

    final result = await AnalyzerService.analyze(
      league: selectedLeague,
      patch: selectedPatch,
      side: selectedSide,
      myComp: myComp,
      enemyComp: enemyComp,
    );

    if (!mounted) return;
    _showResultDialog(result);
  }

  void _showResultDialog(MatchAnalysis result) {
    String formatDuration(double totalSeconds) {
      if (totalSeconds <= 0) return "데이터 없음";
      int minutes = totalSeconds ~/ 60; // 정수 몫 (분)
      int seconds = (totalSeconds % 60).toInt(); // 나머지 (초)
      return "$minutes분 $seconds초";
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚔️ 매치업 분석 완료"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📊 총 경기: ${result.totalGames}전"),
            Text("🏆 승률: ${result.winRate.toStringAsFixed(1)}% (${result.wins}승)"),
            const Divider(),
            Text("🔥 평균 킬 수: ${result.avgKills.toStringAsFixed(1)} 킬", 
                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            Text("⏳ 평균 게임 시간: ${formatDuration(result.avgDuration)}", 
                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 8),
            Text("🩸 전체 누적 킬: ${result.totalKills} 킬", style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LoL 4대 메이저 리그 분석기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: selectedLeague, 
                  items: leagues.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(), 
                  onChanged: (v) => setState(() => selectedLeague = v!)
                ),
                DropdownButton<String>(
                  value: selectedPatch, 
                  items: patches.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), 
                  onChanged: (v) => setState(() => selectedPatch = v!)
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ALL', label: Text('ALL')), 
                    ButtonSegment(value: 'Blue', label: Text('B')), 
                    ButtonSegment(value: 'Red', label: Text('R'))
                  ],
                  selected: {selectedSide},
                  onSelectionChanged: (set) => setState(() => selectedSide = set.first),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTeamCard("우리 팀", true),
            const SizedBox(height: 16),
            _buildTeamCard("상대 팀", false),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(onPressed: _calculateWinRate, child: const Text("통계 검색")),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(String title, bool isMyTeam) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSlot("TOP", isMyTeam ? myTop : enemyTop, (s) => setState(() => isMyTeam ? myTop = s : enemyTop = s)),
                _buildSlot("JNG", isMyTeam ? myJg : enemyJg, (s) => setState(() => isMyTeam ? myJg = s : enemyJg = s)),
                _buildSlot("MID", isMyTeam ? myMid : enemyMid, (s) => setState(() => isMyTeam ? myMid = s : enemyMid = s)),
                _buildSlot("ADC", isMyTeam ? myAdc : enemyAdc, (s) => setState(() => isMyTeam ? myAdc = s : enemyAdc = s)),
                _buildSlot("SUP", isMyTeam ? mySup : enemySup, (s) => setState(() => isMyTeam ? mySup = s : enemySup = s)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(String label, String? enName, Function(String?) onSet) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _openPicker(onSet),
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
              Text(getKoName(enName), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  void _openPicker(Function(String?) onSet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            ListTile(title: const Text("선택 해제"), onTap: () { onSet(null); Navigator.pop(context); }),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 2),
                itemCount: koChampionNames.length,
                itemBuilder: (context, i) {
                  final ko = koChampionNames[i];
                  return InkWell(
                    onTap: () { onSet(championMap[ko]); Navigator.pop(context); },
                    child: Card(child: Center(child: Text(ko, style: const TextStyle(fontSize: 12)))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}