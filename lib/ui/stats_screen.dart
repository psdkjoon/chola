import 'package:flutter/material.dart' hide Text, Icon;
import 'package:chola/localization/localization.dart';
import 'package:chola/practice/topics.dart';
import 'package:chola/practice/stats_store.dart';
import 'package:chola/theme/app_spacing.dart';
import 'package:chola/ui/widgets/layout.dart';
import 'package:chola/ui/widgets/page_frame.dart';
import 'package:chola/ui/widgets/settings_section.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({required this.stats, super.key});

  final StatsStore stats;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: stats,
      builder: (context, _) {
        if (stats.isEmpty) {
          return PageFrame(
            child: Center(
              child: Text(
                'Nothing here yet. Finish a session first.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, box) {
            final split = Layout.split(box.maxWidth);
            final data = SettingsSection(
              title: 'Data',
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Reset stats'),
                  onTap: () => _confirmReset(context),
                ),
              ],
            );
            if (!split) {
              return PageFrame(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.lg,
                    children: [
                      _overall(),
                      _achievements(context),
                      ..._byTopic(context),
                      _recent(),
                      data,
                    ],
                  ),
                ),
              );
            }
            return PageFrame(
              width: 1180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xl,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.lg,
                        children: [
                          _overall(),
                          _achievements(context),
                          _recent(),
                          data,
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.lg,
                        children: _byTopic(context),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _overall() {
    final solved = stats.totalSolved;
    final accuracy = (stats.totalCorrect * 100 / solved).round();
    final average = stats.totalMillis / solved / 1000;
    return SettingsSection(
      title: 'Overall',
      children: [
        _row('Solved', '$solved'),
        _row('Accuracy', '$accuracy%'),
        _row('Average time', '${average.toStringAsFixed(1)} s'),
      ],
    );
  }

  Widget _row(String title, String value) {
    return ListTile(title: Text(title), trailing: Text(value));
  }

  Widget _achievements(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final solved = stats.totalSolved;
    final accuracy = solved == 0 ? 0.0 : stats.totalCorrect / solved;
    final best = stats.bestDayStreak;
    final levels = Level.values
        .where(
          (level) => Topics.forLevel(level)
              .any((topic) => (stats.statFor(topic.id)?.solved ?? 0) > 0),
        )
        .length;
    final items = <(IconData, String, String, bool)>[
      (
        Icons.emoji_events_rounded,
        'Hundred club',
        'Solve 100 questions',
        solved >= 100,
      ),
      (
        Icons.military_tech_rounded,
        'Thousand club',
        'Solve 1000 questions',
        solved >= 1000,
      ),
      (
        Icons.local_fire_department_rounded,
        'Three in a row',
        'Practice 3 days in a row',
        best >= 3,
      ),
      (
        Icons.calendar_month_rounded,
        'Full week',
        'Practice 7 days in a row',
        best >= 7,
      ),
      (
        Icons.bolt_rounded,
        'Sharp mind',
        'Reach 90% accuracy over 50 questions',
        solved >= 50 && accuracy >= 0.9,
      ),
      (
        Icons.explore_rounded,
        'Explorer',
        'Try 10 different topics',
        stats.topicsTried >= 10,
      ),
      (
        Icons.school_rounded,
        'All levels',
        'Practice every education level',
        levels >= Level.values.length,
      ),
    ];
    return SettingsSection(
      title: 'Achievements',
      children: [
        for (final (icon, name, goal, unlocked) in items)
          ListTile(
            leading: Icon(
              unlocked ? icon : Icons.lock_outline_rounded,
              color: unlocked ? scheme.primary : scheme.onSurfaceVariant,
            ),
            title: Text(name),
            subtitle: Text(goal),
            trailing: unlocked
                ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                : null,
          ),
      ],
    );
  }

  List<Widget> _byTopic(BuildContext context) {
    return [
      for (final level in Level.values)
        if (_tiles(context, level).isNotEmpty)
          SettingsSection(title: level.label, children: _tiles(context, level)),
    ];
  }

  List<Widget> _tiles(BuildContext context, Level level) {
    final scheme = Theme.of(context).colorScheme;
    return [
      for (final topic in Topics.forLevel(level))
        if (stats.statFor(topic.id) case final stat? when stat.solved > 0)
          ListTile(
            title: Text(topic.label),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xxs,
              children: [
                Text(
                  '${stat.solved} solved · ${(stat.accuracy * 100).round()}% · ${stat.averageSeconds.toStringAsFixed(1)} s',
                ),
                LinearProgressIndicator(
                  value: stat.accuracy,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  color: stat.accuracy >= 0.85
                      ? scheme.primary
                      : (stat.accuracy >= 0.6 ? scheme.tertiary : scheme.error),
                ),
              ],
            ),
          ),
    ];
  }

  Widget _recent() {
    return SettingsSection(
      title: 'Recent sessions',
      children: [
        for (final record in stats.sessions.take(15))
          ListTile(
            title: Text('${record.correct} / ${record.total}'),
            subtitle: Text(_date(record.time)),
            trailing: Text('${(record.averageMillis / 1000).toStringAsFixed(1)} s'),
          ),
      ],
    );
  }

  String _date(int millis) {
    final time = DateTime.fromMillisecondsSinceEpoch(millis);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset stats'),
        content: const Text('This clears all your history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) stats.reset();
  }
}
