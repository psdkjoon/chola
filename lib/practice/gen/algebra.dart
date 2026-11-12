import 'package:chola/math/answer.dart';
import 'package:chola/math/rational.dart';
import 'package:chola/practice/question.dart';

abstract class Algebra {
  static const Map<String, String> _flip = <String, String>{
    '<': '>',
    '>': '<',
    '≤': '≥',
    '≥': '≤',
  };

  static int _pow(int base, int e) {
    var out = 1;
    for (var i = 0; i < e; i++) {
      out *= base;
    }
    return out;
  }

  static String _f(Object a, Object b) => '\\frac{$a}{$b}';

  static int _big(Gen g, int lo, int hi) {
    var v = 0;
    while (v.abs() < 2) {
      v = g.n(lo, hi);
    }
    return v;
  }

  static Question integers(Gen g) {
    final hi = g.by(10, 20, 50);
    final op = g.pick(const <String>['+', '-', '×', '÷']);
    final String text;
    final int v;
    switch (op) {
      case '+':
        final a = g.nz(-hi, hi);
        final b = g.nz(-hi, hi);
        text = '$a + ${Fmt.paren(b)}';
        v = a + b;
      case '-':
        final a = g.nz(-hi, hi);
        final b = g.nz(-hi, hi);
        text = '$a - ${Fmt.paren(b)}';
        v = a - b;
      case '×':
        final a = g.nz(-12, 12);
        final b = g.nz(-12, 12);
        text = '${Fmt.paren(a)} × ${Fmt.paren(b)}';
        v = a * b;
      default:
        final b = g.nz(-9, 9);
        final q = g.nz(-12, 12);
        text = '${Fmt.paren(b * q)} ÷ ${Fmt.paren(b)}';
        v = q;
    }
    return Question(
      topic: 'integers',
      text: text,
      answer: Ans.integer(v, negative: true),
    );
  }

  static Question powers(Gen g) {
    final variants = g.d == 1
        ? const <int>[0, 1]
        : (g.d == 2 ? const <int>[0, 1, 2, 3] : const <int>[2, 3, 4, 5, 6]);
    final t = g.pick(variants);
    switch (t) {
      case 0:
        final a = g.n(2, 9);
        final n = g.n(2, 3);
        return _power('$a^$n', Ans.integer(_pow(a, n)));
      case 1:
        final a = g.n(2, 5);
        final n = g.n(2, 4);
        return _power('(-$a)^$n', Ans.integer(_pow(-a, n), negative: true));
      case 2:
        final a = g.pick(const <int>[2, 3, 5]);
        final m = g.n(1, 4);
        final n = g.n(1, 4);
        return _power(
          '$a^$m × $a^$n',
          Ans.integer(_pow(a, m + n)),
        );
      case 3:
        final a = g.n(2, 5);
        final m = g.n(3, 6);
        final n = g.n(1, m - 1);
        return _power(
          '$a^$m ÷ $a^$n',
          Ans.integer(_pow(a, m - n)),
        );
      case 4:
        final a = g.n(2, 5);
        if (g.chance()) {
          return _power('$a^0', Ans.integer(1));
        }
        final n = g.n(1, 3);
        return _power('$a^-$n', Ans.rational(Rational(1, _pow(a, n))));
      case 5:
        if (g.chance()) {
          final k = g.n(2, 20);
          return _power('\\sqrt{${k * k}}', Ans.integer(k));
        }
        final k = g.n(2, 10);
        return _power('\\sqrt[3]{${k * k * k}}', Ans.integer(k));
      default:
        final q = g.n(2, 6);
        var p = 1;
        for (var i = 0; i < 30; i++) {
          final c = g.n(1, q - 1);
          if (Rational.gcd(c, q) == 1) {
            p = c;
            break;
          }
        }
        final n = g.n(2, 3);
        return _power(
          '(${_f(p, q)})^$n',
          Ans.rational(Rational(_pow(p, n), _pow(q, n))),
        );
    }
  }

  static Question _power(String text, ValueAnswer answer) => Question(
        topic: 'powers',
        prompt: 'Evaluate',
        text: text,
        answer: answer,
      );

