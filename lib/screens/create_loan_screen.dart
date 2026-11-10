import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_info.dart';
import '../core/utils/formatters.dart';
import '../core/utils/feedback.dart';
import '../models/book.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';
import '../widgets/book_cover.dart';

class CreateLoanScreen extends StatefulWidget {
  const CreateLoanScreen({super.key, required this.book});

  final Book book;

  @override
  State<CreateLoanScreen> createState() => _CreateLoanScreenState();
}

class _CreateLoanScreenState extends State<CreateLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  late final TextEditingController _dueDateController;

  late DateTime _dueDate;
  int _duration = 14;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: AppInfo.studentName);
    _dueDate = DateTime.now().add(Duration(days: _duration));
    _dueDateController = TextEditingController(text: Formatters.date(_dueDate));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _setDuration(int days) {
    setState(() {
      _duration = days;
      _dueDate = DateTime.now().add(Duration(days: days));
      _dueDateController.text = Formatters.date(_dueDate);
    });
  }

  Future<void> _pickDueDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 60)),
      helpText: 'Pilih tenggat pengembalian',
      cancelText: 'Batal',
      confirmText: 'Simpan',
    );

    if (picked == null) return;

    setState(() {
      _dueDate = picked;
      _dueDateController.text = Formatters.date(picked);
      _duration = picked.difference(DateTime(today.year, today.month, today.day)).inDays;
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

  String? _validateDueDate(String? value) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    if (_dueDate.isBefore(start)) return 'Tenggat tidak boleh di masa lalu.';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<LoanProvider>();
    final book = widget.book;
    final notes = _notesController.text.trim();

    final loan = Loan(
      id: '',
      bookKey: book.key,
      title: book.title,
      author: book.authors.isEmpty ? null : book.authors.join(', '),
      coverId: book.coverId,
      borrowerName: _nameController.text.trim(),
      borrowerEmail: _emailController.text.trim(),
      borrowedAt: DateTime.now(),
      dueDate: _dueDate,
      status: LoanStatus.borrowed,
      notes: notes.isEmpty ? null : notes,
    );

    try {
      await provider.create(loan);
      if (!mounted) return;
      showAppSnackBar(context, '"${book.title}" berhasil dipinjam.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, error.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSaving = context.watch<LoanProvider>().isSaving;
    final book = widget.book;

    return Scaffold(
      appBar: AppBar(title: const Text('Pinjam buku')),
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
                    _BookSummary(book: book),
                    const SizedBox(height: 24),
                    Text(
                      'Data peminjaman',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catatan ini akan disimpan ke tabel loans di Supabase.',
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
                        hintText: 'Nama lengkap peminjam',
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
                        hintText: 'nama@email.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                        helperText: 'Dipakai untuk pengingat pengembalian.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _dueDateController,
                      readOnly: true,
                      onTap: _pickDueDate,
                      validator: _validateDueDate,
                      decoration: InputDecoration(
                        labelText: 'Tenggat pengembalian',
                        prefixIcon: const Icon(Icons.event_outlined),
                        suffixIcon: const Icon(Icons.edit_calendar_outlined),
                        helperText: 'Ketuk untuk memilih tanggal lain.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Durasi cepat',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final days in const [7, 14, 30])
                          ChoiceChip(
                            label: Text('$days hari'),
                            selected: _duration == days,
                            showCheckmark: false,
                            onSelected: (_) => _setDuration(days),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      maxLength: 200,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        hintText: 'Contoh: buku dipinjam untuk tugas kuliah.',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.notes_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                            : const Icon(Icons.check_rounded),
                        label: Text(isSaving ? 'Menyimpan...' : 'Simpan peminjaman'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Pastikan data sudah benar sebelum disimpan.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
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

class _BookSummary extends StatelessWidget {
  const _BookSummary({required this.book});

  final Book book;

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
            child: BookCover(url: book.coverUrl(), borderRadius: 9),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.authorLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Peminjaman baru',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
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
