import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/formatters.dart';
import '../core/utils/feedback.dart';
import '../core/utils/loan_actions.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';
import '../widgets/book_cover.dart';

class EditLoanScreen extends StatefulWidget {
  const EditLoanScreen({super.key, required this.loan});

  final Loan loan;

  @override
  State<EditLoanScreen> createState() => _EditLoanScreenState();
}

class _EditLoanScreenState extends State<EditLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;
  late final TextEditingController _dueDateController;

  late DateTime _dueDate;
  late LoanStatus _status;

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    _nameController = TextEditingController(text: loan.borrowerName);
    _emailController = TextEditingController(text: loan.borrowerEmail ?? '');
    _notesController = TextEditingController(text: loan.notes ?? '');
    _dueDate = loan.dueDate;
    _dueDateController = TextEditingController(text: Formatters.date(loan.dueDate));
    _status = loan.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(firstDate) ? firstDate : _dueDate,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 90)),
      helpText: 'Ubah tenggat pengembalian',
      cancelText: 'Batal',
      confirmText: 'Simpan',
    );

    if (picked == null) return;

    setState(() {
      _dueDate = picked;
      _dueDateController.text = Formatters.date(picked);
    });
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Nama peminjam wajib diisi.';
    if (name.length < 3) return 'Nama terlalu pendek, minimal 3 karakter.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi untuk pengingat.';
    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(email)) return 'Format email belum benar.';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final loan = widget.loan;
    final notes = _notesController.text.trim();
    final updated = Loan(
      id: loan.id,
      bookKey: loan.bookKey,
      title: loan.title,
      author: loan.author,
      coverId: loan.coverId,
      borrowerName: _nameController.text.trim(),
      borrowerEmail: _emailController.text.trim(),
      borrowedAt: loan.borrowedAt,
      dueDate: _dueDate,
      returnedAt: _status == LoanStatus.returned
          ? (loan.returnedAt ?? DateTime.now())
          : null,
      status: _status,
      notes: notes.isEmpty ? null : notes,
      createdAt: loan.createdAt,
    );

    try {
      await context.read<LoanProvider>().update(updated);
      if (!mounted) return;
      showAppSnackBar(context, 'Perubahan peminjaman sudah disimpan.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, error.toString(), isError: true);
    }
  }

  Future<void> _deleteLoan() async {
    final deleted = await deleteLoanWithConfirmation(context, widget.loan);
    if (deleted && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final loan = widget.loan;
    final isSaving = context.watch<LoanProvider>().isSaving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit peminjaman'),
        actions: [
          IconButton(
            tooltip: 'Hapus peminjaman',
            onPressed: isSaving ? null : _deleteLoan,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LoanSummary(loan: loan),
                    const SizedBox(height: 24),
                    Text(
                      'Perbarui catatan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perubahan langsung dikirim ke tabel loans di Supabase.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: _validateName,
                      decoration: const InputDecoration(
                        labelText: 'Nama peminjam',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _dueDateController,
                      readOnly: true,
                      onTap: _pickDueDate,
                      decoration: const InputDecoration(
                        labelText: 'Tenggat pengembalian',
                        prefixIcon: Icon(Icons.event_outlined),
                        suffixIcon: Icon(Icons.edit_calendar_outlined),
                        helperText: 'Ketuk untuk mengubah tanggal.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        hintText: 'Tambahkan catatan peminjaman.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Material(
                      color: colors.surfaceContainerLowest,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colors.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: SwitchListTile(
                        value: _status == LoanStatus.returned,
                        onChanged: (value) {
                          setState(() {
                            _status = value ? LoanStatus.returned : LoanStatus.borrowed;
                          });
                        },
                        title: const Text('Sudah dikembalikan'),
                        subtitle: Text(
                          _status == LoanStatus.returned
                              ? 'Buku tercatat kembali ke rak.'
                              : 'Buku masih dipinjam sampai tenggat di atas.',
                        ),
                        secondary: Icon(
                          Icons.assignment_turned_in_outlined,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSaving ? null : _submit,
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(isSaving ? 'Menyimpan...' : 'Simpan perubahan'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: isSaving ? null : _deleteLoan,
                        style: TextButton.styleFrom(foregroundColor: colors.error),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Hapus peminjaman ini'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoanSummary extends StatelessWidget {
  const _LoanSummary({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 86,
            child: BookCover(url: loan.coverUrl, borderRadius: 9),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (loan.author != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    loan.author!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  loan.borrowedAt == null
                      ? 'Dicatat di Supabase'
                      : 'Dipinjam ${Formatters.date(loan.borrowedAt!)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
