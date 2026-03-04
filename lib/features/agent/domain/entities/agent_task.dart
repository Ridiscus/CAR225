class AgentTask {
  final String id;
  final String title;
  final String description;
  final String status; // 'pending', 'in_progress', 'completed', 'canceled'
  final DateTime createdAt;
  final DateTime deadline;
  final String priority; // 'low', 'medium', 'high', 'urgent'

  AgentTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.deadline,
    required this.priority,
  });
}
