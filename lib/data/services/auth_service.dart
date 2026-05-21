import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final Dio _dio = apiClient.dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> registerFreelancer(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.register, data: {...data, 'role': 'FREELANCER'});
  }

  Future<void> registerClient(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.register, data: {...data, 'role': 'CLIENT'});
  }

  Future<void> verifyAccount(String email, String code) async {
    await _dio.post(ApiConstants.verifyAccount, data: {'email': email, 'code': code});
  }

  Future<void> resendCode(String email) async {
    await _dio.post(ApiConstants.resendCode, data: {'email': email});
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
  }

  Future<void> verifyResetCode(String email, String code) async {
    await _dio.post(ApiConstants.verifyResetCode, data: {'email': email, 'code': code});
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post(ApiConstants.resetPassword, data: {'token': token, 'newPassword': newPassword});
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.put(ApiConstants.changePassword, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(ApiConstants.logout, data: {'refreshToken': refreshToken});
    } catch (_) {}
  }

  Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    // Le back-end retourne 'token', pas 'accessToken'
    final token = data['token'] ?? data['accessToken'] ?? '';
    await prefs.setString('token', token);
    await prefs.setString('refreshToken', data['refreshToken'] ?? '');
    await prefs.setString('userId', data['userId']?.toString() ?? '');
    await prefs.setString('userEmail', data['email'] ?? '');
    await prefs.setString('userRole', data['role'] ?? '');
    // Récupérer firstName/lastName depuis /api/settings après login
    if (token.isNotEmpty) {
      try {
        final res = await Dio().get(
          '${ApiConstants.baseUrl}${ApiConstants.settings}',
          options: Options(headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}),
        );
        final s = res.data as Map<String, dynamic>;
        await prefs.setString('userFirstName', s['firstName'] ?? '');
        await prefs.setString('userLastName', s['lastName'] ?? '');
        if (s['id'] != null) {
          await prefs.setString('userId', s['id'].toString());
        }
      } catch (_) {}
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('userRole');
    await prefs.remove('userFirstName');
    await prefs.remove('userLastName');
  }

  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return null;
    final email = prefs.getString('userEmail') ?? '';
    if (email.isEmpty) return null;
    return UserModel(
      id: prefs.getString('userId') ?? '',
      email: email,
      role: prefs.getString('userRole') ?? '',
      firstName: prefs.getString('userFirstName'),
      lastName: prefs.getString('userLastName'),
    );
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }
}
