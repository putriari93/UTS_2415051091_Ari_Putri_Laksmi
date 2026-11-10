import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/book_category.dart';
import '../models/book_detail.dart';
import '../repositories/book_repository.dart';
import '../services/app_exception.dart';

class BookProvider extends ChangeNotifier {
  BookProvider(this._repository);

  final BookRepository _repository;

  static const int _pageSize = 20;

  List<Book> _books = const [];
  List<Book> _trending = const [];
  BookCategory _category = BookCategory.all.first;
  String _query = '';
  int _page = 1;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isTrendingLoading = false;
  String? _error;
  String? _loadMoreError;
  String? _trendingError;

  final Map<String, Future<BookDetail>> _detailCache = {};

  List<Book> get books => _books;
  List<Book> get trending => _trending;
  BookCategory get category => _category;
  String get query => _query;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isTrendingLoading => _isTrendingLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get loadMoreError => _loadMoreError;
  String? get trendingError => _trendingError;
  bool get isFiltering => _query.trim().isNotEmpty || _category.subject != null;

  Future<void> search({String? query, BookCategory? category}) async {
    _query = query ?? _query;
    if (category != null) _category = category;
    _page = 1;
    _hasMore = false;
    _loadMoreError = null;
    _error = null;
    _isLoading = true;
    _books = const [];
    notifyListeners();

    try {
      final subject = _category.subject;
      final trimmed = _query.trim();
      final result = trimmed.isEmpty && subject == null
          ? await _repository.trending(limit: _pageSize)
          : await _repository.search(
              query: trimmed,
              page: 1,
              limit: _pageSize,
              subject: subject,
            );

      _books = result;
      _hasMore = (trimmed.isNotEmpty || subject != null) && result.length >= _pageSize;
    } on AppException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Daftar buku belum bisa dimuat. Coba lagi sebentar.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _isLoading || !_hasMore) return;

    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final nextPage = _page + 1;
      final result = await _repository.search(
        query: _query.trim(),
        page: nextPage,
        limit: _pageSize,
        subject: _category.subject,
      );

      _page = nextPage;
      _books = [..._books, ...result];
      _hasMore = result.length == _pageSize;
    } on AppException catch (error) {
      _loadMoreError = error.message;
    } catch (_) {
      _loadMoreError = 'Buku berikutnya gagal dimuat.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadTrending({bool force = false}) async {
    if (_isTrendingLoading) return;
    if (_trending.isNotEmpty && !force) return;

    _isTrendingLoading = true;
    _trendingError = null;
    notifyListeners();

    try {
      _trending = await _repository.trending(limit: 12);
    } on AppException catch (error) {
      _trendingError = error.message;
    } catch (_) {
      _trendingError = 'Rekomendasi buku belum bisa dimuat.';
    } finally {
      _isTrendingLoading = false;
      notifyListeners();
    }
  }

  Future<BookDetail> detailFor(Book book) {
    return _detailCache.putIfAbsent(book.key, () => _repository.detail(book.key));
  }

  void forgetDetail(String key) {
    _detailCache.remove(key);
  }

  void clearFilters() {
    _query = '';
    _category = BookCategory.all.first;
  }
}
