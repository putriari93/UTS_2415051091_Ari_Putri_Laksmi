enum LoanStatus {
  borrowed,
  returned;

  static LoanStatus fromDb(String? value) {
    return value == 'returned' ? LoanStatus.returned : LoanStatus.borrowed;
  }

  String get dbValue => name;

  String get label => switch (this) {
        LoanStatus.borrowed => 'Dipinjam',
        LoanStatus.returned => 'Dikembalikan',
      };
}

class Loan {
  const Loan({
    required this.id,
    required this.bookKey,
    required this.title,
    required this.borrowerName,
    required this.dueDate,
    required this.status,
    this.author,
    this.coverId,
    this.borrowerEmail,
    this.borrowedAt,
    this.returnedAt,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String bookKey;
  final String title;
  final String? author;
  final int? coverId;
  final String borrowerName;
  final String? borrowerEmail;
  final DateTime? borrowedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final LoanStatus status;
  final String? notes;
  final DateTime? createdAt;

  bool get isReturned => status == LoanStatus.returned;

  bool get isOverdue {
    if (isReturned) return false;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return end.isBefore(start);
  }

  bool get isDueSoon {
    if (isReturned) return false;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final days = end.difference(start).inDays;
    return days >= 0 && days <= 3;
  }

  int get daysLeft {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return end.difference(start).inDays;
  }

  String? get coverUrl {
    if (coverId == null) return null;
    return 'https://covers.openlibrary.org/b/id/$coverId-M.jpg';
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String? ?? '',
      bookKey: json['book_key'] as String? ?? '',
      title: json['title'] as String? ?? 'Tanpa judul',
      author: json['author'] as String?,
      coverId: _asInt(json['cover_id']),
      borrowerName: json['borrower_name'] as String? ?? '',
      borrowerEmail: json['borrower_email'] as String?,
      borrowedAt: _asDate(json['borrowed_at']),
      dueDate: _asDate(json['due_date']) ?? DateTime.now(),
      returnedAt: _asDate(json['returned_at']),
      status: LoanStatus.fromDb(json['status'] as String?),
      notes: json['notes'] as String?,
      createdAt: _asDate(json['created_at']),
    );
  }

  Loan copyWith({
    String? borrowerName,
    String? borrowerEmail,
    DateTime? dueDate,
    DateTime? returnedAt,
    LoanStatus? status,
    String? notes,
  }) {
    return Loan(
      id: id,
      bookKey: bookKey,
      title: title,
      author: author,
      coverId: coverId,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowerEmail: borrowerEmail ?? this.borrowerEmail,
      borrowedAt: borrowedAt,
      dueDate: dueDate ?? this.dueDate,
      returnedAt: returnedAt ?? this.returnedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  /// Payload untuk insert/update. Kolom id dan created_at diurus database.
  Map<String, dynamic> toDatabaseJson() {
    return {
      'book_key': bookKey,
      'title': title,
      'author': author,
      'cover_id': coverId,
      'borrower_name': borrowerName,
      'borrower_email': borrowerEmail,
      'borrowed_at': _formatDate(borrowedAt ?? DateTime.now()),
      'due_date': _formatDate(dueDate),
      'returned_at': returnedAt == null ? null : _formatDate(returnedAt!),
      'status': status.dbValue,
      'notes': notes,
    };
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
