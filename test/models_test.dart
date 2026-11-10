import 'package:flutter_test/flutter_test.dart';

import 'package:uts_mobile_development/models/book.dart';
import 'package:uts_mobile_development/models/loan.dart';

void main() {
  group('Book model', () {
    test('membaca data pencarian Open Library', () {
      final book = Book.fromSearchJson({
        'key': '/works/OL17930368W',
        'title': '  Atomic Habits  ',
        'author_name': ['James Clear'],
        'first_publish_year': 2016,
        'cover_i': 12539702,
        'edition_count': 42,
        'subject': ['Habit', 'Self-help'],
        'language': ['eng', 'ind'],
        'ebook_access': 'printdisabled',
      });

      expect(book.title, 'Atomic Habits');
      expect(book.workId, 'OL17930368W');
      expect(book.authorLabel, 'James Clear');
      expect(book.coverUrl(), contains('12539702-M.jpg'));
      expect(book.subjects, contains('Habit'));
      expect(book.language, 'eng');
    });

    test('memakai nilai aman ketika data tidak lengkap', () {
      final book = Book.fromSearchJson({'key': '/works/OL1W'});

      expect(book.title, 'Tanpa judul');
      expect(book.authorLabel, 'Penulis tidak diketahui');
      expect(book.coverUrl(), isNull);
    });
  });

  group('Loan model', () {
    test('mengubah baris database menjadi objek peminjaman', () {
      final loan = Loan.fromJson({
        'id': 'a2f0f2e0-0000-4000-8000-000000000000',
        'book_key': '/works/OL17930368W',
        'title': 'Atomic Habits',
        'author': 'James Clear',
        'cover_id': 12539702,
        'borrower_name': 'Ari Putri Laksmi',
        'borrower_email': 'putri.ari@student.undiksha.ac.id',
        'borrowed_at': '2026-11-01',
        'due_date': '2026-11-15',
        'status': 'borrowed',
        'notes': 'Untuk tugas kuliah.',
      });

      expect(loan.status, LoanStatus.borrowed);
      expect(loan.isReturned, isFalse);
      expect(loan.dueDate, DateTime(2026, 11, 15));
      expect(loan.coverUrl, contains('12539702-M.jpg'));
    });

    test('menyusun payload database dengan format tanggal yang benar', () {
      final loan = Loan(
        id: '1',
        bookKey: '/works/OL1W',
        title: 'Buku Uji',
        borrowerName: 'Penguji',
        dueDate: DateTime(2026, 12, 5),
        status: LoanStatus.returned,
        returnedAt: DateTime(2026, 12, 1),
      );

      final payload = loan.toDatabaseJson();

      expect(payload['due_date'], '2026-12-05');
      expect(payload['returned_at'], '2026-12-01');
      expect(payload['status'], 'returned');
    });

    test('menandai peminjaman yang lewat tenggat', () {
      final loan = Loan(
        id: '1',
        bookKey: '/works/OL1W',
        title: 'Buku Uji',
        borrowerName: 'Penguji',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        status: LoanStatus.borrowed,
      );

      expect(loan.isOverdue, isTrue);
      expect(loan.isDueSoon, isFalse);
    });

    test('peminjaman yang dikembalikan tidak dianggap terlambat', () {
      final loan = Loan(
        id: '1',
        bookKey: '/works/OL1W',
        title: 'Buku Uji',
        borrowerName: 'Penguji',
        dueDate: DateTime.now().subtract(const Duration(days: 10)),
        status: LoanStatus.returned,
        returnedAt: DateTime.now(),
      );

      expect(loan.isOverdue, isFalse);
    });
  });
}
