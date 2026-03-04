class SupportCategory {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final bool needsReservation;
  final String? reservationLabel;
  final String? emptyMessage;
  final String placeholderObject;
  final String placeholderDescription;

  SupportCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.needsReservation,
    this.reservationLabel,
    this.emptyMessage,
    required this.placeholderObject,
    required this.placeholderDescription,
  });

  factory SupportCategory.fromJson(Map<String, dynamic> json) {
    return SupportCategory(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      needsReservation: json['needs_reservation'] ?? false,
      reservationLabel: json['reservation_label'],
      emptyMessage: json['empty_message'],
      placeholderObject: json['placeholder_object'] ?? '',
      placeholderDescription: json['placeholder_description'] ?? '',
    );
  }
}