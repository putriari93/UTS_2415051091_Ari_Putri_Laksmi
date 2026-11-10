import 'package:flutter/material.dart';

import '../core/utils/breakpoints.dart';

class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = Breakpoints.horizontalPadding(constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minWidth: constraints.maxWidth,
            ),
            child: Padding(
              padding: padding ??
                  EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