  static Question ratio(Gen g) {
    final k = g.n(2, g.by(5, 9, 12));
    if (g.chance()) {
      var p = g.n(1, 9);
      var q = g.n(1, 9);
      while (p == q || Rational.gcd(p, q) != 1) {
        p = g.n(1, 9);
        q = g.n(1, 9);
      }
      return Question(
        topic: 'ratio',
        prompt: 'Simplify the ratio',
        text: '${p * k} : ${q * k}',
        answer: ExactAnswer('$p:$q', symbols: const <String>[':']),
      );
    }
    final c = g.n(1, 9);
    final e = g.n(2, 9);
    if (g.chance()) {
      return Question(
        topic: 'ratio',
        prompt: 'Solve for x',
        text: '${_f('x', e * k)} = ${_f(c, e)}',
        answer: Ans.integer(c * k),
        work: <String>['x = ${c * k}'],
      );
    }
    return Question(
      topic: 'ratio',
      prompt: 'Solve for x',
      text: '${_f(c * k, 'x')} = ${_f(c, e)}',
      answer: Ans.integer(e * k),
      work: <String>['x = ${e * k}'],
    );
  }

  static Question percentProblems(Gen g) {
    final unit = g.d == 3 ? 10 : 20;
    final p = g.pick(g.d == 3
        ? const <int>[12, 15, 35, 45, 8, 25]
        : const <int>[5, 10, 15, 20, 25, 30, 40, 50, 60, 75]);
    final base = unit * g.n(1, g.by(5, 10, 25));
    final part = base * p / 100;
    final variants = g.d == 1 ? const <int>[0, 1] : const <int>[0, 1, 2, 3];
    switch (g.pick(variants)) {
      case 0:
        return Question(
          topic: 'percentp',
          prompt: 'Increase the number by the percent',
          text: '$base, +$p%',
          answer: Ans.decimal(base + part),
        );
      case 1:
        return Question(
          topic: 'percentp',
          prompt: 'Decrease the number by the percent',
          text: '$base, -$p%',
          answer: Ans.decimal(base - part),
        );
      case 2:
        return Question(
          topic: 'percentp',
          prompt: 'What percent is the first number of the second?',
          text: '${Fmt.number(part)}, $base',
          answer: Ans.decimal(p.toDouble()),
        );
      default:
        return Question(
          topic: 'percentp',
          prompt: 'Find the whole',
          text: '${Fmt.number(part)} = $p% × ?',
          answer: Ans.decimal(base.toDouble()),
        );
    }
  }

  static Question evaluate(Gen g) {
    final List<int> c;
    final int x;
    if (g.d == 1) {
      c = <int>[g.n(-9, 9), g.n(2, 9)];
      x = g.n(1, 9);
    } else if (g.d == 2) {
      c = <int>[g.n(-9, 9), g.n(-6, 6), g.n(1, 4)];
      x = g.n(-5, 5);
    } else {
      c = <int>[g.n(-9, 9), g.n(-6, 6), g.n(-4, 4), g.nz(-3, 3)];
      x = g.n(-3, 3);
    }
    return Question(
      topic: 'evaluate',
      prompt: 'Evaluate the expression',
      text: '${Fmt.ints(c)}\nx = $x',
      answer: Ans.integer(Fmt.evalAt(c, x), negative: true),
    );
  }

  static String _sum(List<(int, int)> ts) {
    final b = StringBuffer();
    for (var i = 0; i < ts.length; i++) {
      final (c, k) = ts[i];
      final mag = c.abs();
      final String body;
      if (k == 0) {
        body = '$mag';
      } else {
        final v = k == 1 ? 'x' : 'x^$k';
        body = mag == 1 ? v : '$mag$v';
      }
      if (i == 0) {
        b.write(c < 0 ? '-$body' : body);
      } else {
        b.write(c < 0 ? ' - $body' : ' + $body');
      }
    }
    return b.toString();
  }

  static Question simplify(Gen g) {
    if (g.d == 1) {
      int a1 = 0, a2 = 0, b1 = 0, b2 = 0;
      while (a1 + a2 == 0 || b1 + b2 == 0) {
        a1 = g.nz(-9, 9);
        a2 = g.nz(-9, 9);
        b1 = g.nz(-9, 9);
        b2 = g.nz(-9, 9);
      }
      final ts = <(int, int)>[(a1, 1), (b1, 0), (a2, 1), (b2, 0)]
        ..shuffle(g.r);
      return Question(
        topic: 'terms',
        prompt: 'Simplify the expression',
        text: _sum(ts),
        answer: Ans.poly(<int>[b1 + b2, a1 + a2]),
      );
    }
    final a = _big(g, -6, 6);
    final b = g.nz(-9, 9);
    if (g.d == 2) {
      final c = g.nz(-9, 9);
      return Question(
        topic: 'terms',
        prompt: 'Expand and simplify',
        text: '$a(x ${Fmt.signed(b)}) ${Fmt.signed(c)}',
        answer: Ans.poly(<int>[a * b + c, a]),
      );
    }
    var c = -a;
    var e = 0;
    while (a + c == 0 || a * b + c * e == 0) {
      c = _big(g, -6, 6);
      e = g.nz(-9, 9);
    }
    final second = c < 0
        ? '- ${-c}(x ${Fmt.signed(e)})'
        : '+ $c(x ${Fmt.signed(e)})';
    return Question(
      topic: 'terms',
      prompt: 'Expand and simplify',
      text: '$a(x ${Fmt.signed(b)}) $second',
      answer: Ans.poly(<int>[a * b + c * e, a + c]),
    );
  }

