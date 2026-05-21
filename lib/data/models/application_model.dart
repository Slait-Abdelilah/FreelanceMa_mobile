class ApplicationModel {
  final int id;
  final int offerId;
  final int? freelancerId;
  final String? freelancerFirstName;
  final String? freelancerLastName;
  final String offerTitle;
  final String? offerCategory;
  final double? offerBudgetMin;
  final double? offerBudgetMax;
  final String status;
  final String? coverLetter;
  final double? proposedBudget;
  final int? proposedDays;
  final DateTime appliedAt;
  final DateTime? completedAt;

  const ApplicationModel({
    required this.id,
    required this.offerId,
    this.freelancerId,
    this.freelancerFirstName,
    this.freelancerLastName,
    required this.offerTitle,
    this.offerCategory,
    this.offerBudgetMin,
    this.offerBudgetMax,
    required this.status,
    this.coverLetter,
    this.proposedBudget,
    this.proposedDays,
    required this.appliedAt,
    this.completedAt,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) => ApplicationModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    offerId: (json['offerId'] as num?)?.toInt() ?? 0,
    freelancerId: (json['freelancerId'] as num?)?.toInt(),
    freelancerFirstName: json['freelancerFirstName'] ?? json['applicant']?['firstName'],
    freelancerLastName: json['freelancerLastName'] ?? json['applicant']?['lastName'],
    offerTitle: json['offerTitle'] ?? json['offer']?['title'] ?? '',
    offerCategory: json['offerCategory'],
    offerBudgetMin: (json['offerBudgetMin'] as num?)?.toDouble(),
    offerBudgetMax: (json['offerBudgetMax'] as num?)?.toDouble(),
    status: json['status'] ?? 'PENDING',
    coverLetter: json['coverLetter'],
    proposedBudget: (json['proposedBudget'] as num?)?.toDouble(),
    proposedDays: (json['proposedDays'] as num?)?.toInt(),
    appliedAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
    completedAt: json['completedAt'] != null
        ? DateTime.tryParse(json['completedAt'].toString())
        : null,
  );

  bool get isAccepted => status == 'ACCEPTED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isWithdrawn => status == 'WITHDRAWN';
  bool get isAwaitingValidation => status == 'AWAITING_VALIDATION';

  String? get freelancerName {
    if (freelancerFirstName == null && freelancerLastName == null) return null;
    return '${freelancerFirstName ?? ''} ${freelancerLastName ?? ''}'.trim();
  }

  String get freelancerInitials {
    final first = freelancerFirstName?.isNotEmpty == true ? freelancerFirstName![0] : '';
    final last = freelancerLastName?.isNotEmpty == true ? freelancerLastName![0] : '';
    final initials = '$first$last'.toUpperCase();
    return initials.isNotEmpty ? initials : 'F';
  }

  String get statusLabel {
    const map = {
      'PENDING': 'En attente',
      'ACCEPTED': 'Acceptée',
      'REJECTED': 'Refusée',
      'COMPLETED': 'Terminée',
      'WITHDRAWN': 'Retirée',
      'AWAITING_VALIDATION': 'En validation',
    };
    return map[status] ?? status;
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
    return map[offerCategory ?? ''] ?? (offerCategory ?? '');
  }
}
