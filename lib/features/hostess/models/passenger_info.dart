class PassengerInfo {
  final String lastName;
  final String firstName;
  final String phone;
  final String procheNumber;
  final String? email;

  PassengerInfo({
    required this.lastName,
    required this.firstName,
    required this.phone,
    required this.procheNumber,
    this.email,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() => {
    'lastName': lastName,
    'firstName': firstName,
    'phone': phone,
    'procheNumber': procheNumber,
    'email': email,
  };

  factory PassengerInfo.fromJson(Map<String, dynamic> json) => PassengerInfo(
    lastName: json['lastName'] as String,
    firstName: json['firstName'] as String,
    phone: json['phone'] as String,
    procheNumber: json['procheNumber'] as String,
    email: json['email'] as String?,
  );
}
