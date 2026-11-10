class Book {
  const Book({
    required this.key,
    required this.title,
    this.authors = const [],
    this.firstPublishYear,
    this.coverId,
    this.editionCount,
    this.subjects = const [],
    this.language,
    this.ebookAccess,
  });

  final String key;
  final String title;
  final List<String> authors;
  final int? firstPublishYear;
  final int? coverId;
  final int? editionCount;
  final List<String> subjects;
  final String? language;
  final String? ebookAccess;

  String get workId => key.split('/').last;

  String get authorLabel => authors.isEmpty ? 'Penulis tidak diketahui' : authors.join(', ');

  String? coverUrl({String size = 'M'}) {
    if (coverId == null) return null;
    return 'https://covers.openlibrary.org/b/id/$coverId-$size.jpg';
  }

  factory Book.fromSearchJson(Map<String, dynamic> json) {
    return Book(
      key: json['key'] as String? ?? '',
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'Tanpa judul',
      authors: _stringList(json['author_name']),
      firstPublishYear: _asInt(json['first_publish_year']),
      coverId: _asInt(json['cover_i']),
      editionCount: _asInt(json['edition_count']),
      subjects: _stringList(json['subject']).take(12).toList(),
      language: _firstString(json['language']),
      ebookAccess: json['ebook_access'] as String?,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    }
    return const [];
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _firstString(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value is String) return value;
    return null;
  }
}
