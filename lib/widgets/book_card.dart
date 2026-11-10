import 'package:flutter/material.dart';

import '../models/book.dart';
import 'book_cover.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.width,
  });

  final Book book;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BookCover(url: book.coverUrl(), borderRadius: 10),
                      if (onToggleFavorite != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Material(
                            color: colors.surface.withValues(alpha: 0.9),
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: onToggleFavorite,
                              tooltip: isFavorite ? 'Hapus dari favorit' : 'Simpan ke favorit',
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              icon: Icon(
                                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFavorite ? colors.error : colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  book.authorLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      book.firstPublishYear?.toString() ?? 'Tahun ?',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (book.editionCount != null)
                      Text(
                        '${book.editionCount} edisi',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookListTile extends StatelessWidget {
  const BookListTile({
    super.key,
    required this.book,
    required this.onTap,
    this.trailing,
  });

  final Book book;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                height: 78,
                child: BookCover(url: book.coverUrl(), borderRadius: 8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [book.firstPublishYear?.toString(), '${book.editionCount ?? 0} edisi']
                          .where((item) => item != null && item != '0 edisi')
                          .join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
