import '../models/book.dart';
import '../models/book_detail.dart';
import '../services/open_library_service.dart';

class BookRepository {
  BookRepository({OpenLibraryService? service})
      : _service = service ?? OpenLibraryService();

  final OpenLibraryService _service;

  Future<List<Book>> search({
    required String query,
    int page = 1,
    int limit = 20,
    String? subject,
  }) {
    return _service.searchBooks(
      query: query,
      page: page,
      limit: limit,
      subject: subject,
    );
  }

  Future<List<Book>> trending({int limit = 12}) {
    return _service.fetchTrending(limit: limit);
  }

  Future<BookDetail> detail(String key) {
    return _service.fetchBookDetail(key);
  }
}
