import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/loan.dart';
import 'app_exception.dart';

class LoanService {
  LoanService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _table => SupabaseConfig.loansTable;

  Future<List<Loan>> fetchLoans() async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      return rows.map(Loan.fromJson).toList();
    } on PostgrestException catch (error) {
      throw AppException(_friendlyMessage(error, action: 'memuat'));
    } catch (_) {
      throw const AppException(
        'Gagal memuat data peminjaman dari database. Periksa koneksi lalu coba lagi.',
      );
    }
  }

  Future<Loan> createLoan(Loan loan) async {
    try {
      final row = await _client
          .from(_table)
          .insert(loan.toDatabaseJson())
          .select()
          .single();
      return Loan.fromJson(row);
    } on PostgrestException catch (error) {
      throw AppException(_friendlyMessage(error, action: 'menyimpan'));
    } catch (_) {
      throw const AppException(
        'Peminjaman belum tersimpan. Periksa koneksi lalu coba lagi.',
      );
    }
  }

  Future<Loan> updateLoan(Loan loan) async {
    try {
      final row = await _client
          .from(_table)
          .update(loan.toDatabaseJson())
          .eq('id', loan.id)
          .select()
          .single();
      return Loan.fromJson(row);
    } on PostgrestException catch (error) {
      throw AppException(_friendlyMessage(error, action: 'memperbarui'));
    } catch (_) {
      throw const AppException(
        'Perubahan peminjaman gagal disimpan. Silakan coba lagi.',
      );
    }
  }

  Future<void> deleteLoan(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } on PostgrestException catch (error) {
      throw AppException(_friendlyMessage(error, action: 'menghapus'));
    } catch (_) {
      throw const AppException(
        'Peminjaman gagal dihapus. Periksa koneksi lalu coba lagi.',
      );
    }
  }

  String _friendlyMessage(PostgrestException error, {required String action}) {
    final message = error.message.toLowerCase();

    if (error.code == 'PGRST205' || message.contains('could not find the table')) {
      return 'Tabel loans belum tersedia di Supabase. Jalankan skrip supabase/schema.sql lebih dulu.';
    }
    if (error.code == '42501' || message.contains('row-level security')) {
      return 'Akses tabel loans dibatasi. Periksa policy RLS pada Supabase.';
    }
    if (error.code == '23514') {
      return 'Data peminjaman tidak sesuai aturan tabel. Periksa status dan tanggalnya.';
    }
    return 'Gagal $action data peminjaman: ${error.message}';
  }
}
