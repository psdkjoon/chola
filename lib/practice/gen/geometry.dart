import 'package:chola/math/answer.dart';
import 'package:chola/math/rational.dart';
import 'package:chola/practice/question.dart';

abstract class Geometry {
  static const List<(int, int, int)> _triples = <(int, int, int)>[
    (3, 4, 5),
    (5, 12, 13),
    (8, 15, 17),
    (7, 24, 25),
    (20, 21, 29),
    (9, 40, 41),
  ];

  static Question area(Gen g) {
    final span = g.by(9, 15, 25);
    final variants = g.d == 1
        ? const <int>[0, 1]
        : (g.d == 2 ? const <int>[0, 1, 2, 3] : const <int>[2, 3, 4, 5]);
    switch (g.pick(variants)) {
      case 0:
        final w = g.n(2, span);
        final h = g.n(2, span);
        return Question(
          topic: 'area',
          prompt: 'Area of a rectangle',
          text: 'w = $w, h = $h',
          answer: Ans.integer(w * h),
        );
      case 1:
        final w = g.n(2, span);
        final h = g.n(2, span);
        return Question(
          topic: 'area',
          prompt: 'Perimeter of a rectangle',
          text: 'w = $w, h = $h',
          answer: Ans.integer(2 * (w + h)),
        );
      case 2:
        final b = g.n(3, span);
        var h = g.n(3, span);
        if (b.isOdd && h.isOdd) h += 1;
        return Question(
          topic: 'area',
          prompt: 'Area of a triangle',
          text: 'b = $b, h = $h',
          answer: Ans.decimal(b * h / 2),
        );
      case 3:
        final a = g.n(3, span);
        final b = g.n(3, span);
        var h = g.n(3, span);
        if ((a + b).isOdd && h.isOdd) h += 1;
        return Question(
          topic: 'area',
          prompt: 'Area of a trapezoid',
          text: 'a = $a, b = $b, h = $h',
          answer: Ans.decimal((a + b) * h / 2),
        );
      case 4:
        final r = g.n(2, span);
        return Question(
          topic: 'area',
          prompt: 'Circumference of a circle, in terms of π',
          text: 'r = $r',
          answer: Ans.pi(Rational(2 * r)),
        );
      default:
        final r = g.n(2, span);
        return Question(
          topic: 'area',
          prompt: 'Area of a circle, in terms of π',
          text: 'r = $r',
          answer: Ans.pi(Rational(r * r)),
        );
    }
  }

  static Question pythagoras(Gen g) {
    final count = g.by(2, 4, 6);
    final (a, b, c) = _triples[g.n(0, count - 1)];
    final k = g.n(1, g.by(2, 3, 4));
    final swap = g.chance();
    final p = (swap ? b : a) * k;
    final q = (swap ? a : b) * k;
    final h = c * k;
    if (g.chance()) {
      return Question(
        topic: 'pyth',
        prompt: 'Find the hypotenuse c',
        text: 'a = $p, b = $q',
        answer: Ans.integer(h),
        work: <String>['c^2 = $p^2 + $q^2', 'c^2 = ${h * h}'],
      );
    }
    return Question(
      topic: 'pyth',
      prompt: 'Find the missing leg b',
      text: 'a = $p, c = $h',
      answer: Ans.integer(q),
      work: <String>['b^2 = $h^2 - $p^2', 'b^2 = ${q * q}'],
    );
  }

