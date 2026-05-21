class PortfolioModel {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? projectUrl;
  final DateTime createdAt;

  const PortfolioModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.projectUrl,
    required this.createdAt,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) => PortfolioModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    imageUrl: json['imageUrl'],
    projectUrl: json['projectUrl'],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );
}
