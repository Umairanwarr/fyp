class UserModel {
  final String name;
  final String email;
  final String phone;
  final String userType;
  final String busNumber;
  final String busColor;
  final String universityName;
  final String profileImageUrl;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.busNumber,
    required this.busColor,
    required this.universityName,
    required this.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      userType: json['userType'],
      busNumber: json['busNumber'],
      busColor: json['busColor'],
      universityName: json['universityName'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'busNumber': busNumber,
      'busColor': busColor,
      'universityName': universityName,
      'profileImageUrl': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? userType,
    String? busNumber,
    String? busStop,
    String? universityName,
    String? profileImageUrl,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      busNumber: busNumber ?? this.busNumber,
      busColor: busStop ?? busColor,
      universityName: universityName ?? this.universityName,
    );
  }
}
