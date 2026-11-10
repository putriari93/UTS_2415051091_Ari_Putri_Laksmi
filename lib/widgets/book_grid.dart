import 'package:flutter/material.dart';

import '../core/utils/breakpoints.dart';
import '../models/book.dart';
import 'book_card.dart';

class BookGrid extends StatelessWidget {
  const BookGrid({
    super.key,
    required this.books,
    required this.onTapBook,
    this.isFavorite,
    this.onToggleFavorite,
    this.padding = EdgeInsets.zero,
  });

  final List<Book> books;
  final void Function(Book book) onTapBook;
  final bool Function(Book book)? isFavorite;
  final void Function(Book book)? onToggleFavorite;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = Breakpoints.gridColumns(width);
        const spacing = 12.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;
        final itemExtent = cardWidth * 1.5 + 112;

        return GridView.builder(
          padding: padding,
          itemCount: books.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: itemExtent,
          ),
          itemBuilder: (context, index) {
            final book = books[index];
            return BookCard(
              book: book,
              onTap: () => onTapBook(book),
              isFavorite: isFavorite?.call(book) ?? false,
              onToggleFavorite: onToggleFavorite == null
                  ? null
                  : () => onToggleFavorite!(book),
            );
          },
        );
      },
    );
  }
}
