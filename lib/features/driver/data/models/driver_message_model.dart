class DriverMessageModel {
  final int id;
  final String subject;
  final String message;
  final String senderName;
  final String senderType;
  final String source;
  final bool isRead;
  final DateTime createdAt;

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
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true || json['is_read'].toString() == '1',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}
