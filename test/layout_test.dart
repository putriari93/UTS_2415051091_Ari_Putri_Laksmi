import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:uts_mobile_development/models/book.dart';
import 'package:uts_mobile_development/models/book_detail.dart';
import 'package:uts_mobile_development/models/loan.dart';
import 'package:uts_mobile_development/providers/book_provider.dart';
import 'package:uts_mobile_development/providers/favorite_provider.dart';
import 'package:uts_mobile_development/providers/loan_provider.dart';
import 'package:uts_mobile_development/providers/theme_provider.dart';
import 'package:uts_mobile_development/repositories/book_repository.dart';
import 'package:uts_mobile_development/repositories/loan_repository.dart';
import 'package:uts_mobile_development/screens/book_detail_screen.dart';
import 'package:uts_mobile_development/screens/create_loan_screen.dart';
import 'package:uts_mobile_development/screens/edit_loan_screen.dart';
import 'package:uts_mobile_development/screens/explore_screen.dart';
import 'package:uts_mobile_development/screens/favorites_screen.dart';
import 'package:uts_mobile_development/screens/home_screen.dart';
import 'package:uts_mobile_development/screens/loans_screen.dart';
import 'package:uts_mobile_development/screens/profile_screen.dart';

class _FakeBookRepository extends BookRepository {
  @override
  Future<List<Book>> search({
    required String query,
    int page = 1,
    int limit = 20,
    String? subject,
  }) async {
    return const [];
  }

  @override
  Future<List<Book>> trending({int limit = 12}) async => const [];

  @override
  Future<BookDetail> detail(String key) async => BookDetail(key: key);
}

class _FakeLoanRepository implements LoanRepository {
  _FakeLoanRepository(this.items);

  final List<Loan> items;

  @override
  Future<List<Loan>> fetchAll() async => items;

  @override
  Future<Loan> create(Loan loan) async => loan;

  @override
  Future<Loan> update(Loan loan) async => loan;

  @override
  Future<void> delete(String id) async {}
}

const _book = Book(
  key: '/works/OL17930368W',
  title: 'Atomic Habits: Perubahan Kecil yang Memberi Hasil Luar Biasa',
  authors: ['James Clear'],
  firstPublishYear: 2018,
  editionCount: 42,
  language: 'ind',
);

const _anotherBook = Book(
  key: '/works/OL27448W',
  title: 'The Lord of the Rings',
  authors: ['J. R. R. Tolkien'],
  firstPublishYear: 1954,
);

const _thirdBook = Book(
  key: '/works/OL27482W',
  title: 'The Hobbit',
  authors: ['J. R. R. Tolkien'],
  firstPublishYear: 1937,
);

final _loans = [
  Loan(
    id: '1',
    bookKey: '/works/OL17930368W',
    title: 'Atomic Habits',
    author: 'James Clear',
    borrowerName: 'Ari Putri Laksmi',
    borrowerEmail: 'putri.ari@student.undiksha.ac.id',
    borrowedAt: DateTime(2026, 10, 20),
    dueDate: DateTime(2026, 11, 3),
    status: LoanStatus.borrowed,
    notes: 'Sudah lewat tenggat dan perlu segera dikembalikan ke rak.',
  ),
  Loan(
    id: '2',
    bookKey: '/works/OL27448W',
    title: 'The Lord of the Rings',
    author: 'J. R. R. Tolkien',
    borrowerName: 'Ari Putri Laksmi',
    dueDate: DateTime(2026, 11, 21),
    status: LoanStatus.borrowed,
  ),
  Loan(
    id: '3',
    bookKey: '/works/OL27482W',
    title: 'The Hobbit',
    author: 'J. R. R. Tolkien',
    borrowerName: 'Ari Putri Laksmi',
    borrowedAt: DateTime(2026, 10, 1),
    dueDate: DateTime(2026, 10, 15),
    returnedAt: DateTime(2026, 10, 14),
    status: LoanStatus.returned,
  ),
];

Widget _app({
  required Widget home,
  required BookProvider books,
  required LoanProvider loans,
  required FavoriteProvider favorites,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: books),
      ChangeNotifierProvider.value(value: loans),
      ChangeNotifierProvider.value(value: favorites),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp(home: home),
  );
}

Future<(BookProvider, LoanProvider, FavoriteProvider)> _providers({
  List<Loan> loans = const [],
  List<Book> favorites = const [],
}) async {
  final bookProvider = BookProvider(_FakeBookRepository());
  final loanProvider = LoanProvider(_FakeLoanRepository(loans));
  await loanProvider.load();
  final favoriteProvider = FavoriteProvider();
  for (final book in favorites) {
    favoriteProvider.toggle(book);
  }
  return (bookProvider, loanProvider, favoriteProvider);
}

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget home,
  required Size size,
  List<Loan> loans = const [],
  List<Book> favorites = const [],
}) async {
  await _setSize(tester, size);
  final (books, loanProvider, favoriteProvider) = await _providers(
    loans: loans,
    favorites: favorites,
  );
  await tester.pumpWidget(
    _app(
      home: home,
      books: books,
      loans: loanProvider,
      favorites: favoriteProvider,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  const compact = Size(320, 700);
  const wide = Size(1280, 900);

  testWidgets('beranda rapi pada layar sempit dan lebar', (tester) async {
    await _pump(tester, home: const HomeScreen(), size: compact, loans: _loans);
    await _pump(tester, home: const HomeScreen(), size: wide, loans: _loans);
  });

  testWidgets('katalog tidak overflow pada layar sempit', (tester) async {
    await _pump(tester, home: const ExploreScreen(), size: compact);
  });

  testWidgets('detail buku dengan tombol pinjam tidak overflow', (tester) async {
    await _pump(tester, home: const BookDetailScreen(book: _book), size: compact);
  });

  testWidgets('detail buku berstatus dipinjam tidak overflow', (tester) async {
    await _pump(
      tester,
      home: const BookDetailScreen(book: _book),
      size: compact,
      loans: _loans,
    );
  });

  testWidgets('form pinjam rapi pada layar sempit', (tester) async {
    await _pump(tester, home: const CreateLoanScreen(book: _book), size: compact);
  });

  testWidgets('daftar peminjaman rapi dengan tiga status', (tester) async {
    await _pump(tester, home: const LoansScreen(), size: compact, loans: _loans);
  });

  testWidgets('form edit peminjaman rapi pada layar sempit', (tester) async {
    await _pump(
      tester,
      home: EditLoanScreen(loan: _loans.first),
      size: compact,
      loans: _loans,
    );
  });

  testWidgets('daftar favorit rapi pada layar sempit', (tester) async {
    await _pump(
      tester,
      home: const FavoritesScreen(),
      size: compact,
      favorites: const [_book, _anotherBook, _thirdBook],
    );
  });

  testWidgets('profil rapi pada layar sempit', (tester) async {
    await _pump(
      tester,
      home: const ProfileScreen(),
      size: compact,
      loans: _loans,
      favorites: const [_book],
    );
  });
}
