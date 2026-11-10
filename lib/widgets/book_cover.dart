import 'package:flutter/material.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.url,
    this.borderRadius = 14,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget placeholder = Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.auto_stories_rounded,
        color: colors.onSurfaceVariant.withValues(alpha: 0.55),
        size: 34,
      ),
    );

    final image = url == null || url!.isEmpty
        ? placeholder
        : Image.network(
            url!,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: child,
              );
            },
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return ColoredBox(
                color: colors.surfaceContainerHighest,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => placeholder,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}
