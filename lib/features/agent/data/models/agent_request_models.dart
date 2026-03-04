class UpdateAgentProfileRequestModel {
  
  final String firstName;
  final String lastName;
  final String phone;

  UpdateAgentProfileRequestModel({
    required this.firstName,
    required this.lastName,
    required this.phone
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName, 
      'last_name': lastName,
      'phone_number': phone,
    };
  }
}

class UpdatePasswordRequestModel {
  final String oldPassword;
  final String newPassword;

  UpdatePasswordRequestModel({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'old_password': oldPassword,
      'new_password': newPassword,
    };
  }
}
