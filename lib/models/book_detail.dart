class BookDetail {
  const BookDetail({
    required this.key,
    this.description,
    this.firstPublishDate,
    this.subjects = const [],
    this.coverId,
  });

  final String key;
  final String? description;
  final String? firstPublishDate;
  final List<String> subjects;
  final int? coverId;

  factory BookDetail.fromWorkJson(Map<String, dynamic> json) {
    final covers = (json['covers'] as List?)?.whereType<int>().toList() ?? const <int>[];
    return BookDetail(
      key: json['key'] as String? ?? '',
      description: _parseText(json['description']),
      firstPublishDate: json['first_publish_date'] as String?,
      subjects: (json['subjects'] as List?)
              ?.whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .take(12)
              .toList() ??
          const [],
      coverId: covers.isEmpty ? null : covers.first,
    );
  }

  static String? _parseText(dynamic value) {
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    if (value is Map && value['value'] is String) {
      final text = (value['value'] as String).trim();
      return text.isEmpty ? null : text;
    }
    return null;
  }
}
