import 'dart:math';

import 'package:chola/core/diagnostics.dart';
import 'package:chola/practice/practice_config.dart';
import 'package:chola/practice/question.dart';
import 'package:chola/practice/topics.dart';

class _Due {
  const _Due(this.question, this.at);

  final Question question;
  final int at;
}

class QuestionGenerator {
  QuestionGenerator(this.config, {List<Question> seed = const <Question>[]})
      : _random = Random(),
        _seed = List<Question>.of(seed);

  final PracticeConfig config;
  final Random _random;
  final List<Question> _seed;

  final Map<String, int> _levels = <String, int>{};
  final Map<String, int> _streaks = <String, int>{};
  final Map<String, int> _misses = <String, int>{};
  final List<_Due> _retry = <_Due>[];
  final List<String> _recent = <String>[];
  int _asked = 0;

  int difficultyFor(String topic) => _levels[topic] ?? config.difficulty;

  List<Topic> get _pool {
    final out = <Topic>[
      for (final id in config.topics)
        if (Topics.byId(id) != null) Topics.byId(id)!,
    ];
    if (out.isEmpty) out.add(Topics.byId('add')!);
    return out;
  }

  Question next() {
    if (_seed.isNotEmpty) {
      _asked++;
      return _seed.removeAt(0).asReview();
    }
    final due = _retry.indexWhere((item) => item.at <= _asked);
    if (due >= 0) {
      final item = _retry.removeAt(due);
      _asked++;
      return item.question;
    }
    final pool = _pool;
    Question? fallback;
    for (var attempt = 0; attempt < 30; attempt++) {
      final topic = pool[_random.nextInt(pool.length)];
      final Question question;
      try {
        question = topic.make(Gen(config, difficultyFor(topic.id), _random));
      } on Object catch (error, stack) {
        Diagnostics.record(error, stack, source: topic.id);
        continue;
      }
      final key = '${question.prompt}|${question.text}';
      fallback = question;
      if (!_recent.contains(key) || attempt >= 8) {
        _remember(key);
        _asked++;
        return question;
      }
    }
    _asked++;
    final held = fallback;
    if (held != null) return held;
    return Topics.byId('add')!.make(Gen(config, 2, _random));
  }

  void _remember(String key) {
    _recent.add(key);
    if (_recent.length > 8) _recent.removeAt(0);
  }

  void report(Question question, {required bool correct}) {
    final id = question.topic;
    if (!correct && !question.review && _seed.isEmpty) {
      _retry.add(_Due(question.asReview(), _asked + 3 + _random.nextInt(3)));
    }
    if (!config.adaptive) return;
    final level = difficultyFor(id);
    if (correct) {
      final streak = (_streaks[id] ?? 0) + 1;
      _misses[id] = 0;
      if (streak >= 4 && level < 3) {
        _levels[id] = level + 1;
        _streaks[id] = 0;
      } else {
        _streaks[id] = streak;
      }
    } else {
      final misses = (_misses[id] ?? 0) + 1;
      _streaks[id] = 0;
      if (misses >= 2 && level > 1) {
        _levels[id] = level - 1;
        _misses[id] = 0;
      } else {
        _misses[id] = misses;
      }
    }
  }
}
