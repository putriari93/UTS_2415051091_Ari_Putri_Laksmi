import 'package:flutter/foundation.dart';

import '../models/book.dart';

class FavoriteProvider extends ChangeNotifier {
  final Map<String, Book> _favorites = {};

  List<Book> get books => _favorites.values.toList(growable: false);

  int get count => _favorites.length;

  bool isFavorite(String key) => _favorites.containsKey(key);

  /// Mengembalikan true bila buku sekarang masuk daftar favorit.
  bool toggle(Book book) {
    final key = book.key;
    if (_favorites.containsKey(key)) {
      _favorites.remove(key);
      notifyListeners();
      return false;
    }

    _favorites[key] = book;
    notifyListeners();
    return true;
  }

  void remove(String key) {
    if (_favorites.remove(key) != null) notifyListeners();
  }

  void clear() {
    if (_favorites.isEmpty) return;
    _favorites.clear();
    notifyListeners();
  }
}
