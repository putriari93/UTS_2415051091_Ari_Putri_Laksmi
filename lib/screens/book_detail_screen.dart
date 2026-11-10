import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/formatters.dart';
import '../core/utils/feedback.dart';
import '../models/book.dart';
import '../models/book_detail.dart';
import '../providers/book_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/loan_provider.dart';
import '../widgets/book_cover.dart';
import '../widgets/section_header.dart';
import 'create_loan_screen.dart';
import 'edit_loan_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book});

  final Book book;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Future<BookDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = context.read<BookProvider>().detailFor(widget.book);
  }

  void _retryDetail() {
    context.read<BookProvider>().forgetDetail(widget.book.key);
    setState(() {
      _detailFuture = context.read<BookProvider>().detailFor(widget.book);
    });
  }

  void _toggleFavorite() {
    final added = context.read<FavoriteProvider>().toggle(widget.book);
    showAppSnackBar(
      context,
      added ? 'Buku disimpan ke favorit.' : 'Buku dihapus dari favorit.',
    );
  }

  Future<void> _openCreateLoan() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateLoanScreen(book: widget.book)),
    );

    if (created == true && mounted) {
      // Biarkan halaman detail menampilkan status peminjaman terbaru.
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favorites = context.watch<FavoriteProvider>();
    final loans = context.watch<LoanProvider>();
    final isFavorite = favorites.isFavorite(widget.book.key);
    final activeLoan = loans.activeLoanFor(widget.book.key);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail buku'),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Hapus dari favorit' : 'Simpan ke favorit',
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? theme.colorScheme.error : null,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 860;
            final horizontal = wide ? 32.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 260, child: _buildCover()),
                            const SizedBox(width: 36),
                            Expanded(child: _buildInformation(context, activeLoan)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: SizedBox(width: 190, child: _buildCover()),
                            ),
                            const SizedBox(height: 24),
                            _buildInformation(context, activeLoan),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCover() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: BookCover(url: widget.book.coverUrl(size: 'L'), borderRadius: 20),
      ),
    );
  }

  Widget _buildInformation(BuildContext context, dynamic activeLoan) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final book = widget.book;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (book.subjects.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final subject in book.subjects.take(3))
                Chip(
                  label: Text(subject),
                  visualDensity: VisualDensity.compact,
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Text(
          book.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.edit_outlined, size: 16, color: colors.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                book.authorLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaPill(
              icon: Icons.calendar_today_rounded,
              label: book.firstPublishYear?.toString() ?? 'Tahun tidak diketahui',
            ),
            if (book.editionCount != null)
              _MetaPill(
                icon: Icons.layers_outlined,
                label: '${book.editionCount} edisi',
              ),
            if (book.language != null)
              _MetaPill(
                icon: Icons.translate_rounded,
                label: book.language!.toUpperCase(),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _AvailabilityCard(book: book, activeLoan: activeLoan),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: activeLoan == null ? _openCreateLoan : null,
                icon: Icon(
                  activeLoan == null
                      ? Icons.library_add_outlined
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(
                  activeLoan == null ? 'Pinjam buku ini' : 'Sedang dipinjam',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleFavorite,
                icon: Icon(
                  context.watch<FavoriteProvider>().isFavorite(book.key)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                label: Text(
                  context.watch<FavoriteProvider>().isFavorite(book.key)
                      ? 'Tersimpan'
                      : 'Favorit',
                ),
              ),
            ),
          ],
        ),
        if (activeLoan != null) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditLoanScreen(loan: activeLoan),
                ),
              );
            },
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Kelola peminjaman ini'),
          ),
        ],
        const SizedBox(height: 28),
        SectionHeader(title: 'Tentang buku'),
        const SizedBox(height: 10),
        FutureBuilder<BookDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Memuat deskripsi...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deskripsi belum bisa dimuat.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.error,
                    ),
                  ),
                  TextButton(
                    onPressed: _retryDetail,
                    child: const Text('Coba lagi'),
                  ),
                ],
              );
            }

            final description = snapshot.data?.description;
            return Text(
              description ?? 'Open Library belum menyediakan deskripsi untuk buku ini.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.65,
                color: description == null ? colors.onSurfaceVariant : null,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _DetailFacts(book: book, detailFuture: _detailFuture),
      ],
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.book, required this.activeLoan});

  final Book book;
  final dynamic activeLoan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isBorrowed = activeLoan != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBorrowed ? colors.tertiaryContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isBorrowed ? Icons.schedule_rounded : Icons.check_circle_outline_rounded,
            color: isBorrowed ? colors.onTertiaryContainer : colors.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBorrowed ? 'Sedang dipinjam' : 'Tersedia untuk dipinjam',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isBorrowed ? colors.onTertiaryContainer : colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isBorrowed
                      ? 'Oleh ${activeLoan.borrowerName} · jatuh tempo ${Formatters.date(activeLoan.dueDate)}'
                      : 'Belum ada catatan peminjaman aktif untuk buku ini.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isBorrowed ? colors.onTertiaryContainer : colors.onPrimaryContainer,
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailFacts extends StatelessWidget {
  const _DetailFacts({required this.book, required this.detailFuture});

  final Book book;
  final Future<BookDetail> detailFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: FutureBuilder<BookDetail>(
        future: detailFuture,
        builder: (context, snapshot) {
          final detail = snapshot.data;
          final rows = <(String, String)>[
            ('ID Open Library', book.workId),
            ('Edisi', book.editionCount?.toString() ?? 'Tidak diketahui'),
            ('Bahasa', book.language?.toUpperCase() ?? 'Tidak diketahui'),
            ('Akses e-book', book.ebookAccess ?? 'Tidak diketahui'),
            if (detail?.firstPublishDate != null)
              ('Terbit pertama', detail!.firstPublishDate!),
          ];

          return Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          rows[index].$1,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          rows[index].$2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != rows.length - 1) const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }
}
