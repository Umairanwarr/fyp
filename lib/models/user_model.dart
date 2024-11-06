class UserModel {
  final String name;
  final String email;
  final String phone;
  final String userType;
  final String busNumber;
  final String busColor;
  final String universityName;
  final String profileImageUrl;
  final String? licenseImageUrl;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.busNumber,
    required this.busColor,
    required this.universityName,
    required this.profileImageUrl,
    this.licenseImageUrl,
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
      licenseImageUrl: json['licenseImageUrl'],
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
      'licenseImageUrl': licenseImageUrl,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? userType,
    String? busNumber,
    String? busColor,
    String? universityName,
    String? profileImageUrl,
    String? licenseImageUrl,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      busNumber: busNumber ?? this.busNumber,
      busColor: busColor ?? this.busColor,
      universityName: universityName ?? this.universityName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      userType: data['userType'],
      busNumber: data['busNumber'],
      busColor: data['busColor'],
      universityName: data['universityName'],
      profileImageUrl: data['profileImageUrl'],
      licenseImageUrl: data['licenseImageUrl'],
    );
  }
}
