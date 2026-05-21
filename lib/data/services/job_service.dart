import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/application_model.dart';
import '../models/favorite_model.dart';
import '../models/offer_model.dart';
import 'api_client.dart';

class JobService {
  final Dio _dio = apiClient.dio;

  // ── Offers ──────────────────────────────────────────────────────────────

  Future<List<OfferModel>> getOffers({Map<String, dynamic>? params}) async {
    final res = await _dio.get(ApiConstants.offers, queryParameters: params);
    final data = res.data;
    final content = data is Map ? (data['content'] ?? data) : data;
    if (content is List) return content.map((e) => OfferModel.fromJson(e)).toList();
    return [];
  }

  Future<List<OfferModel>> getMyOffers() async {
    final res = await _dio.get(ApiConstants.myOffers);
    final list = res.data as List;
    return list.map((e) => OfferModel.fromJson(e)).toList();
  }

  Future<OfferModel> getOffer(int id) async {
    final res = await _dio.get('${ApiConstants.offers}/$id');
    return OfferModel.fromJson(res.data);
  }

  Future<void> createOffer(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.offers, data: data);
  }

  Future<void> updateOffer(int id, Map<String, dynamic> data) async {
    await _dio.put('${ApiConstants.offers}/$id', data: data);
  }

  Future<void> closeOffer(int id) async {
    await _dio.patch('${ApiConstants.offers}/$id/close');
  }

  Future<void> deleteOffer(int id) async {
    await _dio.delete('${ApiConstants.offers}/$id');
  }

  // ── Applications ────────────────────────────────────────────────────────

  Future<void> applyToOffer(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.applications, data: data);
  }

  Future<List<ApplicationModel>> getMyApplications() async {
    final res = await _dio.get(ApiConstants.myApplications);
    final list = res.data as List;
    return list.map((e) => ApplicationModel.fromJson(e)).toList();
  }

  Future<List<ApplicationModel>> getOfferApplications(int offerId) async {
    final res = await _dio.get('${ApiConstants.offerApplications}/$offerId');
    final list = res.data as List;
    return list.map((e) => ApplicationModel.fromJson(e)).toList();
  }

  Future<void> withdrawApplication(int id) async {
    await _dio.delete('${ApiConstants.applications}/$id');
  }

  Future<ApplicationModel> acceptApplication(int id) async {
    final res = await _dio.put('${ApiConstants.applications}/$id/accept');
    return ApplicationModel.fromJson(res.data);
  }

  Future<ApplicationModel> rejectApplication(int id) async {
    final res = await _dio.put('${ApiConstants.applications}/$id/reject');
    return ApplicationModel.fromJson(res.data);
  }

  Future<ApplicationModel> completeApplication(int id) async {
    final res = await _dio.put('${ApiConstants.applications}/$id/complete');
    return ApplicationModel.fromJson(res.data);
  }

  Future<void> validateMission(int id) async {
    await _dio.put('${ApiConstants.applications}/$id/validate');
  }

  // ── Favorites ────────────────────────────────────────────────────────────

  Future<List<FavoriteModel>> getMyFavorites() async {
    final res = await _dio.get(ApiConstants.favorites);
    final list = res.data as List;
    return list.map((e) => FavoriteModel.fromJson(e)).toList();
  }

  Future<bool> toggleFavorite(int offerId) async {
    final res = await _dio.post('${ApiConstants.favorites}/$offerId/toggle');
    return res.data['saved'] == true;
  }

  Future<bool> isFavorite(int offerId) async {
    final res = await _dio.get('${ApiConstants.favorites}/$offerId/check');
    return res.data['saved'] == true;
  }
}
