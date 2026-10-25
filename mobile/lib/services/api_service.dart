import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/prediction_model.dart';

class ApiService {
  static String getDefaultBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  static String baseUrl = getDefaultBaseUrl();

  static Future<PredictionResponse> predict(StudentPredictionRequest request) async {
    final endpoint = Uri.parse('$baseUrl/api/predict');

    try {
      final response = await http
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return PredictionResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        // Coba ambil pesan validasi dari FastAPI (HTTP 422)
        final errorBody = jsonDecode(response.body);
        String detail = 'Terjadi kesalahan dari server.';
        if (errorBody['detail'] is List) {
          final errors = errorBody['detail'] as List;
          detail = errors.map((e) => e['msg'] ?? e.toString()).join('\n');
        } else if (errorBody['detail'] is String) {
          detail = errorBody['detail'];
        }
        throw Exception('Server Error (${response.statusCode}): $detail');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Connection refused')) {
        throw Exception(
          'Tidak dapat terhubung ke Backend API di $baseUrl.\n'
          'Pastikan Docker / server FastAPI sudah berjalan dan IP sudah benar.',
        );
      }
      rethrow;
    }
  }

  static Future<HistoryStats> fetchHistory() async {
    final endpoint = Uri.parse('$baseUrl/api/history');

    try {
      final response = await http
          .get(
            endpoint,
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return HistoryStats.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        throw Exception('Gagal memuat riwayat: ${response.statusCode}');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('Connection refused')) {
        throw Exception(
          'Tidak dapat terhubung ke Backend API di $baseUrl.\n'
          'Pastikan server FastAPI sudah berjalan dan IP sudah benar.',
        );
      }
      rethrow;
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
