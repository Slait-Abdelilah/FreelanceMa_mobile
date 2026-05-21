class OfferModel {
  final int id;
  final int? clientId;
  final String title;
  final String description;
  final String category;
  final String budgetType;
  final double budgetMin;
  final double budgetMax;
  final String status;
  final DateTime? deadline;
  final List<String>? requiredSkills;
  final int? applicationsCount;
  final DateTime createdAt;

  const OfferModel({
    required this.id,
    this.clientId,
    required this.title,
    required this.description,
    required this.category,
    required this.budgetType,
    required this.budgetMin,
    required this.budgetMax,
    required this.status,
    this.deadline,
    this.requiredSkills,
    this.applicationsCount,
    required this.createdAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    List<String>? skills;
    final rawSkills = json['requiredSkills'];
    if (rawSkills is List) {
      skills = rawSkills.map((s) => s.toString()).toList();
    } else if (rawSkills is String && rawSkills.isNotEmpty) {
      skills = rawSkills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    return OfferModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      clientId: (json['clientId'] as num?)?.toInt(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'OTHER',
      budgetType: json['budgetType'] ?? 'FIXED',
      budgetMin: ((json['budgetMin'] ?? json['minBudget'] ?? 0) as num).toDouble(),
      budgetMax: ((json['budgetMax'] ?? json['maxBudget'] ?? 0) as num).toDouble(),
      status: json['status'] ?? 'OPEN',
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
      requiredSkills: skills,
      applicationsCount: (json['applicationsCount'] as num?)?.toInt(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get budgetDisplay {
    if (budgetMin == 0 && budgetMax == 0) return 'Budget non spécifié';
    if (budgetType == 'HOURLY') return '${budgetMin.toInt()}–${budgetMax.toInt()} DH/h';
    return '${budgetMin.toInt()}–${budgetMax.toInt()} DH';
  }

  bool get isOpen => status == 'OPEN';

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
