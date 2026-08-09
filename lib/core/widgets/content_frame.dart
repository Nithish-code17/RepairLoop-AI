import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class ContentFrame extends StatelessWidget {
  const ContentFrame({
    required this.child,
    this.padding = const EdgeInsets.all(AppConstants.pagePadding),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: Padding(padding: padding, child: child),
        ),
      );
}
