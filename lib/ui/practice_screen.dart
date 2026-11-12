import 'package:flutter/material.dart' hide Text, Icon;
import 'package:chola/localization/localization.dart';
import 'package:chola/platform/music_service.dart';
import 'package:chola/practice/practice_config.dart';
import 'package:chola/practice/stats_store.dart';
import 'package:chola/practice/topics.dart';
import 'package:chola/theme/app_spacing.dart';
import 'package:chola/ui/session_screen.dart';
import 'package:chola/ui/widgets/amount_picker.dart';
import 'package:chola/ui/widgets/layout.dart';
import 'package:chola/ui/widgets/page_frame.dart';
import 'package:chola/ui/widgets/settings_section.dart';
import 'package:chola/ui/widgets/topic_picker.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({required this.config, required this.stats, super.key});

  final PracticeConfig config;
  final StatsStore stats;

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionScreen(config: config, stats: stats),
      ),
    );
  }

  void _practiceWeakSpots(BuildContext context, List<Topic> weak) {
    config
      ..replaceTopics(<String>[for (final t in weak) t.id])
      ..level = weak.first.level.name;
    _start(context);
  }

  List<Topic> get _weakSpots {
    final scored = <(Topic, double)>[
      for (final topic in Topics.all)
        if (stats.statFor(topic.id) case final stat?
            when stat.solved >= 5 && stat.accuracy < 0.85)
          (topic, stat.accuracy),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return <Topic>[for (final item in scored.take(4)) item.$1];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[config, stats]),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, box) {
            final split = Layout.split(box.maxWidth);
            if (!split) {
              return PageFrame(
                child: Column(
                  spacing: AppSpacing.sm,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: AppSpacing.lg,
                          children: [
                            _today(context),
                            _level(box.maxWidth),
                            _topics(),
                            ..._options(context),
                          ],
                        ),
                      ),
                    ),
                    _startBar(context),
                  ],
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
                    flex: 6,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.lg,
                        children: [
                          _today(context),
                          _level(box.maxWidth * 0.55),
                          _topics(),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      spacing: AppSpacing.sm,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: AppSpacing.lg,
                              children: _options(context),
                            ),
                          ),
                        ),
                        _startBar(context),
                      ],
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

  Widget _today(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = config.dailyGoal;
    final done = stats.todayCount;
    final streak = stats.dayStreak;
    final value = (done / goal).clamp(0.0, 1.0).toDouble();
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 5,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                  Icon(
                    done >= goal ? Icons.check_rounded : Icons.flag_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  Text('$done / $goal', style: theme.textTheme.titleMedium),
                  if (streak > 0)
                    Row(
                      spacing: AppSpacing.xxs,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: scheme.tertiary,
                        ),
                        Text(
                          '$streak day streak',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: scheme.tertiary),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            PopupMenuButton<int>(
              icon: const Icon(Icons.tune_rounded),
              onSelected: (choice) => config.dailyGoal = choice,
              itemBuilder: (context) => [
                const PopupMenuItem<int>(
                  enabled: false,
                  child: Text('Daily goal'),
                ),
                for (final option in const <int>[10, 20, 50, 100])
                  CheckedPopupMenuItem<int>(
                    value: option,
                    checked: option == config.dailyGoal,
                    child: Text('$option'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _options(BuildContext context) => <Widget>[
        if (_usesNumbers) _numbers(),
        _difficulty(),
        _session(context),
      ];

  Widget _startBar(BuildContext context) {
    final weak = _weakSpots;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        spacing: AppSpacing.sm,
        children: [
          if (weak.isNotEmpty)
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              onPressed: () => _practiceWeakSpots(context, weak),
              icon: const Icon(Icons.track_changes_rounded),
              label: const Text('Practice weak spots'),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed:
                config.topics.isEmpty ? null : () => _start(context),
            icon: const Icon(Icons.bolt_rounded),
            label: const Text('Start'),
          ),
        ],
      ),
    );
  }

  bool get _usesNumbers => <String>[
        for (final id in config.topics)
          if (Topics.byId(id)?.usesNumbers ?? false) id,
      ].isNotEmpty;

  Level get _selectedLevel => Topics.levelNamed(config.level);

  static const Map<Level, IconData> _levelIcons = <Level, IconData>{
    Level.elementary: Icons.extension_rounded,
    Level.middle: Icons.calculate_rounded,
    Level.high: Icons.functions_rounded,
    Level.university: Icons.school_rounded,
  };

  int _selectedIn(Level level) => <String>[
        for (final topic in Topics.forLevel(level))
          if (config.hasTopic(topic.id)) topic.id,
      ].length;

  Widget _level(double width) {
    final current = _selectedLevel;
    final columns = width >= 520 ? 4 : 2;
    return SettingsSection(
      title: 'Education level',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: LayoutBuilder(
            builder: (context, box) {
              final cell =
                  (box.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final level in Level.values)
                    SizedBox(
                      width: cell,
                      child: _LevelCard(
                        level: level,
                        icon: _levelIcons[level] ?? Icons.school_rounded,
                        selected: level == current,
                        count: _selectedIn(level),
                        onTap: () => config.level = level.name,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _topics() {
    return SettingsSection(
      title: 'Topics',
      help: 'Choose topics from any level. Questions are drawn from everything you tick.',
      children: [
        TopicPicker(
          level: _selectedLevel,
          selected: config.hasTopic,
          onToggle: config.toggleTopic,
          onGroup: (ids, {required select}) =>
              config.setTopics(ids, selected: select),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Text('${config.topics.length} topics selected'),
        ),
      ],
    );
  }

  Widget _difficulty() {
    return SettingsSection(
      title: 'Difficulty',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SegmentedButton<int>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 1, label: Text('Easy')),
              ButtonSegment(value: 2, label: Text('Medium')),
              ButtonSegment(value: 3, label: Text('Hard')),
            ],
            selected: {config.difficulty},
            onSelectionChanged: (selection) =>
                config.difficulty = selection.first,
          ),
        ),
        SwitchListTile(
          title: const Text('Adaptive difficulty'),
          subtitle: const Text(
            'Questions get harder after a streak and easier after mistakes',
          ),
          value: config.adaptive,
          onChanged: (value) => config.adaptive = value,
        ),
      ],
    );
  }

  Widget _numbers() {
    final decimals = config.kind != NumberKind.whole;
    return SettingsSection(
      title: 'Numbers',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SegmentedButton<NumberKind>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: NumberKind.whole, label: Text('Whole')),
              ButtonSegment(value: NumberKind.decimal, label: Text('Decimal')),
              ButtonSegment(value: NumberKind.mixed, label: Text('Mixed')),
            ],
            selected: {config.kind},
            onSelectionChanged: (selection) => config.kind = selection.first,
          ),
        ),
        _Stepper(
          title: 'First number digits',
          value: config.leftDigits,
          min: 1,
          max: 6,
          onChanged: (value) => config.leftDigits = value,
        ),
        _Stepper(
          title: 'Second number digits',
          value: config.rightDigits,
          min: 1,
          max: 6,
          onChanged: (value) => config.rightDigits = value,
        ),
        if (decimals)
          _Stepper(
            title: 'Max decimal places',
            value: config.decimalPlaces,
            min: 1,
            max: 3,
            onChanged: (value) => config.decimalPlaces = value,
          ),
        if (decimals)
          _Stepper(
            title: 'Max decimal places of answer',
            value: config.answerPlaces,
            min: 0,
            max: 6,
            onChanged: (value) => config.answerPlaces = value,
          ),
        SwitchListTile(
          title: const Text('Allow negative answers'),
          value: config.allowNegative,
          onChanged: (value) => config.allowNegative = value,
        ),
      ],
    );
  }

  Widget _session(BuildContext context) {
    final mode = config.mode;
    return SettingsSection(
      title: 'Session',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SegmentedButton<SessionMode>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: SessionMode.timed, label: Text('Timed')),
              ButtonSegment(value: SessionMode.count, label: Text('Questions')),
              ButtonSegment(value: SessionMode.endless, label: Text('Endless')),
            ],
            selected: {mode},
            onSelectionChanged: (selection) => config.mode = selection.first,
          ),
        ),
        if (mode == SessionMode.timed)
          AmountPicker(
            presets: PracticeConfig.timeChoices,
            value: config.seconds,
            min: PracticeConfig.minSeconds,
            max: PracticeConfig.maxSeconds,
            label: _timeLabel,
            fieldLabel: 'Seconds',
            onChanged: (value) => config.seconds = value,
          ),
        if (mode == SessionMode.count)
          AmountPicker(
            presets: PracticeConfig.countChoices,
            value: config.questions,
            min: PracticeConfig.minQuestions,
            max: PracticeConfig.maxQuestions,
            label: (value) => '$value',
            fieldLabel: 'Questions',
            onChanged: (value) => config.questions = value,
          ),
        SwitchListTile(
          title: const Text('Next on correct answer'),
          subtitle: const Text('Move on as soon as the answer is right'),
          value: config.autoAdvance,
          onChanged: (value) => config.autoAdvance = value,
        ),
        SwitchListTile(
          title: const Text('Music'),
          value: config.music,
          onChanged: (value) => config.music = value,
        ),
        if (config.music)
          ListTile(
            title: const Text('Music track'),
            subtitle: Text(
              config.track < 0
                  ? 'All tracks'
                  : MusicService.tracks[config.track].name,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickTrack(context),
          ),
        SwitchListTile(
          title: const Text('Haptics'),
          value: config.haptics,
          onChanged: (value) => config.haptics = value,
        ),
      ],
    );
  }

  Future<void> _pickTrack(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ListenableBuilder(
          listenable: config,
          builder: (context, _) => ListView(
            shrinkWrap: true,
            children: [
              for (var i = -1; i < MusicService.tracks.length; i++)
                ListTile(
                  leading: Icon(
                    i == -1
                        ? Icons.shuffle_rounded
                        : Icons.music_note_rounded,
                  ),
                  title: Text(
                    i == -1 ? 'All tracks' : MusicService.tracks[i].name,
                  ),
                  trailing: config.track == i
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    config.track = i;
                    MusicService.play(track: i);
                  },
                ),
            ],
          ),
        ),
      ),
    );
    await MusicService.stop();
  }
}

String _timeLabel(int seconds) {
  if (seconds < 60) return '$seconds s';
  if (seconds % 60 == 0) return '${seconds ~/ 60} min';
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.icon,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final Level level;
  final IconData icon;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        selected ? scheme.secondaryContainer : scheme.surfaceContainerHigh;
    final foreground =
        selected ? scheme.onSecondaryContainer : scheme.onSurface;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xxs,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: scheme.primary),
                  const Spacer(),
                  if (count > 0)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 1,
                        ),
                        child: Text(
                          '$count',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: scheme.onPrimary),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                level.label,
                maxLines: 2,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
              Text(
                level.range,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
