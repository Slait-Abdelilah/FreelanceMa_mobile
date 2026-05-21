import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  final Dio _dio = apiClient.dio;

  Future<List<NotificationModel>> getNotifications() async {
    final res = await _dio.get(ApiConstants.notifications);
    final list = res.data as List;
    return list.map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get(ApiConstants.notificationsUnread);
    return (res.data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markAsRead(int id) async {
    await _dio.put('${ApiConstants.notifications}/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.put(ApiConstants.notificationsReadAll);
  }

  Future<void> delete(int id) async {
    await _dio.delete('${ApiConstants.notifications}/$id');
  }
}
