import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/loan.dart';
import '../../providers/loan_provider.dart';
import 'feedback.dart';

Future<bool> deleteLoanWithConfirmation(BuildContext context, Loan loan) async {
  final provider = context.read<LoanProvider>();

  final confirmed = await showConfirmationDialog(
    context,
    title: 'Hapus peminjaman?',
    message:
        'Catatan peminjaman "${loan.title}" akan dihapus permanen dari database. '
        'Buku tetap bisa dipinjam lagi kapan saja.',
    confirmLabel: 'Hapus',
  );

  if (!confirmed || !context.mounted) return false;

  try {
    await provider.delete(loan);
    if (context.mounted) {
      showAppSnackBar(context, 'Peminjaman "${loan.title}" sudah dihapus.');
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      showAppSnackBar(context, error.toString(), isError: true);
    }
    return false;
  }
}

Future<void> markLoanReturned(BuildContext context, Loan loan) async {
  final provider = context.read<LoanProvider>();

  try {
    await provider.markReturned(loan);
    if (context.mounted) {
      showAppSnackBar(context, '"${loan.title}" sudah ditandai dikembalikan.');
    }
  } catch (error) {
    if (context.mounted) {
      showAppSnackBar(context, error.toString(), isError: true);
    }
  }
}
