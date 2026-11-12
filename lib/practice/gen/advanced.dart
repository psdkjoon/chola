import 'dart:math' as math;

import 'package:chola/math/answer.dart';
import 'package:chola/math/expression.dart';
import 'package:chola/math/rational.dart';
import 'package:chola/practice/question.dart';

abstract class Advanced {
  static const String _roots = 'Solve for x, separating the roots with a comma';

  static int _pow(int base, int e) {
    var out = 1;
    for (var i = 0; i < e; i++) {
      out *= base;
    }
    return out;
  }

  static String _f(Object a, Object b) => '\\frac{$a}{$b}';

  static String _lin(int a, int b) =>
      '(${a == 1 ? '' : a}x ${Fmt.signed(b)})';

  static ListAnswer _rootList(List<Rational> rs) {
    final sorted = List<Rational>.of(rs)..sort();
    final distinct = <Rational>[];
    for (final r in sorted) {
      if (distinct.isEmpty || distinct.last != r) distinct.add(r);
    }
    return ListAnswer(
      <double>[for (final r in distinct) r.value],
      ordered: false,
      shownParts: <String>[for (final r in distinct) r.markup],
      fraction: true,
    );
  }

  static Question quadratic(Gen g) {
    final List<int> coef;
    final List<Rational> roots;
    final String factored;
    if (g.d == 3) {
      final a = g.n(2, 3);
      var p = g.nz(-9, 9);
      while (Rational.gcd(p, a) != 1) {
        p = g.nz(-9, 9);
      }
      final r = g.nz(-6, 6);
      coef = <int>[p * r, -(p + a * r), a];
      roots = <Rational>[Rational(p, a), Rational(r)];
      factored = '${_lin(a, -p)}${Fmt.linFactor(r)} = 0';
    } else {
      final span = g.d == 1 ? 6 : 9;
      final r1 = g.d == 1 ? g.n(1, span) : g.nz(-span, span);
      var r2 = g.d == 1 ? g.n(1, span) : g.nz(-span, span);
      if (g.d == 1 && g.chance(6)) r2 = r1;
      coef = <int>[r1 * r2, -(r1 + r2), 1];
      roots = <Rational>[Rational(r1), Rational(r2)];
      factored = '${Fmt.linFactor(r1)}${Fmt.linFactor(r2)} = 0';
    }
    return Question(
      topic: 'quad',
      prompt: _roots,
      text: '${Fmt.ints(coef)} = 0',
      answer: _rootList(roots),
      work: <String>[factored],
    );
  }

  static ExprAnswer _factorAnswer(List<int> coef, String shown) => ExprAnswer(
        Poly(<double>[for (final v in coef) v.toDouble()]),
        shown,
        form: ExprForm.factored,
      );

