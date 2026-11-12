import 'package:flutter/foundation.dart';
import 'package:chola/core/kv_store.dart';
import 'package:chola/practice/question.dart';

class OpStat {
  OpStat(this.solved, this.correct, this.millis);

  int solved;
  int correct;
  int millis;

  double get accuracy => solved == 0 ? 0 : correct / solved;
  double get averageSeconds => solved == 0 ? 0 : millis / solved / 1000;
}

class SessionRecord {
  const SessionRecord({
    required this.time,
    required this.correct,
    required this.total,
    required this.averageMillis,
    required this.topics,
  });

  final int time;
  final int correct;
  final int total;
  final int averageMillis;
  final List<String> topics;

  String get line =>
      '$time,$correct,$total,$averageMillis,${topics.join('+')}';

  static SessionRecord? parse(String line) {
    final parts = line.split(',');
    if (parts.length != 5) return null;
    final time = int.tryParse(parts[0]);
    final correct = int.tryParse(parts[1]);
    final total = int.tryParse(parts[2]);
    final average = int.tryParse(parts[3]);
    if (time == null || correct == null || total == null || average == null) {
      return null;
    }
    return SessionRecord(
      time: time,
      correct: correct,
      total: total,
      averageMillis: average,
      topics: parts[4].split('+'),
    );
  }
}

class StatsStore extends ChangeNotifier {
  StatsStore._(this._store) {
    for (final line in _store.getStringList('s.ops') ?? const <String>[]) {
      final parts = line.split(',');
      if (parts.length != 4) continue;
      final solved = int.tryParse(parts[1]);
      final correct = int.tryParse(parts[2]);
      final millis = int.tryParse(parts[3]);
      if (solved == null || correct == null || millis == null) continue;
      _ops[parts[0]] = OpStat(solved, correct, millis);
    }
    for (final line in _store.getStringList('s.days') ?? const <String>[]) {
      final parts = line.split(',');
      if (parts.length != 2) continue;
      final key = int.tryParse(parts[0]);
      final count = int.tryParse(parts[1]);
      if (key == null || count == null) continue;
      _days[key] = count;
    }
    for (final line in _store.getStringList('s.sessions') ?? const <String>[]) {
      final record = SessionRecord.parse(line);
      if (record != null) _sessions.add(record);
    }
  }

  static StatsStore load(KvStore store) => StatsStore._(store);

  static const int _maxSessions = 30;

  final KvStore _store;
  final Map<String, OpStat> _ops = <String, OpStat>{};
  final List<SessionRecord> _sessions = <SessionRecord>[];
  final Map<int, int> _days = <int, int>{};

  static const int _maxDays = 400;

  static int _dayKey(DateTime t) => t.year * 10000 + t.month * 100 + t.day;

  int get todayCount => _days[_dayKey(DateTime.now())] ?? 0;

  int get dayStreak {
    var day = DateTime.now();
    if ((_days[_dayKey(day)] ?? 0) == 0) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while ((_days[_dayKey(day)] ?? 0) > 0) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  int get bestDayStreak {
    final keys = <int>[
      for (final entry in _days.entries)
        if (entry.value > 0) entry.key,
    ]..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final key in keys) {
      final day = DateTime.utc(key ~/ 10000, key ~/ 100 % 100, key % 100);
      run = previous != null && day.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > best) best = run;
      previous = day;
    }
    return best;
  }

  int get topicsTried => _ops.values.where((s) => s.solved > 0).length;

  List<SessionRecord> get sessions => List.unmodifiable(_sessions);

  OpStat? statFor(String topic) => _ops[topic];

  int get totalSolved => _ops.values.fold(0, (sum, s) => sum + s.solved);
  int get totalCorrect => _ops.values.fold(0, (sum, s) => sum + s.correct);
  int get totalMillis => _ops.values.fold(0, (sum, s) => sum + s.millis);

  bool get isEmpty => totalSolved == 0;

  void addSession(List<Attempt> attempts, List<String> topics) {
    if (attempts.isEmpty) return;
    var correct = 0;
    var millis = 0;
    for (final attempt in attempts) {
      final stat = _ops.putIfAbsent(
        attempt.question.topic,
        () => OpStat(0, 0, 0),
      );
      stat.solved++;
      stat.millis += attempt.millis;
      millis += attempt.millis;
      if (attempt.correct) {
        stat.correct++;
        correct++;
      }
    }
    final today = _dayKey(DateTime.now());
    _days[today] = (_days[today] ?? 0) + attempts.length;
    if (_days.length > _maxDays) {
      final keys = _days.keys.toList()..sort();
      for (final key in keys.take(_days.length - _maxDays)) {
        _days.remove(key);
      }
    }
    _sessions.insert(
      0,
      SessionRecord(
        time: DateTime.now().millisecondsSinceEpoch,
        correct: correct,
        total: attempts.length,
        averageMillis: millis ~/ attempts.length,
        topics: topics,
      ),
    );
    if (_sessions.length > _maxSessions) {
      _sessions.removeRange(_maxSessions, _sessions.length);
    }
    _save();
    notifyListeners();
  }

  void reset() {
    _ops.clear();
    _sessions.clear();
    _days.clear();
    _save();
    notifyListeners();
  }

  void _save() {
    _store.setStringList('s.ops', [
      for (final entry in _ops.entries)
        '${entry.key},${entry.value.solved},${entry.value.correct},${entry.value.millis}',
    ]);
    _store.setStringList('s.days', [
      for (final entry in _days.entries) '${entry.key},${entry.value}',
    ]);
    _store.setStringList('s.sessions', [
      for (final record in _sessions) record.line,
    ]);
  }
}
