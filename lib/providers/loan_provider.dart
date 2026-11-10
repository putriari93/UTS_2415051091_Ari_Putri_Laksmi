import 'package:flutter/foundation.dart';

import '../models/loan.dart';
import '../repositories/loan_repository.dart';
import '../services/app_exception.dart';

class LoanProvider extends ChangeNotifier {
  LoanProvider({required LoanRepository repository}) : _repository = repository;

  final LoanRepository _repository;

  List<Loan> _loans = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<Loan> get loans => _loans;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  List<Loan> get activeLoans =>
      _loans.where((loan) => loan.status == LoanStatus.borrowed).toList();

  List<Loan> get returnedLoans =>
      _loans.where((loan) => loan.status == LoanStatus.returned).toList();

  List<Loan> get overdueLoans =>
      _loans.where((loan) => loan.isOverdue).toList();

  List<Loan> get dueSoonLoans =>
      _loans.where((loan) => loan.isDueSoon || loan.isOverdue).toList();

  int get activeCount => activeLoans.length;
  int get returnedCount => returnedLoans.length;
  int get overdueCount => overdueLoans.length;

  Loan? activeLoanFor(String bookKey) {
    for (final loan in _loans) {
      if (loan.bookKey == bookKey && loan.status == LoanStatus.borrowed) {
        return loan;
      }
    }
    return null;
  }

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _loans = await _repository.fetchAll();
    } on AppException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Data peminjaman belum bisa dimuat. Periksa koneksi lalu coba lagi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Loan> create(Loan loan) async {
    _isSaving = true;
    notifyListeners();
    try {
      final saved = await _repository.create(loan);
      _loans = [saved, ..._loans];
      return saved;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<Loan> update(Loan loan) async {
    _isSaving = true;
    notifyListeners();
    try {
      final saved = await _repository.update(loan);
      _loans = [
        for (final item in _loans) item.id == saved.id ? saved : item,
      ];
      return saved;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> markReturned(Loan loan) {
    return update(
      loan.copyWith(
        status: LoanStatus.returned,
        returnedAt: DateTime.now(),
      ),
    );
  }

  Future<void> delete(Loan loan) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.delete(loan.id);
      _loans = _loans.where((item) => item.id != loan.id).toList();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
