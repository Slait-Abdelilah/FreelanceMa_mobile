class FreelancerModel {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? title;
  final String? location;
  final bool available;
  final double? hourlyRate;
  final String? experienceLevel;
  final List<String> skills;
  final double? averageRating;
  final int? completedMissions;

  const FreelancerModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.title,
    this.location,
    this.available = true,
    this.hourlyRate,
    this.experienceLevel,
    this.skills = const [],
    this.averageRating,
    this.completedMissions,
  });

  factory FreelancerModel.fromJson(Map<String, dynamic> json) => FreelancerModel(
    id: (json['userId'] ?? json['id'] as num?)?.toInt() ?? 0,
    email: json['email'] ?? '',
    firstName: json['firstName'],
    lastName: json['lastName'],
    title: json['title'],
    location: json['location'],
    available: json['available'] ?? true,
    hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
    experienceLevel: json['experienceLevel'],
    skills: json['skills'] is List
        ? (json['skills'] as List).map((s) => s.toString()).toList()
        : [],
    averageRating: (json['averageRating'] as num?)?.toDouble(),
    completedMissions: (json['completedMissions'] as num?)?.toInt(),
  );

  String get displayName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return email.split('@')[0];
  }

  String get initials {
    final parts = displayName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get levelLabel {
    const map = {
      'JUNIOR': 'Junior',
      'INTERMEDIATE': 'Intermédiaire',
      'SENIOR': 'Senior',
      'EXPERT': 'Expert',
    };
    return map[experienceLevel ?? ''] ?? (experienceLevel ?? '');
  }
}
