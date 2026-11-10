import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/breakpoints.dart';
import '../core/utils/feedback.dart';
import '../models/book.dart';
import '../providers/favorite_provider.dart';
import '../widgets/book_grid.dart';
import '../widgets/state_view.dart';
import 'book_detail_screen.dart';
import 'explore_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _clearFavorites(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Kosongkan favorit?',
      message: 'Semua buku di daftar favorit akan dihapus dari perangkat ini.',
      confirmLabel: 'Kosongkan',
    );
    if (!confirmed || !context.mounted) return;

    context.read<FavoriteProvider>().clear();
    showAppSnackBar(context, 'Daftar favorit sudah dikosongkan.');
  }

  void _toggleFavorite(BuildContext context, Book book) {
    context.read<FavoriteProvider>().remove(book.key);
    showAppSnackBar(context, '"${book.title}" dihapus dari favorit.');
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit'),
        actions: [
          if (favorites.count > 0)
            IconButton(
              tooltip: 'Kosongkan favorit',
              onPressed: () => _clearFavorites(context),
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = Breakpoints.horizontalPadding(constraints.maxWidth);

            if (favorites.books.isEmpty) {
              return StateView(
                icon: Icons.favorite_border_rounded,
                title: 'Belum ada buku favorit',
                message:
                    'Ketuk ikon hati pada buku di katalog untuk menyimpannya di sini.',
                actionLabel: 'Jelajahi katalog',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExploreScreen(autofocus: true),
                    ),
                  );
                },
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${favorites.count} buku tersimpan',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            'Disimpan di perangkat ini',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 20),
                        child: BookGrid(
                          books: favorites.books,
                          isFavorite: (_) => true,
                          onToggleFavorite: (book) => _toggleFavorite(context, book),
                          onTapBook: (book) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookDetailScreen(book: book),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
