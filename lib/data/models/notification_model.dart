class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final int? offerId;
  final int? applicationId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.offerId,
    this.applicationId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    type: json['type'] ?? '',
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    offerId: (json['offerId'] as num?)?.toInt(),
    applicationId: (json['applicationId'] as num?)?.toInt(),
    isRead: json['isRead'] ?? json['read'] ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );
}