  static Question eq1(Gen g) {
    const prompt = 'Solve for x';
    if (g.d == 1) {
      final a = g.n(2, 9);
      final x = g.n(1, 12);
      switch (g.n(0, 3)) {
        case 0:
          return Question(
            topic: 'eq1',
            prompt: prompt,
            text: 'x + $a = ${x + a}',
            answer: Ans.integer(x),
            work: <String>['x = ${x + a} - $a'],
          );
        case 1:
          return Question(
            topic: 'eq1',
            prompt: prompt,
            text: 'x - $a = $x',
            answer: Ans.integer(x + a),
            work: <String>['x = $x + $a'],
          );
        case 2:
          return Question(
            topic: 'eq1',
            prompt: prompt,
            text: '${a}x = ${a * x}',
            answer: Ans.integer(x),
            work: <String>['x = ${a * x} ÷ $a'],
          );
        default:
          return Question(
            topic: 'eq1',
            prompt: prompt,
            text: '${_f('x', a)} = $x',
            answer: Ans.integer(a * x),
            work: <String>['x = $x × $a'],
          );
      }
    }
    if (g.d == 2) {
      final a = _big(g, -9, 9);
      final x = g.nz(-9, 9);
      final b = g.nz(-9, 9);
      final c = a * x + b;
      return Question(
        topic: 'eq1',
        prompt: prompt,
        text: '${Fmt.ints(<int>[b, a])} = $c',
        answer: Ans.integer(x, negative: true),
        work: <String>['${Fmt.ints(<int>[0, a])} = ${c - b}', 'x = $x'],
      );
    }
    final a = g.n(2, 9);
    var p = g.nz(-9, 9);
    while (Rational.gcd(p, a) != 1) {
      p = g.nz(-9, 9);
    }
    final b = g.nz(-9, 9);
    final r = Rational(p, a);
    return Question(
      topic: 'eq1',
      prompt: prompt,
      text: '${Fmt.ints(<int>[b, a])} = ${p + b}',
      answer: Ans.rational(r, negative: true, reduced: false),
      work: <String>['${a}x = $p', 'x = ${r.markup}'],
    );
  }

  static Question eq2(Gen g) {
    const prompt = 'Solve for x';
    final variants = g.d == 1
        ? const <int>[1, 2]
        : (g.d == 2 ? const <int>[0, 1, 2] : const <int>[0, 3, 2]);
    final x = g.nz(-9, 9);
    switch (g.pick(variants)) {
      case 0:
        final span = g.by(6, 9, 12);
        final a = g.nz(-span, span);
        var c = g.nz(-span, span);
        while (c == a) {
          c = g.nz(-span, span);
        }
        final b = g.nz(-9, 9);
        final e = a * x + b - c * x;
        return Question(
          topic: 'eq2',
          prompt: prompt,
          text: '${Fmt.ints(<int>[b, a])} = ${Fmt.ints(<int>[e, c])}',
          answer: Ans.integer(x, negative: true),
          work: <String>[
            '${Fmt.ints(<int>[0, a - c])} = ${e - b}',
            'x = $x',
          ],
        );
      case 1:
        final a = _big(g, g.d == 3 ? -9 : 2, 9);
        final b = g.nz(-9, 9);
        final c = a * (x + b);
        return Question(
          topic: 'eq2',
          prompt: prompt,
          text: '$a(x ${Fmt.signed(b)}) = $c',
          answer: Ans.integer(x, negative: true),
          work: <String>['x ${Fmt.signed(b)} = ${x + b}', 'x = $x'],
        );
      case 2:
        final a = g.n(2, 9);
        final b = g.nz(-9, 9);
        final k = g.nz(-9, 9);
        return Question(
          topic: 'eq2',
          prompt: prompt,
          text: '${_f('x', a)} ${Fmt.signed(b)} = ${k + b}',
          answer: Ans.integer(a * k, negative: true),
          work: <String>['${_f('x', a)} = $k', 'x = ${a * k}'],
        );
      default:
        final a = g.n(2, 9);
        final b = g.nz(-9, 9);
        final c = g.nz(-9, 9);
        return Question(
          topic: 'eq2',
          prompt: prompt,
          text: '${_f('x ${Fmt.signed(b)}', a)} = $c',
          answer: Ans.integer(a * c - b, negative: true),
          work: <String>[
            'x ${Fmt.signed(b)} = ${a * c}',
            'x = ${a * c - b}',
          ],
        );
    }
  }

