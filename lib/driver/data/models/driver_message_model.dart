class DriverMessageModel {
  final int id;
  final String subject;
  final String message;
  final String senderName;
  final String senderType;
  final String source;
  final bool isRead;
  final String createdAt;

  DriverMessageModel({
    required this.id,
    required this.subject,
    required this.message,
    required this.senderName,
    required this.senderType,
    required this.source,
    required this.isRead,
    required this.createdAt,
  });

  factory DriverMessageModel.fromJson(Map<String, dynamic> json) {
    return DriverMessageModel(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      senderName: json['sender_name'] ?? '',
      senderType: json['sender_type'] ?? '',
      source: json['source'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }
}
