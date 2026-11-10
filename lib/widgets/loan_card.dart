import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/loan.dart';
import 'book_cover.dart';

class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.loan,
    this.onEdit,
    this.onDelete,
    this.onMarkReturned,
    this.onTap,
  });

  final Loan loan;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkReturned;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dueColor = loan.isReturned
        ? colors.onSurfaceVariant
        : loan.isOverdue
            ? colors.error
            : loan.isDueSoon
                ? colors.tertiary
                : colors.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 58,
                height: 84,
                child: BookCover(url: loan.coverUrl, borderRadius: 9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final title = Text(
                          loan.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        );
                        final pill = _StatusPill(loan: loan);

                        if (constraints.maxWidth < 170) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              const SizedBox(height: 6),
                              pill,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: title),
                            const SizedBox(width: 6),
                            pill,
                          ],
                        );
                      },
                    ),
                    if (loan.author != null && loan.author!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        loan.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _InfoLine(
                      icon: Icons.person_outline_rounded,
                      text: loan.borrowerName,
                    ),
                    const SizedBox(height: 4),
                    _InfoLine(
                      icon: loan.isReturned
                          ? Icons.check_circle_outline_rounded
                          : Icons.event_rounded,
                      text: loan.isReturned
                          ? 'Dikembalikan ${Formatters.date(loan.returnedAt ?? loan.dueDate)}'
                          : '${Formatters.date(loan.dueDate)} · ${Formatters.relativeDue(loan.dueDate)}',
                      color: dueColor,
                    ),
                    if (loan.notes != null && loan.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        loan.notes!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null || onMarkReturned != null)
                PopupMenuButton<String>(
                  tooltip: 'Aksi peminjaman',
                  icon: Icon(Icons.more_vert_rounded, color: colors.onSurfaceVariant),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                      case 'return':
                        onMarkReturned?.call();
                      case 'delete':
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit peminjaman'),
                        ),
                      ),
                    if (onMarkReturned != null && !loan.isReturned)
                      const PopupMenuItem(
                        value: 'return',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.assignment_turned_in_outlined),
                          title: Text('Tandai dikembalikan'),
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('Hapus'),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 14, color: tint),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, background, foreground) = loan.isReturned
        ? ('Dikembalikan', colors.surfaceContainerHighest, colors.onSurfaceVariant)
        : loan.isOverdue
            ? ('Terlambat', colors.errorContainer, colors.onErrorContainer)
            : loan.isDueSoon
                ? ('Segera jatuh tempo', colors.tertiaryContainer, colors.onTertiaryContainer)
                : ('Dipinjam', colors.primaryContainer, colors.onPrimaryContainer);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
