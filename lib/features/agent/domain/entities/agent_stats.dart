class AgentStats {
  final int scannedToday;
  final int totalScanned;
  final int pendingTasks;
  final int completedTasks;
  final double performanceRate;

  AgentStats({
    required this.scannedToday,
    required this.totalScanned,
    required this.pendingTasks,
    required this.completedTasks,
    required this.performanceRate,
  });
}
