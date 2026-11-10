import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_info.dart';
import '../core/utils/breakpoints.dart';
import '../core/utils/formatters.dart';
import '../core/utils/feedback.dart';
import '../core/utils/loan_actions.dart';
import '../models/book.dart';
import '../models/loan.dart';
import '../providers/book_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/loan_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/loan_card.dart';
import '../widgets/section_header.dart';
import '../widgets/state_view.dart';
import '../widgets/stat_card.dart';
import 'book_detail_screen.dart';
import 'edit_loan_screen.dart';
import 'explore_screen.dart';
import 'loans_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExploreScreen(autofocus: true),
      ),
    );
  }

  void _openBook(BuildContext context, Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  void _openLoan(BuildContext context, Loan loan) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditLoanScreen(loan: loan)),
    );
  }

  void _toggleFavorite(BuildContext context, Book book) {
    final added = context.read<FavoriteProvider>().toggle(book);
    showAppSnackBar(
      context,
      added ? '"${book.title}" disimpan ke favorit.' : '"${book.title}" dihapus dari favorit.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = context.watch<BookProvider>();
    final loanProvider = context.watch<LoanProvider>();
    final favorites = context.watch<FavoriteProvider>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = Breakpoints.horizontalPadding(constraints.maxWidth);

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  bookProvider.loadTrending(force: true),
                  loanProvider.load(showLoading: false),
                ]);
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 32),
                    children: [
                      _WelcomeHeader(onSearch: () => _openSearch(context)),
                      const SizedBox(height: 20),
                      _StatsSection(loanProvider: loanProvider),
                      if (loanProvider.overdueCount > 0) ...[
                        const SizedBox(height: 14),
                        _OverdueBanner(
                          count: loanProvider.overdueCount,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const LoansScreen()),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 26),
                      SectionHeader(
                        title: 'Rekomendasi hari ini',
                        subtitle: 'Buku yang sedang ramai dibaca di Open Library',
                        actionLabel: 'Jelajahi',
                        onAction: () => _openSearch(context),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 322,
                        child: _TrendingSection(
                          provider: bookProvider,
                          favorites: favorites,
                          onOpenBook: (book) => _openBook(context, book),
                          onToggleFavorite: (book) => _toggleFavorite(context, book),
                        ),
                      ),
                      const SizedBox(height: 26),
                      SectionHeader(
                        title: 'Peminjaman terakhir',
                        subtitle: loanProvider.error == null
                            ? 'Tersimpan di Supabase'
                            : 'Database belum bisa dihubungi',
                        actionLabel: 'Lihat semua',
                        onAction: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoansScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _RecentLoans(
                        provider: loanProvider,
                        onOpenLoan: (loan) => _openLoan(context, loan),
                        onFindBook: () => _openSearch(context),
                      ),
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
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final firstName = AppInfo.studentName.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary,
            Color.lerp(colors.primary, colors.secondary, 0.55) ?? colors.primary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: 14,
                          color: colors.onPrimary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Formatters.longDate(DateTime.now()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Halo, $firstName',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Buku apa yang ingin kamu baca minggu ini?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.onPrimary.withValues(alpha: 0.18),
                child: Text(
                  Formatters.initials(AppInfo.studentName),
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Material(
            color: colors.onPrimary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onSearch,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 20, color: colors.onPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cari judul, penulis, atau subjek...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: colors.onPrimary.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.loanProvider});

  final LoanProvider loanProvider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        const gap = 12.0;
        final itemWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: StatCard(
                label: 'Sedang dipinjam',
                value: '${loanProvider.activeCount}',
                icon: Icons.menu_book_rounded,
                color: colors.primary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                label: 'Perlu perhatian',
                value: '${loanProvider.dueSoonLoans.length}',
                icon: Icons.schedule_rounded,
                color: colors.tertiary,
                hint: '≤ 3 hari',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: StatCard(
                label: 'Selesai',
                value: '${loanProvider.returnedCount}',
                icon: Icons.task_alt_rounded,
                color: colors.secondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.notification_important_outlined, color: colors.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count buku sudah lewat tenggat pengembalian.',
              style: TextStyle(color: colors.onErrorContainer, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              'Lihat',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingSection extends StatelessWidget {
  const _TrendingSection({
    required this.provider,
    required this.favorites,
    required this.onOpenBook,
    required this.onToggleFavorite,
  });

  final BookProvider provider;
  final FavoriteProvider favorites;
  final void Function(Book book) onOpenBook;
  final void Function(Book book) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    if (provider.isTrendingLoading && provider.trending.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.trendingError != null && provider.trending.isEmpty) {
      return StateView(
        icon: Icons.cloud_off_rounded,
        title: 'Rekomendasi belum bisa dimuat',
        message: provider.trendingError,
        actionLabel: 'Coba lagi',
        onAction: () => provider.loadTrending(force: true),
        tone: StateTone.error,
      );
    }

    if (provider.trending.isEmpty) {
      return StateView(
        icon: Icons.auto_stories_outlined,
        title: 'Belum ada rekomendasi',
        message: 'Tarik ke bawah untuk memuat ulang daftar buku.',
        actionLabel: 'Muat ulang',
        onAction: () => provider.loadTrending(force: true),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: provider.trending.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final book = provider.trending[index];
        return SizedBox(
          width: 168,
          child: BookCard(
            book: book,
            onTap: () => onOpenBook(book),
            isFavorite: favorites.isFavorite(book.key),
            onToggleFavorite: () => onToggleFavorite(book),
          ),
        );
      },
    );
  }
}

class _RecentLoans extends StatelessWidget {
  const _RecentLoans({
    required this.provider,
    required this.onOpenLoan,
    required this.onFindBook,
  });

  final LoanProvider provider;
  final void Function(Loan loan) onOpenLoan;
  final VoidCallback onFindBook;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (provider.isLoading && provider.loans.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null && provider.loans.isEmpty) {
      return SizedBox(
        height: 260,
        child: StateView(
          icon: Icons.storage_rounded,
          title: 'Data peminjaman belum tersedia',
          message: provider.error,
          actionLabel: 'Coba lagi',
          onAction: () => provider.load(),
          tone: StateTone.error,
        ),
      );
    }

    if (provider.loans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(Icons.bookmark_add_outlined, size: 34, color: colors.primary),
            const SizedBox(height: 10),
            Text(
              'Belum ada buku yang dipinjam',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mulai dari katalog, lalu simpan peminjaman pertamamu.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onFindBook,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Cari buku'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final loan in provider.loans.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LoanCard(
              loan: loan,
              onTap: () => onOpenLoan(loan),
              onEdit: () => onOpenLoan(loan),
              onMarkReturned: loan.isReturned
                  ? null
                  : () => markLoanReturned(context, loan),
              onDelete: () => deleteLoanWithConfirmation(context, loan),
            ),
          ),
      ],
    );
  }
}
