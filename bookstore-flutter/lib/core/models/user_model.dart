class UserModel {
  final int idUser;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phoneNumber;
  final String? gender;
  final String? dateOfBirth;
  final String? deliveryAddress;
  final String? avatar;

  UserModel({
    required this.idUser,
    this.firstName,
    this.lastName,
    required this.email,
    this.phoneNumber,
    this.gender,
    this.dateOfBirth,
    this.deliveryAddress,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: json['idUser'] ?? 0,
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth'],
      deliveryAddress: json['deliveryAddress'],
      avatar: json['avatar'],
    );
  }

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    return '$f $l'.trim();
  }
}
