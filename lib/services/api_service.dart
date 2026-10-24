import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Semua request ke BTNG Sayur API 2026.
/// Dokumentasi: https://api-mobile.dnccudinus.org
class ApiService {
  static const String baseUrl = 'https://api-mobile.dnccudinus.org/api';
  static const Duration _timeout = Duration(seconds: 15);

  /// Ambil isi "data" dari respons { "success": true, "data": ... }
  static dynamic _data(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('Server membalas kode ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  /// GET /api/vegetables?kategori=...&cari=...
  static Future<List<Sayur>> getSayur({String? kategori, String? cari}) async {
    final params = <String, String>{};
    if (kategori != null && kategori.isNotEmpty) params['kategori'] = kategori;
    if (cari != null && cari.trim().isNotEmpty) params['cari'] = cari.trim();

    var uri = Uri.parse('$baseUrl/vegetables');
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

    final data = _data(await http.get(uri).timeout(_timeout));
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Sayur.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /api/vegetables/:id
  static Future<Sayur> getDetail(int id) async {
    final data = _data(
        await http.get(Uri.parse('$baseUrl/vegetables/$id')).timeout(_timeout));
    if (data is Map) return Sayur.fromJson(Map<String, dynamic>.from(data));
    throw Exception('Detail sayur tidak ditemukan');
  }

  /// GET /api/vegetables/categories
  static Future<List<String>> getKategori() async {
    final data = _data(await http
        .get(Uri.parse('$baseUrl/vegetables/categories'))
        .timeout(_timeout));
    if (data is! List) return [];
    return data
        .map((e) => e is Map ? '${e['nama'] ?? e['kategori'] ?? e['name'] ?? ''}' : '$e')
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