  static Question volume(Gen g) {
    final variants = g.d == 1
        ? const <int>[0, 1]
        : (g.d == 2 ? const <int>[0, 1, 2] : const <int>[2, 3, 4]);
    switch (g.pick(variants)) {
      case 0:
        final a = g.n(2, 9);
        return Question(
          topic: 'volume',
          prompt: 'Volume of a cube',
          text: 'a = $a',
          answer: Ans.integer(a * a * a),
        );
      case 1:
        final l = g.n(2, 9);
        final w = g.n(2, 9);
        final h = g.n(2, 9);
        return Question(
          topic: 'volume',
          prompt: 'Volume of a box',
          text: 'l = $l, w = $w, h = $h',
          answer: Ans.integer(l * w * h),
        );
      case 2:
        final r = g.n(2, 6);
        final h = g.n(2, 9);
        return Question(
          topic: 'volume',
          prompt: 'Volume of a cylinder, in terms of π',
          text: 'r = $r, h = $h',
          answer: Ans.pi(Rational(r * r * h)),
        );
      case 3:
        final r = 3 * g.n(1, 2);
        final h = g.n(2, 9);
        return Question(
          topic: 'volume',
          prompt: 'Volume of a cone, in terms of π',
          text: 'r = $r, h = $h',
          answer: Ans.pi(Rational(r * r * h ~/ 3)),
        );
      default:
        final k = g.n(1, 2);
        return Question(
          topic: 'volume',
          prompt: 'Volume of a sphere, in terms of π',
          text: 'r = ${3 * k}',
          answer: Ans.pi(Rational(36 * k * k * k)),
        );
    }
  }

  static Question angles(Gen g) {
    final variants = g.d == 1
        ? const <int>[0, 1, 2]
        : (g.d == 2 ? const <int>[0, 1, 2, 3] : const <int>[3, 4, 0]);
    switch (g.pick(variants)) {
      case 0:
        final a = g.n(20, 90);
        final b = g.n(20, 150 - a);
        return Question(
          topic: 'angles',
          prompt: 'Find the third angle of the triangle',
          text: '$a°, $b°',
          answer: Ans.integer(180 - a - b),
        );
      case 1:
        final a = g.n(1, 89);
        return Question(
          topic: 'angles',
          prompt: 'Find the complement of the angle',
          text: '$a°',
          answer: Ans.integer(90 - a),
        );
      case 2:
        final a = g.n(1, 179);
        return Question(
          topic: 'angles',
          prompt: 'Find the supplement of the angle',
          text: '$a°',
          answer: Ans.integer(180 - a),
        );
      case 3:
        final n = g.n(5, 12);
        return Question(
          topic: 'angles',
          prompt: 'Sum of the interior angles of a polygon with n sides',
          text: 'n = $n',
          answer: Ans.integer((n - 2) * 180),
        );
      default:
        final n = g.pick(const <int>[
          3, 4, 5, 6, 8, 9, 10, 12, 15, 18, 20, 24, 30, 36, 40, 45,
        ]);
        return Question(
          topic: 'angles',
          prompt: 'Each interior angle of a regular polygon with n sides',
          text: 'n = $n',
          answer: Ans.integer(180 - 360 ~/ n),
        );
    }
  }

  static Question coords(Gen g) {
    final x1 = g.n(-5, 5);
    final y1 = g.n(-5, 5);
    final variants = g.d == 1 ? const <int>[1] : const <int>[0, 1];
    if (g.pick(variants) == 0) {
      final (a, b, c) = g.pick(const <(int, int, int)>[
        (3, 4, 5),
        (6, 8, 10),
        (5, 12, 13),
        (9, 12, 15),
        (8, 15, 17),
      ]);
      final swap = g.chance();
      final dx = (swap ? b : a) * g.sign();
      final dy = (swap ? a : b) * g.sign();
      return Question(
        topic: 'coords',
        prompt: 'Find the distance between the points',
        text: '($x1, $y1), (${x1 + dx}, ${y1 + dy})',
        answer: Ans.integer(c),
        work: <String>['d^2 = ${dx * dx} + ${dy * dy}', 'd^2 = ${c * c}'],
      );
    }
    final half = g.d == 3;
    final dx = half ? g.nz(-7, 7) : 2 * g.nz(-4, 4);
    final dy = half ? g.nz(-7, 7) : 2 * g.nz(-4, 4);
    return Question(
      topic: 'coords',
      prompt: 'Find the midpoint, written as x, y',
      text: '($x1, $y1), (${x1 + dx}, ${y1 + dy})',
      answer: ListAnswer(
        <double>[x1 + dx / 2, y1 + dy / 2],
        decimal: half,
      ),
    );
  }

