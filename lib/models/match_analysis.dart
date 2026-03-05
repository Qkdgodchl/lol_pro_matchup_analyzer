class MatchAnalysis {
  final int totalGames;
  final int wins;
  final int totalKills;
  final int totalDuration; // 👈 1. 총 게임 시간(초) 변수 추가

  MatchAnalysis({
    required this.totalGames,
    required this.wins,
    required this.totalKills,
    required this.totalDuration, // 👈 2. 생성자에 추가
  });

  double get winRate => totalGames > 0 ? (wins / totalGames) * 100 : 0;
  double get avgKills => totalGames > 0 ? (totalKills / totalGames) : 0;
  double get avgDuration => totalGames > 0 ? (totalDuration / totalGames) : 0; // 👈 3. 평균 시간 계산기 추가
}