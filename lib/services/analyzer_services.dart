// lib/services/analyzer_service.dart

import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../models/match_analysis.dart';

class AnalyzerService {
  static Future<MatchAnalysis> analyze({
    required String league,
    required String patch,
    required String side,
    required Map<String, String> myComp,
    required Map<String, String> enemyComp,
  }) async {
    int count = 0;
    int win = 0;
    int totalKills = 0;
    int totalDuration = 0 ;

    try {
      final rawData = await rootBundle.loadString('assets/lol_data.csv');
      List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
      final header = listData[0].map((e) => e.toString().toLowerCase().trim()).toList();

      final gameIdIdx = header.indexOf('gameid');
      final resultIdx = header.indexOf('result');
      final killsIdx = header.indexOf('kills');
      final gameLengthIdx = header.indexOf('gamelength') ;
      final positionIdx = header.indexOf('position');
      final sideIdx = header.indexOf('side');
      final championIdx = header.indexOf('champion');
      final leagueIdx = header.indexOf('league');
      final patchIdx = header.indexOf('patch');

      Map<String, Map<String, Map<String, String>>> matchComps = {};
      Map<String, Map<String, int>> matchResults = {};
      Map<String, Map<String, int>> matchKills = {};
      Map<String , int> matchDurations = {} ;

      for (int i = 1; i < listData.length; i++) {
        var row = listData[i];
        if (row.length <= championIdx) continue;

        String rowLeague = row[leagueIdx].toString().toUpperCase();
        if (league == 'ALL') {
          if (!['LCK', 'LPL', 'LEC', 'LCS'].contains(rowLeague)) continue;
        } else if (rowLeague != league) continue;

        String rowPatch = row[patchIdx].toString();
        if (!rowPatch.startsWith('16.')) continue;
        if (patch != 'ALL(16시즌)' && !rowPatch.startsWith(patch)) continue;

        String gameId = row[gameIdIdx].toString();
        String rowSide = row[sideIdx].toString();

        if (row[positionIdx].toString().toLowerCase() == 'team') {
          matchResults.putIfAbsent(gameId, () => {'Blue': 0, 'Red': 0});
          matchResults[gameId]![rowSide] = (double.tryParse(row[resultIdx].toString()) ?? 0).toInt();
          
          matchKills.putIfAbsent(gameId, () => {'Blue': 0, 'Red': 0});
          matchKills[gameId]![rowSide] = (double.tryParse(row[killsIdx].toString()) ?? 0).toInt();

          matchDurations.putIfAbsent(gameId, () => (double.tryParse(row[gameLengthIdx].toString()) ?? 0).toInt()) ;
          continue;
        }

        matchComps.putIfAbsent(gameId, () => {'Blue': {}, 'Red': {}});
        matchComps[gameId]![rowSide]![row[positionIdx].toString().toLowerCase()] = row[championIdx].toString().trim();
      }

      bool isMatch(Map<String, String> target, Map<String, String> actual) {
        for (var entry in target.entries) {
          if (actual[entry.key] != entry.value) return false;
        }
        return true;
      }
      

      matchComps.forEach((gameId, sidesData) {
        var blueTeam = sidesData['Blue'] ?? {};
        var redTeam = sidesData['Red'] ?? {};
        bool isFound = false;
        bool isWin = false;

        if (side == 'ALL') {
          if (isMatch(myComp, blueTeam) && isMatch(enemyComp, redTeam)) {
            isFound = true; if (matchResults[gameId]!['Blue'] == 1) isWin = true;
          } else if (isMatch(myComp, redTeam) && isMatch(enemyComp, blueTeam)) {
            isFound = true; if (matchResults[gameId]!['Red'] == 1) isWin = true;
          }
        } else {
          String enemySide = (side == 'Blue') ? 'Red' : 'Blue';
          if (isMatch(myComp, sidesData[side] ?? {}) && isMatch(enemyComp, sidesData[enemySide] ?? {})) {
            isFound = true; if (matchResults[gameId]![side] == 1) isWin = true;
          }
        }

        if (isFound) {
          count++;
          if (isWin) win++;
          totalKills += (matchKills[gameId]?['Blue'] ?? 0) + (matchKills[gameId]?['Red'] ?? 0);
          totalDuration += matchDurations[gameId] ?? 0;
        }
      });
    } catch (e) {
      print("Error analyzing data: $e");
    }

    return MatchAnalysis(totalGames: count, wins: win, totalKills: totalKills, totalDuration: totalDuration);
  }
}