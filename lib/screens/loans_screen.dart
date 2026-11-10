import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/breakpoints.dart';
import '../core/utils/loan_actions.dart';
import '../models/loan.dart';
import '../providers/loan_provider.dart';
import '../widgets/loan_card.dart';
import '../widgets/state_view.dart';
import 'edit_loan_screen.dart';
import 'explore_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

enum _LoanFilter { all, active, returned }

class _LoansScreenState extends State<LoansScreen> {
  _LoanFilter _filter = _LoanFilter.all;

  List<Loan> _filtered(List<Loan> loans) {
    final filtered = switch (_filter) {
      _LoanFilter.all => [...loans],
      _LoanFilter.active =>
        loans.where((loan) => loan.status == LoanStatus.borrowed).toList(),
      _LoanFilter.returned =>
        loans.where((loan) => loan.status == LoanStatus.returned).toList(),
    };

    filtered.sort((a, b) {
      if (a.isReturned != b.isReturned) return a.isReturned ? 1 : -1;
      if (a.isReturned) {
        final aDate = a.returnedAt ?? a.dueDate;
        final bDate = b.returnedAt ?? b.dueDate;
        return bDate.compareTo(aDate);
      }
      return a.dueDate.compareTo(b.dueDate);
    });

    return filtered;
  }

  void _openEdit(Loan loan) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditLoanScreen(loan: loan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoanProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peminjaman'),
        actions: [
          IconButton(
            tooltip: 'Tambah dari katalog',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExploreScreen(autofocus: true),
                ),
              );
            },
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => provider.load(showLoading: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = Breakpoints.horizontalPadding(constraints.maxWidth);
            final filtered = _filtered(provider.loans);

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${provider.activeCount} dipinjam · ${provider.returnedCount} selesai',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (provider.isSaving)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: horizontal),
                    itemCount: _LoanFilter.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _LoanFilter.values[index];
                      final label = switch (filter) {
                        _LoanFilter.all => 'Semua',
                        _LoanFilter.active => 'Masih dipinjam',
                        _LoanFilter.returned => 'Dikembalikan',
                      };
                      return ChoiceChip(
                        label: Text(label),
                        selected: _filter == filter,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _filter = filter),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.load(showLoading: false),
                    child: _buildBody(
                      context,
                      provider: provider,
                      filtered: filtered,
                      horizontal: horizontal,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required LoanProvider provider,
    required List<Loan> filtered,
    required double horizontal,
  }) {
    if (provider.isLoading && provider.loans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.loans.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: StateView(
              icon: Icons.storage_rounded,
              title: 'Data peminjaman gagal dimuat',
              message: provider.error,
              actionLabel: 'Coba lagi',
              onAction: () => provider.load(),
              tone: StateTone.error,
            ),
          ),
        ],
      );
    }

    if (filtered.isEmpty) {
      final emptyAll = provider.loans.isEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: StateView(
              icon: emptyAll ? Icons.library_books_outlined : Icons.filter_alt_off_outlined,
              title: emptyAll
                  ? 'Belum ada peminjaman'
                  : _filter == _LoanFilter.active
                      ? 'Tidak ada buku yang sedang dipinjam'
                      : 'Belum ada buku yang dikembalikan',
              message: emptyAll
                  ? 'Pilih buku dari katalog Open Library, lalu simpan peminjaman pertamamu.'
                  : 'Coba pilih filter lain untuk melihat catatan lainnya.',
              actionLabel: emptyAll ? 'Cari buku' : null,
              onAction: emptyAll
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExploreScreen(autofocus: true),
                        ),
                      );
                    }
                  : null,
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Breakpoints.listColumns(constraints.maxWidth);
        final gap = 12.0;
        final itemWidth =
            (constraints.maxWidth - horizontal * 2 - gap * (columns - 1)) / columns;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 28),
          children: [
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final loan in filtered)
                  SizedBox(
                    width: itemWidth,
                    child: LoanCard(
                      loan: loan,
                      onTap: () => _openEdit(loan),
                      onEdit: () => _openEdit(loan),
                      onMarkReturned: loan.isReturned
                          ? null
                          : () => markLoanReturned(context, loan),
                      onDelete: () => deleteLoanWithConfirmation(context, loan),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
