import 'package:flutter/material.dart' hide Text, Icon;
import 'package:chola/localization/localization.dart';
import 'package:chola/practice/topics.dart';
import 'package:chola/theme/app_spacing.dart';
import 'package:chola/ui/widgets/math_text.dart';

class TopicPicker extends StatelessWidget {
  const TopicPicker({
    required this.level,
    required this.selected,
    required this.onToggle,
    required this.onGroup,
    super.key,
  });

  final Level level;
  final bool Function(String id) selected;
  final ValueChanged<String> onToggle;
  final void Function(List<String> ids, {required bool select}) onGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, box) {
          final columns = box.maxWidth >= 560 ? 3 : 2;
          final width =
              (box.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [
              for (final category in Topics.categories(level))
                _section(theme, scheme, category, width),
            ],
          );
        },
      ),
    );
  }

  Widget _section(
    ThemeData theme,
    ColorScheme scheme,
    String category,
    double width,
  ) {
    final topics = Topics.inCategory(level, category);
    final ids = <String>[for (final t in topics) t.id];
    final all = ids.every(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xxs,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () => onGroup(ids, select: !all),
              child: Text(all ? 'Clear' : 'Select all'),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final topic in topics)
              SizedBox(
                width: width,
                child: _TopicTile(
                  topic: topic,
                  selected: selected(topic.id),
                  onTap: () => onToggle(topic.id),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  final Topic topic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        selected ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final foreground =
        selected ? scheme.onPrimaryContainer : scheme.onSurface;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: AppSpacing.xxs,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xxs,
                  children: [
                    Expanded(
                      child: Text(
                        topic.label,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: foreground),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: MathText(
                      topic.example,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
