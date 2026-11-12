import 'package:flutter/material.dart';
import 'package:chola/theme/app_spacing.dart';
import 'package:chola/ui/widgets/layout.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    required this.child,
    this.actions = const [],
    this.width = maxWidth,
    super.key,
  });

  final Widget child;
  final List<Widget> actions;
  final double width;

  static const double maxWidth = 36 * AppSpacing.spaceUnit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final edge = Layout.edge(box.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: Padding(
              padding: EdgeInsets.only(left: edge, right: edge, top: edge),
              child: Column(
                spacing: AppSpacing.md,
                children: [
                  if (actions.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
