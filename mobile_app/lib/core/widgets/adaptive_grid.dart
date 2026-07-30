import 'package:flutter/material.dart';

class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double itemSpacing;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.itemSpacing = 16.0,
  });

  int _columnCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnCount(constraints.maxWidth);
        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: itemSpacing,
          crossAxisSpacing: itemSpacing,
          childAspectRatio: 2.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children.map((child) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 100),
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
