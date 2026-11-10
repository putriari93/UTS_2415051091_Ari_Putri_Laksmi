import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/book.dart';
import '../models/book_detail.dart';
import 'app_exception.dart';

class OpenLibraryService {
  OpenLibraryService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _base = 'https://openlibrary.org';
  static const String _searchFields =
      'key,title,author_name,first_publish_year,cover_i,edition_count,subject,language,ebook_access';
  static const Duration _timeout = Duration(seconds: 20);

  Future<List<Book>> searchBooks({
    required String query,
    int page = 1,
    int limit = 20,
    String? subject,
  }) async {
    final search = query.trim();
    final subjectQuery = subject == null ? '' : 'subject:$subject';

    final q = [if (search.isNotEmpty) search, if (subjectQuery.isNotEmpty) subjectQuery].join(' ');
    if (q.isEmpty) return const [];

    final uri = Uri.https('openlibrary.org', '/search.json', {
      'q': q,
      'page': '$page',
      'limit': '$limit',
      'fields': _searchFields,
    });

    final json = await _getJson(uri);
    final docs = json['docs'];
    if (docs is! List) return const [];

    return docs
        .whereType<Map<String, dynamic>>()
        .map(Book.fromSearchJson)
        .where((book) => book.key.isNotEmpty)
        .toList();
  }

  Future<List<Book>> fetchTrending({int limit = 12}) async {
    final uri = Uri.https('openlibrary.org', '/trending/daily.json', {
      'limit': '$limit',
    });

    final json = await _getJson(uri);
    final works = json['works'];
    if (works is! List) return const [];

    return works
        .whereType<Map<String, dynamic>>()
        .map(Book.fromSearchJson)
        .where((book) => book.key.isNotEmpty)
        .toList();
  }

  Future<BookDetail> fetchBookDetail(String key) async {
    final path = key.startsWith('/') ? key : '/$key';
    final uri = Uri.parse('$_base$path.json');
    final json = await _getJson(uri);
    return BookDetail.fromWorkJson(json);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw AppException(
          'Open Library menolak permintaan (status ${response.statusCode}). Coba lagi beberapa saat lagi.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const AppException('Format respons Open Library tidak dikenali.');
      }
      return decoded;
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        'Koneksi ke Open Library terlalu lama. Periksa jaringan lalu coba lagi.',
      );
    } on http.ClientException {
      throw const AppException(
        'Tidak dapat menghubungi Open Library. Pastikan perangkat terhubung internet.',
      );
    } on FormatException {
      throw const AppException('Respons Open Library tidak dapat dibaca.');
    } catch (_) {
      throw const AppException(
        'Terjadi kendala saat mengambil data buku. Silakan coba lagi.',
      );
    }
  }
}
