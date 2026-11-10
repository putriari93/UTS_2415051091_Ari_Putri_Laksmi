import '../models/loan.dart';
import '../services/loan_service.dart';

class LoanRepository {
  LoanRepository({LoanService? service}) : _service = service ?? LoanService();

  final LoanService _service;

  Future<List<Loan>> fetchAll() => _service.fetchLoans();

  Future<Loan> create(Loan loan) => _service.createLoan(loan);

  Future<Loan> update(Loan loan) => _service.updateLoan(loan);

  Future<void> delete(String id) => _service.deleteLoan(id);
}
