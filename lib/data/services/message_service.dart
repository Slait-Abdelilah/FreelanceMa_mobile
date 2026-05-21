import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../models/chat_message_model.dart';
import 'api_client.dart';

class MessageService {
  final Dio _dio = apiClient.dio;

  Future<List<ChatMessageModel>> getHistory(String conversationId) async {
    final res = await _dio.get('${ApiConstants.messageHistory}/$conversationId');
    final list = res.data as List;
    return list.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get(ApiConstants.messageUnreadCount);
    return (res.data['count'] as num?)?.toInt() ?? 0;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
}
