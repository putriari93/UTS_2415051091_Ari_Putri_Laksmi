class BookCategory {
  const BookCategory({required this.label, this.subject});

  final String label;
  final String? subject;

  static const List<BookCategory> all = [
    BookCategory(label: 'Semua'),
    BookCategory(label: 'Fiksi', subject: 'fiction'),
    BookCategory(label: 'Sains', subject: 'science'),
    BookCategory(label: 'Sejarah', subject: 'history'),
    BookCategory(label: 'Anak', subject: 'juvenile_fiction'),
    BookCategory(label: 'Teknologi', subject: 'technology'),
    BookCategory(label: 'Bisnis', subject: 'business'),
  ];
}
