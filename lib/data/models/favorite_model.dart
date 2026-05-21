class FavoriteModel {
  final int favoriteId;
  final int offerId;
  final String title;
  final String description;
  final String category;
  final double budgetMin;
  final double budgetMax;
  final String budgetType;
  final String? deadline;
  final String? requiredSkills;
  final String status;
  final int applicationsCount;
  final DateTime savedAt;

  const FavoriteModel({
    required this.favoriteId,
    required this.offerId,
    required this.title,
    required this.description,
    required this.category,
    required this.budgetMin,
    required this.budgetMax,
    required this.budgetType,
    this.deadline,
    this.requiredSkills,
    required this.status,
    this.applicationsCount = 0,
    required this.savedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) => FavoriteModel(
    favoriteId: (json['favoriteId'] as num?)?.toInt() ?? 0,
    offerId: (json['offerId'] as num?)?.toInt() ?? 0,
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? '',
    budgetMin: (json['budgetMin'] as num?)?.toDouble() ?? 0,
    budgetMax: (json['budgetMax'] as num?)?.toDouble() ?? 0,
    budgetType: json['budgetType'] ?? 'FIXED',
    deadline: json['deadline']?.toString(),
    requiredSkills: json['requiredSkills'],
    status: json['status'] ?? 'OPEN',
    applicationsCount: (json['applicationsCount'] as num?)?.toInt() ?? 0,
    savedAt: json['savedAt'] != null
        ? DateTime.tryParse(json['savedAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );

  String get budgetDisplay {
    if (budgetType == 'HOURLY') return '${budgetMin.toInt()}-${budgetMax.toInt()} DH/h';
    return '${budgetMin.toInt()}-${budgetMax.toInt()} DH';
  }

  String get categoryLabel {
    const map = {
      'WEB_DEVELOPMENT':    'Développement web',
      'MOBILE_DEVELOPMENT': 'Développement mobile',
      'DESIGN':             'Design',
      'MARKETING':          'Marketing',
      'WRITING':            'Rédaction',
      'VIDEO':              'Vidéo',
      'TRANSLATION':        'Traduction',
      'DATA_SCIENCE':       'Data Science',
      'OTHER':              'Autre',
    };
    return map[category] ?? category;
  }
}
