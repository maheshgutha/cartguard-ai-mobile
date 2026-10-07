class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String token;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.token,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      phone: json['phone'] ?? '',
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'token': token,
      };

  AppUser copyWith({String? token}) => AppUser(
        id: id,
        name: name,
        email: email,
        role: role,
        phone: phone,
        token: token ?? this.token,
      );
}
