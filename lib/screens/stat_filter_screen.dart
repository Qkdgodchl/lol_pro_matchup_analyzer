import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
// '프로젝트이름' 자리에 pubspec.yaml에 적힌 이름을 넣으세요.
import 'package:flutter_application_1/constatns/champions.dart' ;
 // 챔피언 리스트 불러오기
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

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로 씬 챔피언 통계'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: selectedLeague,
                    items: leagues.map((l) => DropdownMenuItem(value: l, child: Text(l, style: TextStyle(color: l == 'ALL' ? Colors.amber : Colors.white)))).toList(),
                    onChanged: (val) => setState(() => selectedLeague = val!),
                  ),
                  DropdownButton<String>(
                    value: selectedPatch,
                    items: patches.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => selectedPatch = val!),
                  ),
                  
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ALL', label: Text('ALL', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: 'Blue', label: Text('Blue', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: 'Red', label: Text('Red', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {selectedSide},
                    onSelectionChanged: (newSelection) => setState(() => selectedSide = newSelection.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (states) {
                          if (states.contains(WidgetState.selected)) {
                            if (selectedSide == 'ALL') return Colors.purple.withValues(alpha: 0.5);
                            return selectedSide == 'Blue' ? Colors.blue.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5);
                          }
                          return Colors.transparent;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildTeamSection('우리 팀 챔피언', true),
              const SizedBox(height: 24),
              _buildTeamSection('상대 팀 챔피언', false),
              const SizedBox(height: 40),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => _calculateWinRate(),
                child: const Text('통계 검색하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCompMatch(Map<String, String> targetComp, Map<String, String> actualComp) {
    for (var entry in targetComp.entries) {
      if (actualComp[entry.key] != entry.value) return false;
    }
    return true;
  }

  Future<void> _calculateWinRate() async {
    print("=================================");
    print("⏳ 데이터 로딩 및 분석 중...");
    
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

    if (myComp.isEmpty && enemyComp.isEmpty) {
      print("❌ 우리 팀 또는 상대 팀 챔피언을 최소 1개 이상 선택해주세요!");
      print("=================================");
      return;
    }

    try {
      final rawData = await rootBundle.loadString('assets/lol_data.csv');
      List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
      
      final header = listData[0].map((e) => e.toString().toLowerCase().trim()).toList();
      
      final gameIdIdx = header.indexOf('gameid');
      final leagueIdx = header.indexOf('league');
      final patchIdx = header.indexOf('patch');
      final championIdx = header.indexOf('champion');
      final resultIdx = header.indexOf('result');
      final positionIdx = header.indexOf('position');
      final sideIdx = header.indexOf('side');

      Map<String, Map<String, Map<String, String>>> matchComps = {};
      Map<String, Map<String, int>> matchResults = {};

      for (int i = 1; i < listData.length; i++) {
        var row = listData[i];
        if (row.length <= championIdx) continue;

        String rowLeague = row[leagueIdx].toString().toUpperCase();
        if (selectedLeague == 'ALL') {
          if (!['LCK', 'LPL', 'LEC', 'LCS'].contains(rowLeague)) continue;
        } else {
          if (rowLeague != selectedLeague) continue;
        }

        String rowPatch = row[patchIdx].toString();
        if (!rowPatch.startsWith('16.')) continue;
        if (selectedPatch != 'ALL(16시즌)' && !rowPatch.startsWith(selectedPatch)) continue;

        String position = row[positionIdx].toString().toLowerCase().trim();
        if (position == 'team') continue;

        String gameId = row[gameIdIdx].toString();
        String side = row[sideIdx].toString();
        String champion = row[championIdx].toString().trim();
        
        // 🚨 핵심 수정 버그 픽스: 소수점(1.0)으로 읽히더라도 무조건 깔끔한 정수(1)로 변환해줍니다!
        int result = (double.tryParse(row[resultIdx].toString()) ?? 0.0).toInt(); 

        if (champion.isEmpty || (side != 'Blue' && side != 'Red')) continue;

        matchComps.putIfAbsent(gameId, () => {'Blue': {}, 'Red': {}});
        matchResults.putIfAbsent(gameId, () => {'Blue': 0, 'Red': 0});

        matchComps[gameId]![side]![position] = champion;
        matchResults[gameId]![side] = result; // 이제 1승이 정상적으로 1로 들어갑니다.
      }

      int matchCount = 0;
      int winCount = 0;

      matchComps.forEach((gameId, sidesData) {
        var blueTeam = sidesData['Blue'] ?? {};
        var redTeam = sidesData['Red'] ?? {};

        bool isMatchFound = false;
        bool isWin = false;

        if (selectedSide == 'ALL') {
          bool myTeamIsBlue = _isCompMatch(myComp, blueTeam) && _isCompMatch(enemyComp, redTeam);
          if (myTeamIsBlue) {
            isMatchFound = true;
            if (matchResults[gameId]!['Blue'] == 1) isWin = true;
          } else {
            bool myTeamIsRed = _isCompMatch(myComp, redTeam) && _isCompMatch(enemyComp, blueTeam);
            if (myTeamIsRed) {
              isMatchFound = true;
              if (matchResults[gameId]!['Red'] == 1) isWin = true;
            }
          }
        } else {
          String mySide = selectedSide;
          String enemySide = (mySide == 'Blue') ? 'Red' : 'Blue';
          
          var myTeamInGame = sidesData[mySide] ?? {};
          var enemyTeamInGame = sidesData[enemySide] ?? {};
          
          if (_isCompMatch(myComp, myTeamInGame) && _isCompMatch(enemyComp, enemyTeamInGame)) {
            isMatchFound = true;
            if (matchResults[gameId]![mySide] == 1) isWin = true;
          }
        }

        if (isMatchFound) {
          matchCount++;
          if (isWin) winCount++;
        }
      });

      print("🔍 검색 리그: ${selectedLeague == 'ALL' ? '4대 리그 통합 (LCK, LPL, LEC, LCS)' : selectedLeague} / 패치: $selectedPatch / 진영: $selectedSide");
      print("🔵 우리 팀: $myComp");
      print("🔴 상대 팀: $enemyComp");
      print("📊 등장 횟수: $matchCount 전");
      
      if (matchCount > 0) {
        double winRate = (winCount / matchCount) * 100;
        print("🏆 승리: $winCount 승");
        print("📈 승률: ${winRate.toStringAsFixed(1)} %");
      } else {
        print("🤷‍♂️ 해당 조건의 매치업이 4대 리그에서 나온 적이 없습니다.");
      }
      print("=================================");

    } catch (e) {
      print("❌ 데이터 분석 중 오류 발생: $e");
      print("=================================");
    }
  }

  Widget _buildTeamSection(String title, bool isMyTeam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildChampSlot('TOP', isMyTeam ? myTop : enemyTop, (champ) => setState(() => isMyTeam ? myTop = champ : enemyTop = champ)),
            _buildChampSlot('JUG', isMyTeam ? myJg : enemyJg, (champ) => setState(() => isMyTeam ? myJg = champ : enemyJg = champ)),
            _buildChampSlot('MID', isMyTeam ? myMid : enemyMid, (champ) => setState(() => isMyTeam ? myMid = champ : enemyMid = champ)),
            _buildChampSlot('ADC', isMyTeam ? myAdc : enemyAdc, (champ) => setState(() => isMyTeam ? myAdc = champ : enemyAdc = champ)),
            _buildChampSlot('SUP', isMyTeam ? mySup : enemySup, (champ) => setState(() => isMyTeam ? mySup = champ : enemySup = champ)),
          ],
        ),
      ],
    );
  }

  Widget _buildChampSlot(String role, String? champName, Function(String) onSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showChampionPicker(role, onSelected),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(role, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    champName ?? '+',
                    style: TextStyle(
                      fontSize: champName != null ? 14 : 24,
                      fontWeight: FontWeight.bold,
                      color: champName != null ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChampionPicker(String role, Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$role 챔피언 선택', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    // 선택 해제(초기화) 버튼 추가
                    TextButton(
                      onPressed: () {
                        onSelected(''); // 빈 값 전달
                        Navigator.pop(context);
                      },
                      child: const Text('비우기', style: TextStyle(color: Colors.redAccent)),
                    )
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, 
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: allChampions.length,
                  itemBuilder: (context, index) {
                    final champ = allChampions[index];
                    return InkWell(
                      onTap: () {
                        onSelected(champ);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(champ, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}