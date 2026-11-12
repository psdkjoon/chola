import 'package:flutter/foundation.dart';
import 'package:chola/core/kv_store.dart';

enum NumberKind { whole, decimal, mixed }

enum SessionMode { timed, count, endless }

class PracticeConfig extends ChangeNotifier {
  PracticeConfig._(this._store) {
    final names =
        _store.getStringList('p.topics') ?? _store.getStringList('p.ops');
    _topics.addAll(names ?? const ['add', 'multiply']);
    _level = _store.getString('p.level') ?? _level;
    _difficulty = _clamp(_store.getInt('p.difficulty'), 1, 3, _difficulty);
    _adaptive = _store.getBool('p.adaptive') ?? _adaptive;
    _dailyGoal = _clamp(_store.getInt('p.goal'), 5, 500, _dailyGoal);
    _track = _clamp(_store.getInt('p.track'), -1, maxTrack, _track);
    _kind = _named(NumberKind.values, _store.getString('p.kind'), _kind);
    _mode = _named(SessionMode.values, _store.getString('p.mode'), _mode);
    _leftDigits = _clamp(_store.getInt('p.left'), 1, 6, _leftDigits);
    _rightDigits = _clamp(_store.getInt('p.right'), 1, 6, _rightDigits);
    _decimalPlaces = _clamp(_store.getInt('p.places'), 1, 3, _decimalPlaces);
    _answerPlaces = _clamp(_store.getInt('p.answer'), 0, 6, _answerPlaces);
    _seconds = _clamp(_store.getInt('p.seconds'), minSeconds, maxSeconds, _seconds);
    _questions = _clamp(
      _store.getInt('p.questions'),
      minQuestions,
      maxQuestions,
      _questions,
    );
    _music = _store.getBool('p.music') ?? _music;
    _allowNegative = _store.getBool('p.negative') ?? _allowNegative;
    _autoAdvance = _store.getBool('p.auto') ?? _autoAdvance;
    _haptics = _store.getBool('p.haptics') ?? _haptics;
  }

  static PracticeConfig load(KvStore store) => PracticeConfig._(store);

  static const List<int> timeChoices = [30, 60, 120, 300];
  static const List<int> countChoices = [10, 20, 50, 100];
  static const int maxTrack = 17;
  static const int minSeconds = 5;
  static const int maxSeconds = 3600;
  static const int minQuestions = 1;
  static const int maxQuestions = 9999;

  static T _named<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static int _clamp(int? value, int low, int high, int fallback) {
    if (value == null) return fallback;
    return _bound(value, low, high);
  }

  static int _bound(int value, int low, int high) {
    if (value < low) return low;
    if (value > high) return high;
    return value;
  }

  final KvStore _store;
  final Set<String> _topics = <String>{};

  String _level = 'elementary';
  int _difficulty = 2;
  bool _adaptive = true;
  int _dailyGoal = 20;
  int _track = -1;
  NumberKind _kind = NumberKind.whole;
  SessionMode _mode = SessionMode.timed;
  int _leftDigits = 2;
  int _rightDigits = 2;
  int _decimalPlaces = 1;
  int _answerPlaces = 3;
  int _seconds = 60;
  int _questions = 20;
  bool _allowNegative = false;
  bool _autoAdvance = true;
  bool _haptics = true;
  bool _music = true;

  Set<String> get topics => Set<String>.unmodifiable(_topics);
  String get level => _level;
  int get difficulty => _difficulty;
  bool get adaptive => _adaptive;
  int get dailyGoal => _dailyGoal;
  int get track => _track;

  NumberKind get kind => _kind;
  SessionMode get mode => _mode;
  int get leftDigits => _leftDigits;
  int get rightDigits => _rightDigits;
  int get decimalPlaces => _decimalPlaces;
  int get answerPlaces => _answerPlaces;
  int get seconds => _seconds;
  int get questions => _questions;
  bool get allowNegative => _allowNegative;
  bool get autoAdvance => _autoAdvance;
  bool get haptics => _haptics;
  bool get music => _music;

  bool hasTopic(String id) => _topics.contains(id);

  void toggleTopic(String id) {
    if (_topics.contains(id)) {
      _topics.remove(id);
    } else {
      _topics.add(id);
    }
    _saveTopics();
  }

  void setTopics(Iterable<String> ids, {required bool selected}) {
    if (selected) {
      _topics.addAll(ids);
    } else {
      _topics.removeAll(ids.toSet());
    }
    _saveTopics();
  }

  void replaceTopics(Iterable<String> ids) {
    if (ids.isEmpty) return;
    _topics
      ..clear()
      ..addAll(ids);
    _saveTopics();
  }

  void _saveTopics() {
    _store.setStringList('p.topics', _topics.toList()..sort());
    notifyListeners();
  }

  set level(String value) => _apply(() => _level = value, 'p.level', value);

  set difficulty(int value) {
    final bounded = _bound(value, 1, 3);
    _apply(() => _difficulty = bounded, 'p.difficulty', bounded);
  }

  set dailyGoal(int value) {
    final bounded = _bound(value, 5, 500);
    _apply(() => _dailyGoal = bounded, 'p.goal', bounded);
  }

  set adaptive(bool value) =>
      _apply(() => _adaptive = value, 'p.adaptive', value);

  set track(int value) {
    final bounded = _bound(value, -1, maxTrack);
    _apply(() => _track = bounded, 'p.track', bounded);
  }

  set kind(NumberKind value) =>
      _apply(() => _kind = value, 'p.kind', value.name);

  set mode(SessionMode value) =>
      _apply(() => _mode = value, 'p.mode', value.name);

  set leftDigits(int value) {
    final bounded = _bound(value, 1, 6);
    _apply(() => _leftDigits = bounded, 'p.left', bounded);
  }

  set rightDigits(int value) {
    final bounded = _bound(value, 1, 6);
    _apply(() => _rightDigits = bounded, 'p.right', bounded);
  }

  set decimalPlaces(int value) {
    final bounded = _bound(value, 1, 3);
    _apply(() => _decimalPlaces = bounded, 'p.places', bounded);
  }

  set answerPlaces(int value) {
    final bounded = _bound(value, 0, 6);
    _apply(() => _answerPlaces = bounded, 'p.answer', bounded);
  }

  set seconds(int value) {
    final bounded = _bound(value, minSeconds, maxSeconds);
    _apply(() => _seconds = bounded, 'p.seconds', bounded);
  }

  set questions(int value) {
    final bounded = _bound(value, minQuestions, maxQuestions);
    _apply(() => _questions = bounded, 'p.questions', bounded);
  }

  set allowNegative(bool value) =>
      _apply(() => _allowNegative = value, 'p.negative', value);

  set autoAdvance(bool value) =>
      _apply(() => _autoAdvance = value, 'p.auto', value);

  set haptics(bool value) =>
      _apply(() => _haptics = value, 'p.haptics', value);

  set music(bool value) => _apply(() => _music = value, 'p.music', value);

  void _apply(VoidCallback change, String key, Object value) {
    change();
    switch (value) {
      case final bool v:
        _store.setBool(key, v);
      case final int v:
        _store.setInt(key, v);
      case final String v:
        _store.setString(key, v);
    }
    notifyListeners();
  }
}