  static Question inequality(Gen g) {
    final rel = g.pick(const <String>['<', '>', '≤', '≥']);
    final String text;
    final String result;
    final int bound;
    if (g.d == 1) {
      final a = g.n(1, 9);
      final x = g.n(-5, 12);
      if (g.chance()) {
        text = 'x + $a $rel ${x + a}';
        bound = x;
      } else {
        text = 'x - $a $rel ${x - a}';
        bound = x;
      }
      result = rel;
    } else {
      final a = g.d == 2 ? g.n(2, 9) : -g.n(2, 9);
      final x = g.nz(-9, 9);
      final b = g.nz(-9, 9);
      text = '${Fmt.ints(<int>[b, a])} $rel ${a * x + b}';
      bound = x;
      result = a < 0 ? _flip[rel]! : rel;
    }
    return Question(
      topic: 'ineq',
      prompt: 'Solve the inequality',
      text: text,
      answer: RelationAnswer(result, bound.toDouble()),
    );
  }

  static Question system(Gen g) {
    int a1, b1, a2, b2;
    final x = g.n(-5, 9);
    final y = g.n(-5, 9);
    do {
      if (g.d == 1) {
        a1 = 1;
        b1 = 1;
        a2 = 1;
        b2 = -1;
      } else if (g.d == 2) {
        a1 = g.n(1, 3);
        b1 = g.n(1, 3);
        a2 = g.n(1, 3);
        b2 = -g.n(1, 3);
      } else {
        a1 = g.nz(-5, 5);
        b1 = g.nz(-5, 5);
        a2 = g.nz(-5, 5);
        b2 = g.nz(-5, 5);
      }
    } while (a1 * b2 - a2 * b1 == 0);
    final c1 = a1 * x + b1 * y;
    final c2 = a2 * x + b2 * y;
    return Question(
      topic: 'system',
      prompt: 'Solve for x and y, written as x, y',
      text: '\\sys{${Fmt.xy(a1, b1)} = $c1;${Fmt.xy(a2, b2)} = $c2}',
      answer: ListAnswer(<double>[x.toDouble(), y.toDouble()]),
    );
  }

  static Question lines(Gen g) {
    final variants = g.d == 1 ? const <int>[0, 2] : const <int>[0, 1, 2];
    switch (g.pick(variants)) {
      case 0:
        final q = g.d == 1 ? 1 : g.n(1, 4);
        final p = g.nz(-6, 6);
        final dx = q * g.n(1, 3);
        final x1 = g.n(-5, 5);
        final y1 = g.n(-5, 5);
        final x2 = x1 + dx;
        final y2 = y1 + p * (dx ~/ q);
        return Question(
          topic: 'lines',
          prompt: 'Find the slope of the line through the points',
          text: '($x1, $y1), ($x2, $y2)',
          answer: Ans.rational(Rational(p, q), negative: true, reduced: false),
        );
      case 1:
        final m = g.nz(-5, 5);
        final x1 = g.n(-4, 4);
        final y1 = g.n(-6, 6);
        return Question(
          topic: 'lines',
          prompt: 'Write the line as y = mx + b',
          text: 'm = $m,  P($x1, $y1)',
          answer: Ans.poly(<int>[y1 - m * x1, m]),
        );
      default:
        final a = _big(g, -5, 5);
        final x0 = g.nz(-9, 9);
        return Question(
          topic: 'lines',
          prompt: 'Find the x-intercept (where y = 0)',
          text: 'y = ${Fmt.ints(<int>[-a * x0, a])}',
          answer: Ans.integer(x0, negative: true),
        );
    }
  }
}
