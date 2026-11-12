import 'dart:async';

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:flutter/services.dart';
import 'package:chola/localization/localization.dart';
import 'package:chola/platform/music_service.dart';
import 'package:chola/practice/generator.dart';
import 'package:chola/practice/practice_config.dart';
import 'package:chola/practice/question.dart';
import 'package:chola/practice/stats_store.dart';
import 'package:chola/practice/topics.dart';
import 'package:chola/theme/app_spacing.dart';
import 'package:chola/ui/widgets/keypad.dart';
import 'package:chola/ui/widgets/layout.dart';
import 'package:chola/ui/widgets/math_text.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({
    required this.config,
    required this.stats,
    this.retry = const <Question>[],
    super.key,
  });

  final PracticeConfig config;
  final StatsStore stats;
  final List<Question> retry;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with WidgetsBindingObserver {
  static const Set<String> _appendKeys = <String>{
    ',', 'x', '(', 'i', '<', '>', '≤', '≥', '+', '^',
  };

  late final QuestionGenerator _generator =
      QuestionGenerator(widget.config, seed: widget.retry);
  final Stopwatch _clock = Stopwatch();
  final ValueNotifier<int> _remaining = ValueNotifier<int>(0);
  final List<Attempt> _attempts = <Attempt>[];
  late final List<String> _topics = widget.config.topics.toList()..sort();

  Timer? _ticker;
  late Question _question = _generator.next();
  var _input = '';
  var _started = false;
  var _finished = false;
  var _questionStart = 0;
  var _streak = 0;
  var _bestStreak = 0;
  var _lastAnswer = '';
  var _lastWork = const <String>[];

  PracticeConfig get _config => widget.config;
  bool get _isRetry => widget.retry.isNotEmpty;
  bool get _timed => !_isRetry && _config.mode == SessionMode.timed;
  bool get _counting => _isRetry || _config.mode == SessionMode.count;
  bool get _endless => !_isRetry && _config.mode == SessionMode.endless;
  int get _total => _isRetry ? widget.retry.length : _config.questions;
  List<String> get _keys => _question.answer.keys;
  bool get _appends => _keys.any(_appendKeys.contains);
  int get _limit =>
      _keys.any((k) => k != '-' && k != '.' && k != '/') ? 30 : 14;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remaining.value = _config.seconds * 1000;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    MusicService.stop();
    _remaining.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started || _finished) return;
    if (state == AppLifecycleState.resumed) {
      if (!_clock.isRunning) _clock.start();
      if (_config.music) MusicService.play(track: _config.track);
    } else {
      _clock.stop();
      MusicService.pause();
    }
  }

  void _toggleMusic() {
    final next = !_config.music;
    _config.music = next;
    if (_started && !_finished) {
      if (next) {
        MusicService.play(track: _config.track);
      } else {
        MusicService.pause();
      }
    }
    setState(() {});
  }

  void _start() {
    if (_started) return;
    setState(() => _started = true);
    _clock.start();
    if (_config.music) MusicService.play(track: _config.track);
    if (_timed) {
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final left = _config.seconds * 1000 - _clock.elapsedMilliseconds;
        _remaining.value = left < 0 ? 0 : left;
        if (left <= 0) _finish();
      });
    }
  }

  void _haptic(VoidCallback feedback) {
    if (_config.haptics) feedback();
  }

  void _press(String key) {
    if (_finished) return;
    if (!_started) {
      _start();
      return;
    }
    switch (key) {
      case 'back':
        if (_input.isNotEmpty) {
          setState(() => _input = _input.substring(0, _input.length - 1));
        }
      case 'skip':
        _submit();
      case 'enter':
        if (_input.isNotEmpty) _submit();
      case '-':
        if (_appends) {
          if (_input.length < _limit) setState(() => _input = '$_input-');
        } else {
          setState(() {
            _input = _input.startsWith('-') ? _input.substring(1) : '-$_input';
          });
        }
      case '.':
        final blocked = !_appends && _input.contains('.');
        if (!blocked && _input.length < _limit) {
          setState(() => _input = '$_input.');
        }
      default:
        if (_input.length < _limit) {
          setState(() => _input = '$_input$key');
        }
    }
    _haptic(HapticFeedback.selectionClick);
    if (_config.autoAdvance &&
        key != 'skip' &&
        key != 'enter' &&
        _question.answer.matches(_input)) {
      _submit();
    }
  }

  void _submit() {
    if (_finished) return;
    final given = _input;
    final asked = _question;
    final correct = asked.answer.matches(given);
    final now = _clock.elapsedMilliseconds;
    _attempts.add(
      Attempt(
        question: asked,
        given: given,
        correct: correct,
        millis: now - _questionStart,
      ),
    );
    if (correct) {
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      _lastAnswer = '';
      _lastWork = const <String>[];
      _haptic(HapticFeedback.lightImpact);
    } else {
      _streak = 0;
      _lastAnswer = asked.answer.shown;
      _lastWork = asked.work;
      _haptic(HapticFeedback.heavyImpact);
    }
    _generator.report(asked, correct: correct);
    if (_counting && _attempts.length >= _total) {
      _finish();
      return;
    }
    setState(() {
      _questionStart = now;
      _input = '';
      _question = _generator.next();
    });
  }

  void _finish() {
    if (_finished) return;
    _ticker?.cancel();
    _clock.stop();
    MusicService.stop();
    widget.stats.addSession(_attempts, _topics);
    if (mounted) setState(() => _finished = true);
  }

  void _again() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SessionScreen(config: _config, stats: widget.stats),
      ),
    );
  }

  void _retryMistakes(List<Question> questions) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SessionScreen(
          config: _config,
          stats: widget.stats,
          retry: questions,
        ),
      ),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _finished) return KeyEventResult.ignored;
    final logical = event.logicalKey;
    if (logical == LogicalKeyboardKey.backspace) {
      _press('back');
      return KeyEventResult.handled;
    }
    if (logical == LogicalKeyboardKey.enter ||
        logical == LogicalKeyboardKey.numpadEnter) {
      _press('enter');
      return KeyEventResult.handled;
    }
    final character = event.character;
    if (character == null || character.isEmpty) return KeyEventResult.ignored;
    final keys = _keys;
    if (character == ',' && keys.contains('.') && !keys.contains(',')) {
      _press('.');
      return KeyEventResult.handled;
    }
    if (RegExp(r'^[0-9]$').hasMatch(character) || keys.contains(character)) {
      _press(character);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: _finished ? _results(context) : _play(context),
        ),
      ),
    );
  }

  Widget _play(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final landscape = Layout.landscape(box.biggest);
        final edge = Layout.edge(box.maxWidth);
        final hasExtras = _keys.any((k) => k != '-' && k != '.' && k != '/');
        final Widget body;
        if (landscape) {
          final keypadWidth = (box.maxWidth * 0.4).clamp(300.0, 460.0).toDouble();
          body = Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(child: _card(context)),
              SizedBox(
                width: keypadWidth,
                child: Keypad(onKey: _press, keys: _keys),
              ),
            ],
          );
        } else {
          body = Column(
            spacing: AppSpacing.sm,
            children: [
              Expanded(flex: 5, child: _card(context)),
              Expanded(
                flex: hasExtras ? 7 : 6,
                child: Keypad(onKey: _press, keys: _keys),
              ),
            ],
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: landscape ? 1100 : 640),
            child: Padding(
              padding: EdgeInsets.fromLTRB(edge, AppSpacing.xxs, edge, edge),
              child: Column(
                spacing: AppSpacing.xxs,
                children: [
                  _header(context),
                  _progress(),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: _toggleMusic,
          icon: Icon(
            _config.music ? Icons.music_note_rounded : Icons.music_off_rounded,
          ),
        ),
        if (_config.music && _config.track < 0 && _started)
          const IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: MusicService.next,
            icon: Icon(Icons.skip_next_rounded),
          ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.lg,
              children: [
                _Counter(
                  label: 'Score',
                  value: '${_attempts.where((a) => a.correct).length}',
                ),
                _Counter(label: 'Streak', value: '$_streak'),
                if (_config.adaptive && !_isRetry)
                  _Counter(
                    label: 'Level',
                    value: '${_generator.difficultyFor(_question.topic)}',
                  ),
                if (_timed)
                  ValueListenableBuilder<int>(
                    valueListenable: _remaining,
                    builder: (context, left, _) => _Counter(
                      label: 'Time',
                      value: _clockText((left / 1000).ceil()),
                      urgent: _started && left <= 10000,
                    ),
                  ),
                if (_counting)
                  _Counter(
                    label: 'Question',
                    value: '${_attempts.length + 1} / $_total',
                  ),
                if (_endless)
                  TextButton(
                    onPressed: _attempts.isEmpty
                        ? () => Navigator.of(context).pop()
                        : _finish,
                    child: const Text('End'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _progress() {
    if (_timed) {
      final total = _config.seconds * 1000;
      return ValueListenableBuilder<int>(
        valueListenable: _remaining,
        builder: (context, left, _) => LinearProgressIndicator(
          value: left / total,
          minHeight: 5,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      );
    }
    if (_counting) {
      return LinearProgressIndicator(
        value: _attempts.length / _total,
        minHeight: 5,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      );
    }
    return const SizedBox(height: 5);
  }

  Widget _card(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: LayoutBuilder(
              builder: (context, box) {
                final h = box.maxHeight;
                final questionSize = (h * 0.15).clamp(22.0, 42.0).toDouble();
                final answerSize = (h * 0.10).clamp(18.0, 30.0).toDouble();
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    spacing: AppSpacing.sm,
                    children: [
                      _chips(theme),
                      if (_lastAnswer.isNotEmpty)
                        _feedback(theme, showWork: h >= 330),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: KeyedSubtree(
                                key: ValueKey<int>(_attempts.length),
                                child: _questionBody(theme, questionSize),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _answerBox(theme, answerSize),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (!_started)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _start(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Center(
                  child: Text(
                    'Tap to start',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: scheme.primary),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chips(ThemeData theme) {
    final scheme = theme.colorScheme;
    final label = Topics.byId(_question.topic)?.label ?? '';
    Widget chip(String text, Color background, Color foreground) => DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 3,
            ),
            child: Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(color: foreground),
            ),
          ),
        );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        spacing: AppSpacing.xxs,
        runSpacing: AppSpacing.xxs,
        children: [
          if (label.isNotEmpty)
            chip(label, scheme.secondaryContainer, scheme.onSecondaryContainer),
          if (_question.review)
            chip(
              'Review',
              scheme.tertiary.withValues(alpha: 0.2),
              scheme.tertiary,
            ),
        ],
      ),
    );
  }

  Widget _feedback(ThemeData theme, {required bool showWork}) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs * 2,
      ),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          Icon(Icons.close_rounded, color: scheme.error, size: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: MathText(
                    '= $_lastAnswer',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: scheme.error),
                  ),
                ),
                if (showWork)
                  for (final line in _lastWork)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: MathText(
                        line,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionBody(ThemeData theme, double size) {
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        if (_question.prompt.isNotEmpty)
          Text(
            _question.prompt,
            textAlign: TextAlign.center,
            style: _question.text.isEmpty
                ? theme.textTheme.titleLarge
                : theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        if (_question.text.isNotEmpty)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: MathText(
              _question.text,
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: size),
            ),
          ),
      ],
    );
  }

  Widget _answerBox(ThemeData theme, double size) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border(bottom: BorderSide(color: scheme.primary, width: 3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: MathText(
          _input.isEmpty ? ' ' : _input,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontSize: size, color: scheme.primary),
        ),
      ),
    );
  }

  Widget _results(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = _attempts.length;
    final correct = _attempts.where((a) => a.correct).length;
    final accuracy = total == 0 ? 0 : (correct * 100 / total).round();
    final totalMillis = _attempts.fold(0, (sum, a) => sum + a.millis);
    final average = total == 0 ? 0.0 : totalMillis / total / 1000;
    final mistakes = _attempts.where((a) => !a.correct).toList();
    final unique = <String, Question>{};
    for (final attempt in mistakes) {
      final q = attempt.question;
      unique.putIfAbsent('${q.prompt}|${q.text}', () => q);
    }
    final perTopic = <String, List<Attempt>>{};
    for (final attempt in _attempts) {
      perTopic
          .putIfAbsent(attempt.question.topic, () => <Attempt>[])
          .add(attempt);
    }

    final summary = <Widget>[
      Center(
        child: Text(
          _timed ? 'Time\'s up' : 'Finished',
          style: theme.textTheme.titleMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      Center(
        child: Text(
          '$correct',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontSize: 64, color: scheme.primary),
        ),
      ),
      Center(
        child: Text(
          '/ $total',
          style: theme.textTheme.titleMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        spacing: AppSpacing.sm,
        children: [
          Expanded(child: _StatTile(label: 'Accuracy', value: '$accuracy%')),
          Expanded(
            child: _StatTile(
              label: 'Average time',
              value: '${average.toStringAsFixed(1)} s',
            ),
          ),
          Expanded(child: _StatTile(label: 'Best streak', value: '$_bestStreak')),
        ],
      ),
    ];

    final details = <Widget>[
      for (final entry in perTopic.entries)
        _TopicRow(topic: entry.key, attempts: entry.value),
      if (mistakes.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Mistakes',
          style: theme.textTheme.labelLarge
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final attempt in mistakes.take(30)) _MistakeRow(attempt: attempt),
      ],
    ];

    Widget buttons() => Column(
          spacing: AppSpacing.sm,
          children: [
            if (unique.isNotEmpty)
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _retryMistakes(unique.values.toList()),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Retry mistakes'),
              ),
            Row(
              spacing: AppSpacing.sm,
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _again,
                    child: const Text('Again'),
                  ),
                ),
              ],
            ),
          ],
        );

    return LayoutBuilder(
      builder: (context, box) {
        final edge = Layout.edge(box.maxWidth);
        final split = Layout.split(box.maxWidth) || Layout.landscape(box.biggest);
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: split ? 1000 : 640),
            child: Padding(
              padding: EdgeInsets.all(edge),
              child: split
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.xl,
                      children: [
                        SizedBox(
                          width: 320,
                          child: Column(
                            children: [
                              Expanded(child: ListView(children: summary)),
                              const SizedBox(height: AppSpacing.md),
                              buttons(),
                            ],
                          ),
                        ),
                        Expanded(child: ListView(children: details)),
                      ],
                    )
                  : Column(
                      spacing: AppSpacing.md,
                      children: [
                        Expanded(
                          child: ListView(children: [...summary, ...details]),
                        ),
                        buttons(),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

String _clockText(int seconds) {
  if (seconds < 60) return '$seconds';
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _Counter extends StatelessWidget {
  const _Counter({required this.label, required this.value, this.urgent = false});

  final String label;
  final String value;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium
              ?.copyWith(color: urgent ? scheme.error : scheme.onSurface),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic, required this.attempts});

  final String topic;
  final List<Attempt> attempts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final correct = attempts.where((a) => a.correct).length;
    final millis = attempts.fold(0, (sum, a) => sum + a.millis);
    final average = millis / attempts.length / 1000;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Column(
        spacing: AppSpacing.xxs,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(child: Text(Topics.byId(topic)?.label ?? topic)),
              Text(
                '$correct / ${attempts.length}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${average.toStringAsFixed(1)} s',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: correct / attempts.length,
            minHeight: 4,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ],
      ),
    );
  }
}

class _MistakeRow extends StatelessWidget {
  const _MistakeRow({required this.attempt});

  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final question = attempt.question;
    final given = attempt.given.isEmpty ? '—' : attempt.given;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xxs,
        children: [
          if (question.prompt.isNotEmpty)
            Text(
              question.prompt,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.sm,
                  children: [
                    if (question.text.isNotEmpty)
                      MathText(question.text, style: theme.textTheme.titleMedium),
                    if (question.text.isNotEmpty)
                      Text('=', style: theme.textTheme.titleMedium),
                    MathText(
                      question.answer.shown,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: MathText(
              given,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          for (final line in question.work)
            Directionality(
              textDirection: TextDirection.ltr,
              child: MathText(
                line,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