  static Question stats(Gen g) {
    final hi = g.by(15, 30, 60);
    final n = g.d == 1 ? 5 : (g.d == 2 ? g.pick(const <int>[5, 7]) : g.n(4, 8));
    final kinds = g.d == 1 ? const <int>[0, 3] : const <int>[0, 1, 2, 3];
    final kind = g.pick(kinds);
    final values = <int>[];
    if (kind == 0) {
      var s = 0;
      for (var i = 0; i < n - 1; i++) {
        final v = g.n(1, hi);
        values.add(v);
        s += v;
      }
      var last = (n - s % n) % n + n * g.n(0, hi ~/ n);
      if (last == 0) last = n;
      values.add(last);
    } else if (kind == 2) {
      final m = g.n(1, hi);
      final pool = <int>[
        for (var v = 1; v <= hi + n; v++)
          if (v != m) v,
      ]..shuffle(g.r);
      final copies = g.n(2, 3);
      for (var i = 0; i < copies; i++) {
        values.add(m);
      }
      values.addAll(pool.take(n - copies + 1));
    } else {
      for (var i = 0; i < n; i++) {
        values.add(g.n(1, hi));
      }
    }
    values.shuffle(g.r);
    final sorted = List<int>.of(values)..sort();
    final String prompt;
    final ValueAnswer answer;
    switch (kind) {
      case 0:
        prompt = 'Find the mean';
        answer = Ans.decimal(values.fold(0, (a, b) => a + b) / values.length);
      case 1:
        prompt = 'Find the median';
        final mid = sorted.length ~/ 2;
        answer = Ans.decimal(
          sorted.length.isOdd
              ? sorted[mid].toDouble()
              : (sorted[mid - 1] + sorted[mid]) / 2,
        );
      case 2:
        prompt = 'Find the mode';
        final counts = <int, int>{};
        for (final v in values) {
          counts[v] = (counts[v] ?? 0) + 1;
        }
        var best = values.first;
        for (final e in counts.entries) {
          if (e.value > counts[best]!) best = e.key;
        }
        answer = Ans.integer(best);
      default:
        prompt = 'Find the range';
        answer = Ans.integer(sorted.last - sorted.first);
    }
    return Question(
      topic: 'stats',
      prompt: prompt,
      text: values.join(', '),
      answer: answer,
    );
  }

  static int _choose(int n, int k) {
    var out = 1;
    for (var i = 1; i <= k; i++) {
      out = out * (n - k + i) ~/ i;
    }
    return out;
  }

  static Question probability(Gen g) {
    final variants = g.d == 1
        ? const <int>[0, 3]
        : (g.d == 2 ? const <int>[0, 1, 3] : const <int>[0, 1, 2]);
    switch (g.pick(variants)) {
      case 0:
        final r = g.n(1, 9);
        final b = g.n(1, 9);
        return Question(
          topic: 'prob',
          prompt:
              'A bag has $r red and $b blue marbles. What is the chance of picking red?',
          text: '',
          answer: Ans.rational(Rational(r, r + b)),
        );
      case 1:
        final s = g.n(2, 12);
        final ways = 6 - (s - 7).abs();
        return Question(
          topic: 'prob',
          prompt: 'Two dice are rolled. What is the chance that the sum is $s?',
          text: '',
          answer: Ans.rational(Rational(ways, 36)),
        );
      case 2:
        final n = g.n(2, 5);
        final k = g.n(0, n);
        return Question(
          topic: 'prob',
          prompt:
              'A coin is flipped $n times. What is the chance of exactly $k heads?',
          text: '',
          answer: Ans.rational(Rational(_choose(n, k), 1 << n)),
        );
      default:
        final k = g.n(1, 5);
        return Question(
          topic: 'prob',
          prompt:
              'A die is rolled. What is the chance of a number greater than $k?',
          text: '',
          answer: Ans.rational(Rational(6 - k, 6)),
        );
    }
  }
}
