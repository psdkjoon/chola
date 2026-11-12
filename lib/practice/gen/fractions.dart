import 'package:chola/math/answer.dart';
import 'package:chola/math/rational.dart';
import 'package:chola/practice/question.dart';

abstract class Fractions {
  static const String _lowest = 'Answer as a fraction in lowest terms';

  static int _den(Gen g) => g.d == 1
      ? g.pick(const <int>[2, 3, 4, 5, 6, 8, 10])
      : g.n(2, g.by(6, 12, 20));

  static String _f(Object a, Object b) => '\\frac{$a}{$b}';

  static int _coprime(Gen g, int q, int hi) {
    for (var i = 0; i < 60; i++) {
      final c = g.n(1, hi);
      if (Rational.gcd(c, q) == 1) return c;
    }
    return 1;
  }

  static Question simplify(Gen g) {
    final q = _den(g);
    final p = _coprime(g, q, g.d == 3 ? q * 2 : q - 1);
    final k = g.n(2, g.by(5, 9, 12));
    return Question(
      topic: 'frac_simplify',
      prompt: 'Simplify the fraction',
      text: _f(p * k, q * k),
      answer: Ans.rational(Rational(p, q)),
    );
  }

  static Question add(Gen g) {
    final b = g.d == 3 ? g.n(2, 12) : g.pick(const <int>[2, 3, 4, 5, 6]);
    int e;
    if (g.d == 1) {
      e = b;
    } else if (g.d == 2) {
      e = b * g.pick(const <int>[2, 3]);
    } else {
      e = g.n(2, 12);
    }
    var a = g.n(1, b - 1);
    var c = g.n(1, e - 1);
    var op = g.chance() ? '+' : '-';
    var bb = b;
    var ee = e;
    if (op == '-') {
      final cmp = (a * ee).compareTo(c * bb);
      if (cmp == 0) {
        op = '+';
      } else if (cmp < 0) {
        final ta = a;
        a = c;
        c = ta;
        final tb = bb;
        bb = ee;
        ee = tb;
      }
    }
    final plus = op == '+';
    final l = Rational.lcm(bb, ee);
    final x = a * (l ~/ bb);
    final y = c * (l ~/ ee);
    final r = plus
        ? Rational(a, bb) + Rational(c, ee)
        : Rational(a, bb) - Rational(c, ee);
    return Question(
      topic: 'frac_add',
      prompt: _lowest,
      text: '${_f(a, bb)} $op ${_f(c, ee)}',
      answer: Ans.rational(r),
      work: <String>[
        '${_f(x, l)} $op ${_f(y, l)}',
        '= ${_f(plus ? x + y : x - y, l)}',
      ],
    );
  }

  static Question multiply(Gen g) {
    final hi = g.by(6, 9, 12);
    final a = g.n(1, hi);
    final b = g.n(2, hi);
    final c = g.n(1, hi);
    final e = g.n(2, hi);
    final divide = g.d > 1 && g.chance();
    if (divide) {
      return Question(
        topic: 'frac_mul',
        prompt: _lowest,
        text: '${_f(a, b)} ÷ ${_f(c, e)}',
        answer: Ans.rational(Rational(a, b) / Rational(c, e)),
        work: <String>[
          '${_f(a, b)} × ${_f(e, c)}',
          '= ${_f('$a × $e', '$b × $c')}',
        ],
      );
    }
    return Question(
      topic: 'frac_mul',
      prompt: _lowest,
      text: '${_f(a, b)} × ${_f(c, e)}',
      answer: Ans.rational(Rational(a, b) * Rational(c, e)),
      work: <String>['= ${_f('$a × $c', '$b × $e')}'],
    );
  }

  static Question of(Gen g) {
    final q = _den(g);
    final p = g.n(1, q - 1);
    final k = g.n(1, g.by(6, 12, 20));
    return Question(
      topic: 'frac_of',
      prompt: 'Fraction of a number',
      text: '${_f(p, q)} × ${q * k}',
      answer: Ans.integer(p * k),
      work: <String>['${q * k} ÷ $q = $k', '$k × $p = ${p * k}'],
    );
  }

  static Question mixed(Gen g) {
    final q = g.n(2, g.by(5, 9, 12));
    final p = _coprime(g, q, q - 1);
    final w = g.n(1, g.by(4, 9, 15));
    final improper = w * q + p;
    if (g.chance()) {
      return Question(
        topic: 'mixed',
        prompt: 'Write as a mixed number',
        text: _f(improper, q),
        answer: ExactAnswer(
          '$w $p/$q',
          shownText: '$w${_f(p, q)}',
          symbols: const <String>['/', ' '],
        ),
        work: <String>['$improper ÷ $q = $w  (+ $p)'],
      );
    }
    return Question(
      topic: 'mixed',
      prompt: 'Write as an improper fraction',
      text: '$w${_f(p, q)}',
      answer: Ans.rational(Rational(improper, q)),
      work: <String>['$w × $q + $p = $improper'],
    );
  }

  static Question compare(Gen g) {
    final b = _den(g);
    var e = _den(g);
    final a = g.n(1, b - 1);
    var c = g.n(1, e - 1);
    if (g.d > 1 && g.chance(5)) {
      final k = g.n(2, 4);
      c = a * k;
      e = b * k;
    }
    final cmp = (a * e).compareTo(c * b);
    final sign = cmp < 0 ? '<' : (cmp > 0 ? '>' : '=');
    return Question(
      topic: 'frac_compare',
      prompt: 'Which sign goes in the middle?',
      text: '${_f(a, b)}  ?  ${_f(c, e)}',
      answer: ExactAnswer(sign, symbols: const <String>['<', '>', '=']),
      work: <String>['$a × $e = ${a * e}', '$c × $b = ${c * b}'],
    );
  }

  static Question decimals(Gen g) {
    if (g.chance()) {
      final den = g.pick(g.d == 1
          ? const <int>[2, 4, 5, 10]
          : (g.d == 2
              ? const <int>[2, 4, 5, 8, 10, 20, 25]
              : const <int>[8, 16, 20, 25, 40, 50]));
      final p = g.n(1, g.d == 3 ? den * 2 : den - 1);
      return Question(
        topic: 'frac_decimal',
        prompt: 'Write as a decimal',
        text: _f(p, den),
        answer: Ans.decimal(p / den),
      );
    }
    final scale = g.d == 1 ? 10 : 100;
    var m = g.n(1, g.d == 3 ? 375 : (scale == 10 ? 9 : 99));
    if (m % 10 == 0) m += 1;
    final r = Rational(m, scale);
    return Question(
      topic: 'frac_decimal',
      prompt: 'Write as a fraction in lowest terms',
      text: Fmt.number(m / scale),
      answer: Ans.rational(r),
    );
  }
}
