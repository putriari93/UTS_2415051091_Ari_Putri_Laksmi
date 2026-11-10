import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/breakpoints.dart';
import '../core/utils/feedback.dart';
import '../models/book.dart';
import '../models/book_category.dart';
import '../providers/book_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/book_grid.dart';
import '../widgets/state_view.dart';
import 'book_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.initialQuery, this.autofocus = false});

  final String? initialQuery;
  final bool autofocus;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookProvider>().search(query: _controller.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<BookProvider>().search(query: value);
    });
  }

  void _applyCategory(BookCategory category) {
    FocusScope.of(context).unfocus();
    context.read<BookProvider>().search(
          query: _controller.text,
          category: category,
        );
  }

  void _clear() {
    _controller.clear();
    setState(() {});
    context.read<BookProvider>().search(query: '');
  }

  void _toggleFavorite(Book book) {
    final added = context.read<FavoriteProvider>().toggle(book);
    showAppSnackBar(
      context,
      added ? '"${book.title}" disimpan ke favorit.' : '"${book.title}" dihapus dari favorit.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();
    final favorites = context.watch<FavoriteProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jelajah buku'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => provider.search(query: _controller.text),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = Breakpoints.horizontalPadding(constraints.maxWidth);

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 0),
                  child: TextField(
                    controller: _controller,
                    autofocus: widget.autofocus,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (value) {
                      _debounce?.cancel();
                      FocusScope.of(context).unfocus();
                      provider.search(query: value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari judul, penulis, atau subjek',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: _clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: horizontal),
                    itemCount: BookCategory.all.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = BookCategory.all[index];
                      final selected = provider.category.label == category.label;
                      return ChoiceChip(
                        label: Text(category.label),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) => _applyCategory(category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildContent(
                    context,
                    provider: provider,
                    favorites: favorites,
                    horizontal: horizontal,
                    theme: theme,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required BookProvider provider,
    required FavoriteProvider favorites,
    required double horizontal,
    required ThemeData theme,
  }) {
    if (provider.isLoading && provider.books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.books.isEmpty) {
      return StateView(
        icon: Icons.cloud_off_rounded,
        title: 'Katalog belum bisa dimuat',
        message: provider.error,
        actionLabel: 'Coba lagi',
        onAction: () => provider.search(query: _controller.text),
        tone: StateTone.error,
      );
    }

    if (provider.books.isEmpty) {
      return StateView(
        icon: Icons.search_off_rounded,
        title: 'Buku tidak ditemukan',
        message: 'Coba kata kunci lain atau pilih kategori yang berbeda.',
        actionLabel: 'Cari ulang',
        onAction: () => provider.search(query: _controller.text),
      );
    }

    final label = provider.isFiltering
        ? '${provider.books.length} buku ditemukan'
        : 'Buku populer hari ini';

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (provider.category.subject != null)
                Text(
                  provider.category.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: BookGrid(
              books: provider.books,
              padding: const EdgeInsets.only(bottom: 12),
              isFavorite: (book) => favorites.isFavorite(book.key),
              onToggleFavorite: _toggleFavorite,
              onTapBook: (book) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
                );
              },
            ),
          ),
        ),
        if (provider.loadMoreError != null)
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 8),
            child: Text(
              provider.loadMoreError!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (provider.hasMore || provider.loadMoreError != null)
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: provider.isLoadingMore ? null : provider.loadMore,
                child: provider.isLoadingMore
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Muat buku lainnya'),
              ),
            ),
          ),
      ],
    );
  }
}
