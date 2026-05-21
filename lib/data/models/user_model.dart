class UserModel {
  final String id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? '',
    firstName: json['firstName'],
    lastName: json['lastName'],
  );

  String get displayName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    final parts = email.split('@')[0].replaceAll(RegExp(r'[._]'), ' ').split(' ');
    return parts.map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  String get initials {
    final parts = displayName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isFreelancer => role == 'FREELANCER';
  bool get isClient => role == 'CLIENT';
}