  static Question factor(Gen g) {
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[1, 2] : const <int>[3, 4]);
    switch (g.pick(variants)) {
      case 0:
        final r1 = -g.n(1, 8);
        final r2 = -g.n(1, 8);
        final coef = <int>[r1 * r2, -(r1 + r2), 1];
        return Question(
          topic: 'factor',
          prompt: 'Factor the expression',
          text: Fmt.ints(coef),
          answer: _factorAnswer(
            coef,
            '${Fmt.linFactor(r1)}${Fmt.linFactor(r2)}',
          ),
        );
      case 1:
        final r1 = g.nz(-9, 9);
        final r2 = g.nz(-9, 9);
        final coef = <int>[r1 * r2, -(r1 + r2), 1];
        return Question(
          topic: 'factor',
          prompt: 'Factor the expression',
          text: Fmt.ints(coef),
          answer: _factorAnswer(
            coef,
            '${Fmt.linFactor(r1)}${Fmt.linFactor(r2)}',
          ),
        );
      case 2:
        final k = g.n(2, 12);
        return Question(
          topic: 'factor',
          prompt: 'Factor the expression',
          text: 'x^2 - ${k * k}',
          answer: _factorAnswer(
            <int>[-k * k, 0, 1],
            '(x - $k)(x + $k)',
          ),
        );
      case 3:
        var a = 1;
        var c = 1;
        while (a * c == 1) {
          a = g.n(1, 3);
          c = g.n(1, 3);
        }
        final b = g.nz(-6, 6);
        final e = g.nz(-6, 6);
        final coef = <int>[b * e, a * e + b * c, a * c];
        return Question(
          topic: 'factor',
          prompt: 'Factor the expression',
          text: Fmt.ints(coef),
          answer: _factorAnswer(coef, '${_lin(a, b)}${_lin(c, e)}'),
        );
      default:
        final k = g.n(2, 5);
        final r = g.nz(-6, 6);
        return Question(
          topic: 'factor',
          prompt: 'Factor the expression',
          text: Fmt.ints(<int>[0, -k * r, k]),
          answer: _factorAnswer(
            <int>[0, -k * r, k],
            '${k}x${Fmt.linFactor(r)}',
          ),
        );
    }
  }

  static Question expand(Gen g) {
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[0, 1, 2] : const <int>[3, 4, 5]);
    final List<int> result;
    final String text;
    switch (g.pick(variants)) {
      case 0:
        final a = g.d == 1 ? g.n(1, 9) : g.nz(-9, 9);
        final b = g.d == 1 ? g.n(1, 9) : g.nz(-9, 9);
        text = '(x ${Fmt.signed(a)})(x ${Fmt.signed(b)})';
        result = Fmt.mul(<int>[a, 1], <int>[b, 1]);
      case 1:
        final a = g.nz(-9, 9);
        text = '(x ${Fmt.signed(a)})^2';
        result = Fmt.mul(<int>[a, 1], <int>[a, 1]);
      case 2:
        final a = g.n(2, 12);
        text = '(x - $a)(x + $a)';
        result = Fmt.mul(<int>[-a, 1], <int>[a, 1]);
      case 3:
        final a = g.n(1, 3);
        final c = g.n(1, 3);
        final b = g.nz(-6, 6);
        final e = g.nz(-6, 6);
        text = '${_lin(a, b)}${_lin(c, e)}';
        result = Fmt.mul(<int>[b, a], <int>[e, c]);
      default:
        List<int> p = <int>[0, 0, 0];
        List<int> q = <int>[0, 0, 0];
        var out = <int>[0];
        final minus = g.chance();
        do {
          p = <int>[g.n(-9, 9), g.n(-9, 9), g.nz(-5, 5)];
          q = <int>[g.n(-9, 9), g.n(-9, 9), g.nz(-5, 5)];
          out = Fmt.add(p, q, minus ? -1 : 1);
        } while (out.every((v) => v == 0));
        text = '(${Fmt.ints(p)}) ${minus ? '-' : '+'} (${Fmt.ints(q)})';
        result = out;
    }
    return Question(
      topic: 'polyops',
      prompt: 'Expand and simplify',
      text: text,
      answer: Ans.poly(result),
    );
  }

  static Question absolute(Gen g) {
    if (g.d == 1) {
      final a = g.nz(-9, 9);
      final b = g.n(1, 9);
      return Question(
        topic: 'abs',
        prompt: _roots,
        text: '|x ${Fmt.signed(-a)}| = $b',
        answer: _rootList(<Rational>[Rational(a + b), Rational(a - b)]),
      );
    }
    final a = g.n(2, 4);
    final b = g.nz(-9, 9);
    final c = g.n(1, 9);
    return Question(
      topic: 'abs',
      prompt: _roots,
      text: '|${Fmt.ints(<int>[b, a])}| = $c',
      answer: _rootList(
        <Rational>[Rational(c - b, a), Rational(-c - b, a)],
      ),
    );
  }

  static Question parabola(Gen g) {
    if (g.d == 1) {
      final a = g.nz(-3, 3);
      final b = g.n(-9, 9);
      final c = g.nz(-9, 9);
      return Question(
        topic: 'parabola',
        prompt: 'Find the discriminant',
        text: Fmt.ints(<int>[c, b, a]),
        answer: Ans.integer(b * b - 4 * a * c, negative: true),
        work: <String>['b^2 - 4ac'],
      );
    }
    final a = g.d == 2 ? 1 : g.pick(const <int>[1, 2, 3, -1, -2]);
    final h = g.n(-5, 5);
    final k = g.n(-9, 9);
    return Question(
      topic: 'parabola',
      prompt: 'Find the vertex, written as h, k',
      text: 'y = ${Fmt.ints(<int>[a * h * h + k, -2 * a * h, a])}',
      answer: ListAnswer(<double>[h.toDouble(), k.toDouble()]),
      work: <String>['h = ${_f('-b', '2a')}'],
    );
  }

  static List<int> _compose(List<int> f, List<int> g) {
    var out = <int>[0];
    var power = <int>[1];
    for (var k = 0; k < f.length; k++) {
      out = Fmt.add(out, <int>[for (final v in power) v * f[k]]);
      power = Fmt.mul(power, g);
    }
    return out;
  }

  static Question functions(Gen g) {
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[0, 1] : const <int>[1, 2, 3]);
    switch (g.pick(variants)) {
      case 0:
        final f = g.d == 1
            ? <int>[g.n(-9, 9), g.nz(-5, 5)]
            : <int>[g.n(-9, 9), g.n(-6, 6), g.nz(-3, 3)];
        final x = g.n(-4, 4);
        return Question(
          topic: 'functions',
          prompt: 'Evaluate the function',
          text: 'f(x) = ${Fmt.ints(f)}\nf($x) = ?',
          answer: Ans.integer(Fmt.evalAt(f, x), negative: true),
        );
      case 1:
        final f = <int>[g.n(-5, 5), g.nz(-4, 4)];
        final h = <int>[g.n(-5, 5), g.n(-3, 3), g.nz(-2, 2)];
        final x = g.n(-3, 3);
        return Question(
          topic: 'functions',
          prompt: 'Evaluate the function',
          text:
              'f(x) = ${Fmt.ints(f)}\ng(x) = ${Fmt.ints(h)}\nf(g($x)) = ?',
          answer: Ans.integer(
            Fmt.evalAt(f, Fmt.evalAt(h, x)),
            negative: true,
          ),
        );
      case 2:
        final f = <int>[g.n(-6, 6), g.nz(-3, 3), g.nz(-3, 3)];
        final h = <int>[g.n(-5, 5), g.nz(-3, 3)];
        return Question(
          topic: 'functions',
          prompt: 'Find the composite function',
          text:
              'f(x) = ${Fmt.ints(f)}\ng(x) = ${Fmt.ints(h)}\nf(g(x)) = ?',
          answer: Ans.poly(_compose(f, h)),
        );
      default:
        final a = g.pick(const <int>[2, 3, 4, 5, -2, -3]);
        final b = g.nz(-9, 9);
        return Question(
          topic: 'functions',
          prompt: 'Find the inverse function',
          text: 'f(x) = ${Fmt.ints(<int>[b, a])}\nf^-1(x) = ?',
          answer: ExprAnswer(
            Poly(<double>[-b / a, 1 / a]),
            _f('x ${Fmt.signed(-b)}', a),
            form: ExprForm.any,
            fraction: true,
          ),
        );
    }
  }

  static Question radicals(Gen g) {
    final k = g.n(2, g.by(5, 8, 12));
    final m = g.pick(const <int>[2, 3, 5, 6, 7, 10, 11]);
    final c = g.d == 3 ? g.n(2, 4) : 1;
    final inside = k * k * m;
    return Question(
      topic: 'radicals',
      prompt: 'Simplify the radical',
      text: c == 1 ? '\\sqrt{$inside}' : '$c\\sqrt{$inside}',
      answer: RadicalAnswer(c * k, m),
    );
  }

  static Question complex(Gen g) {
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[0, 1, 2] : const <int>[1, 2, 3]);
    switch (g.pick(variants)) {
      case 0:
        final a = g.nz(-6, 6), b = g.nz(-6, 6);
        final c = g.nz(-6, 6), e = g.nz(-6, 6);
        final minus = g.chance();
        return Question(
          topic: 'complex',
          prompt: 'Write in the form a + bi',
          text:
              '(${Fmt.complex(a, b)}) ${minus ? '-' : '+'} (${Fmt.complex(c, e)})',
          answer: minus
              ? ComplexAnswer((a - c).toDouble(), (b - e).toDouble())
              : ComplexAnswer((a + c).toDouble(), (b + e).toDouble()),
        );
      case 1:
        final a = g.nz(-5, 5), b = g.nz(-5, 5);
        final c = g.nz(-5, 5), e = g.nz(-5, 5);
        return Question(
          topic: 'complex',
          prompt: 'Write in the form a + bi',
          text: '(${Fmt.complex(a, b)})(${Fmt.complex(c, e)})',
          answer: ComplexAnswer(
            (a * c - b * e).toDouble(),
            (a * e + b * c).toDouble(),
          ),
        );
      case 2:
        final n = g.n(3, 43);
        final (re, im) = switch (n % 4) {
          0 => (1.0, 0.0),
          1 => (0.0, 1.0),
          2 => (-1.0, 0.0),
          _ => (0.0, -1.0),
        };
        return Question(
          topic: 'complex',
          prompt: 'Write in the form a + bi',
          text: 'i^$n',
          answer: ComplexAnswer(re, im),
        );
      default:
        final (a, b, c) = g.pick(const <(int, int, int)>[
          (3, 4, 5),
          (6, 8, 10),
          (5, 12, 13),
          (8, 15, 17),
        ]);
        return Question(
          topic: 'complex',
          prompt: 'Find the modulus',
          text: 'z = ${Fmt.complex(a * g.sign(), b * g.sign())}',
          answer: Ans.integer(c),
        );
    }
  }

  static Question logs(Gen g) {
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[0, 1] : const <int>[1, 2, 3]);
    final b = g.pick(const <int>[2, 3, 5, 10]);
    final top = b == 2 ? 6 : (b == 3 ? 4 : (b == 5 ? 3 : 3));
    switch (g.pick(variants)) {
      case 0:
        final k = g.n(1, top);
        return Question(
          topic: 'logs',
          prompt: 'Evaluate',
          text: 'log_{$b} ${_pow(b, k)}',
          answer: Ans.integer(k),
        );
      case 1:
        final i = g.n(1, top - 1);
        final j = g.n(1, top - i);
        if (g.chance()) {
          return Question(
            topic: 'logs',
            prompt: 'Evaluate',
            text: 'log_{$b} ${_pow(b, i)} + log_{$b} ${_pow(b, j)}',
            answer: Ans.integer(i + j),
          );
        }
        return Question(
          topic: 'logs',
          prompt: 'Evaluate',
          text: 'log_{$b} ${_pow(b, i + j)} - log_{$b} ${_pow(b, j)}',
          answer: Ans.integer(i),
        );
      case 2:
        final k = g.n(1, top);
        return Question(
          topic: 'logs',
          prompt: 'Evaluate',
          text: 'log_{$b} ${_f(1, _pow(b, k))}',
          answer: Ans.integer(-k, negative: true),
        );
      default:
        final k = g.n(2, 9);
        return Question(
          topic: 'logs',
          prompt: 'Evaluate',
          text: 'ln e^{$k}',
          answer: Ans.integer(k),
        );
    }
  }

  static Question exponentialEquation(Gen g) {
    const prompt = 'Solve for x';
    final b = g.pick(const <int>[2, 3, 5]);
    final top = b == 2 ? 6 : (b == 3 ? 4 : 3);
    final k = g.n(1, top);
    if (g.d == 1) {
      return Question(
        topic: 'expeq',
        prompt: prompt,
        text: '$b^x = ${_pow(b, k)}',
        answer: Ans.integer(k),
      );
    }
    if (g.d == 2) {
      final c = g.nz(-3, 3);
      return Question(
        topic: 'expeq',
        prompt: prompt,
        text: '$b^{x ${Fmt.signed(c)}} = ${_pow(b, k)}',
        answer: Ans.integer(k - c, negative: true),
      );
    }
    if (g.chance()) {
      return Question(
        topic: 'expeq',
        prompt: prompt,
        text: '$b^x = ${_f(1, _pow(b, k))}',
        answer: Ans.integer(-k, negative: true),
      );
    }
    final x = g.n(2, 4);
    final base = g.pick(const <int>[2, 3]);
    return Question(
      topic: 'expeq',
      prompt: prompt,
      text: '$base^{2x} = ${_pow(base, 2 * x)}',
      answer: Ans.integer(x),
    );
  }

  static const Map<int, String> _sinRef = <int, String>{
    0: '0',
    30: '\\frac{1}{2}',
    45: '\\frac{\\sqrt{2}}{2}',
    60: '\\frac{\\sqrt{3}}{2}',
    90: '1',
  };

  static const Map<int, String> _tanRef = <int, String>{
    0: '0',
    30: '\\frac{\\sqrt{3}}{3}',
    45: '1',
    60: '\\sqrt{3}',
  };

  static Question trig(Gen g) {
    final List<(String, int)> pool;
    if (g.d == 1) {
      pool = const <(String, int)>[
        ('sin', 0), ('sin', 30), ('sin', 90),
        ('cos', 0), ('cos', 60), ('cos', 90),
        ('tan', 0), ('tan', 45),
      ];
    } else {
      final angles = g.d == 2
          ? const <int>[0, 30, 45, 60, 90]
          : const <int>[0, 30, 45, 60, 90, 120, 135, 150, 180];
      pool = <(String, int)>[
        for (final f in const <String>['sin', 'cos', 'tan'])
          for (final a in angles)
            if (!(f == 'tan' && a == 90)) (f, a),
      ];
    }
    final (fn, angle) = g.pick(pool);
    final ref = angle <= 90 ? angle : 180 - angle;
    final String base;
    switch (fn) {
      case 'sin':
        base = _sinRef[ref]!;
      case 'cos':
        base = _sinRef[90 - ref]!;
      default:
        base = _tanRef[ref]!;
    }
    final negative = angle > 90 && fn != 'sin' && base != '0';
    final rad = angle * math.pi / 180;
    final value = switch (fn) {
      'sin' => math.sin(rad),
      'cos' => math.cos(rad),
      _ => math.tan(rad),
    };
    return Question(
      topic: 'trig',
      prompt: 'Find the exact value',
      text: '$fn $angle°',
      answer: ValueAnswer(
        value,
        shownText: negative ? '-$base' : base,
        negative: g.d == 3,
        fraction: true,
        symbols: const <String>['√'],
      ),
    );
  }

  static Question radians(Gen g) {
    final list = g.d == 1
        ? const <int>[30, 45, 60, 90, 180]
        : const <int>[
            30, 45, 60, 90, 120, 135, 150, 180, 210, 225, 240, 270, 300, 315,
            330, 360,
          ];
    final deg = g.pick(list);
    final a = Ans.pi(Rational(deg, 180));
    if (g.chance()) {
      return Question(
        topic: 'radians',
        prompt: 'Convert to radians',
        text: '$deg°',
        answer: a,
      );
    }
    return Question(
      topic: 'radians',
      prompt: 'Convert to degrees',
      text: a.shown,
      answer: Ans.integer(deg),
    );
  }

  static Question sequences(Gen g) {
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[0, 1, 2] : const <int>[1, 2, 3]);
    switch (g.pick(variants)) {
      case 0:
        final a = g.n(-5, 9);
        final d = g.nz(-5, 9);
        final n = g.n(10, 30);
        return Question(
          topic: 'seq',
          prompt: 'Find the n-th term',
          text: '$a, ${a + d}, ${a + 2 * d}, ${a + 3 * d}, …\nn = $n',
          answer: Ans.integer(a + (n - 1) * d, negative: true),
        );
      case 1:
        final a = g.n(-5, 9);
        final d = g.nz(-5, 9);
        final n = g.n(10, 30);
        return Question(
          topic: 'seq',
          prompt: 'Find the sum of the first n terms',
          text: '$a, ${a + d}, ${a + 2 * d}, ${a + 3 * d}, …\nn = $n',
          answer: Ans.integer(n * (2 * a + (n - 1) * d) ~/ 2, negative: true),
        );
      case 2:
        final a = g.n(1, 5);
        final r = g.pick(const <int>[2, 3, -2]);
        final n = g.n(4, 7);
        return Question(
          topic: 'seq',
          prompt: 'Find the n-th term',
          text: '$a, ${a * r}, ${a * r * r}, ${a * r * r * r}, …\nn = $n',
          answer: Ans.integer(a * _pow(r, n - 1), negative: true),
        );
      default:
        final a = g.n(1, 5);
        final r = g.pick(const <int>[2, 3]);
        final n = g.n(4, 6);
        return Question(
          topic: 'seq',
          prompt: 'Find the sum of the first n terms',
          text: '$a, ${a * r}, ${a * r * r}, ${a * r * r * r}, …\nn = $n',
          answer: Ans.integer(a * (_pow(r, n) - 1) ~/ (r - 1)),
        );
    }
  }

  static int _choose(int n, int k) {
    var out = 1;
    for (var i = 1; i <= k; i++) {
      out = out * (n - k + i) ~/ i;
    }
    return out;
  }

  static Question counting(Gen g) {
    final variants = g.d == 1
        ? const <int>[0, 1]
        : (g.d == 2 ? const <int>[1, 2] : const <int>[2, 3]);
    switch (g.pick(variants)) {
      case 0:
        final n = g.n(3, 8);
        var f = 1;
        for (var i = 2; i <= n; i++) {
          f *= i;
        }
        return Question(
          topic: 'comb',
          prompt: 'Evaluate',
          text: '$n!',
          answer: Ans.integer(f),
        );
      case 1:
        final n = g.n(4, 9);
        final r = g.n(2, 4);
        var p = 1;
        for (var i = 0; i < r; i++) {
          p *= n - i;
        }
        return Question(
          topic: 'comb',
          prompt: 'Evaluate',
          text: 'P($n, $r)',
          answer: Ans.integer(p),
        );
      case 2:
        final n = g.n(5, 12);
        final r = g.n(2, 4);
        return Question(
          topic: 'comb',
          prompt: 'Evaluate',
          text: 'C($n, $r)',
          answer: Ans.integer(_choose(n, r)),
        );
      default:
        final both = g.n(2, 8);
        final a = both + g.n(2, 12);
        final b = both + g.n(2, 12);
        return Question(
          topic: 'comb',
          prompt: 'Find |A ∪ B|',
          text: '|A| = $a, |B| = $b, |A ∩ B| = $both',
          answer: Ans.integer(a + b - both),
        );
    }
  }
}
