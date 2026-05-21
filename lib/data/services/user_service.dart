import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/freelancer_model.dart';
import '../models/portfolio_model.dart';
import 'api_client.dart';

class UserService {
  final Dio _dio = apiClient.dio;

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get(ApiConstants.profile);
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.put(ApiConstants.profile, data: data);
  }

  Future<List<FreelancerModel>> getFreelancers({String? search}) async {
    final res = await _dio.get(
      ApiConstants.freelancers,
      queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
    );
    final list = res.data as List;
    return list.map((e) => FreelancerModel.fromJson(e)).toList();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSettings() async {
    final res = await _dio.get(ApiConstants.settings);
    return res.data as Map<String, dynamic>;
  }

  Future<void> updateAccount(Map<String, dynamic> data) async {
    await _dio.put(ApiConstants.settingsAccount, data: data);
  }

  Future<void> updatePrivacy(Map<String, dynamic> data) async {
    await _dio.put(ApiConstants.settingsPrivacy, data: data);
  }

  Future<void> deleteAccount() async {
    await _dio.delete(ApiConstants.deleteAccount);
  }

  // ── Portfolio ─────────────────────────────────────────────────────────────

  Future<List<PortfolioModel>> getPortfolio() async {
    final res = await _dio.get(ApiConstants.portfolio);
    return (res.data as List).map((e) => PortfolioModel.fromJson(e)).toList();
  }

  Future<List<PortfolioModel>> getPublicPortfolio(int freelancerId) async {
    final res = await _dio.get('${ApiConstants.portfolio}/public/$freelancerId');
    return (res.data as List).map((e) => PortfolioModel.fromJson(e)).toList();
  }

  Future<PortfolioModel> addPortfolioProject(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.portfolio, data: data);
    return PortfolioModel.fromJson(res.data);
  }

  Future<PortfolioModel> updatePortfolioProject(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.portfolio}/$id', data: data);
    return PortfolioModel.fromJson(res.data);
  }

  Future<void> deletePortfolioProject(int id) async {
    await _dio.delete('${ApiConstants.portfolio}/$id');
  }

  // ── Wallet ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWallet() async {
    final res = await _dio.get(ApiConstants.wallet);
    final data = res.data as Map<String, dynamic>;
    // WalletSummaryDTO : { wallet: {...}, recentTransactions: [...] }
    // On retourne l'objet wallet directement
    return (data['wallet'] as Map<String, dynamic>?) ?? data;
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final res = await _dio.get(ApiConstants.transactions);
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> deposit(double amount) async {
    await _dio.post(ApiConstants.deposit, data: {'amount': amount});
  }

  Future<void> requestWithdrawal(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.withdraw, data: data);
  }
}
