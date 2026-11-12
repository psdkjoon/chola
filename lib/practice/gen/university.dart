import 'dart:math' as math;

import 'package:chola/math/answer.dart';
import 'package:chola/math/rational.dart';
import 'package:chola/practice/question.dart';

abstract class University {
  static String _f(Object a, Object b) => '\\frac{$a}{$b}';

  static String _mat(List<int> m) => '\\mat{${m[0]},${m[1]};${m[2]},${m[3]}}';

  static int _choose(int n, int k) {
    var out = 1;
    for (var i = 1; i <= k; i++) {
      out = out * (n - k + i) ~/ i;
    }
    return out;
  }

  static Question limits(Gen g) {
    const prompt = 'Find the limit';
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[0, 1] : const <int>[2, 3]);
    switch (g.pick(variants)) {
      case 0:
        final a = g.n(-3, 3);
        final c = <int>[g.n(-9, 9), g.n(-6, 6), g.nz(-4, 4)];
        return Question(
          topic: 'limits',
          prompt: prompt,
          text: 'lim_{x→$a} (${Fmt.ints(c)})',
          answer: Ans.integer(Fmt.evalAt(c, a), negative: true),
        );
      case 1:
        final a = g.nz(-6, 6);
        return Question(
          topic: 'limits',
          prompt: prompt,
          text: 'lim_{x→$a} ${_f('x^2 - ${a * a}', 'x ${Fmt.signed(-a)}')}',
          answer: Ans.integer(2 * a, negative: true),
          work: <String>['(x - $a)(x + $a)'],
        );
      case 2:
        final a = g.nz(-6, 6);
        final b = g.nz(-6, 6);
        return Question(
          topic: 'limits',
          prompt: prompt,
          text:
              'lim_{x→$a} ${_f(Fmt.ints(<int>[-a * b, b - a, 1]), 'x ${Fmt.signed(-a)}')}',
          answer: Ans.integer(a + b, negative: true),
        );
      default:
        final a = g.nz(-6, 6);
        final d = g.nz(-6, 6);
        final b = g.n(-9, 9);
        final e = g.n(-9, 9);
        return Question(
          topic: 'limits',
          prompt: prompt,
          text:
              'lim_{x→∞} ${_f(Fmt.ints(<int>[0, b, a]), Fmt.ints(<int>[e, 0, d]))}',
          answer: Ans.rational(Rational(a, d), negative: true),
        );
    }
  }

  static Question derivative(Gen g) {
    const prompt = 'Find the derivative';
    if (g.d == 1) {
      final n = g.n(2, 6);
      final c = List<int>.filled(n + 1, 0);
      c[n] = g.nz(-9, 9);
      return Question(
        topic: 'deriv',
        prompt: prompt,
        text: 'f(x) = ${Fmt.ints(c)}',
        answer: Ans.poly(Fmt.derive(c)),
      );
    }
    if (g.d == 2) {
      final c = <int>[g.n(-9, 9), g.nz(-9, 9), g.n(-9, 9), g.nz(-6, 6)];
      return Question(
        topic: 'deriv',
        prompt: prompt,
        text: 'f(x) = ${Fmt.ints(c)}',
        answer: Ans.poly(Fmt.derive(c)),
      );
    }
    if (g.chance()) {
      final a = g.nz(-5, 5);
      final b = g.nz(-5, 5);
      final expanded = Fmt.mul(<int>[a, 0, 1], <int>[b, 1]);
      return Question(
        topic: 'deriv',
        prompt: prompt,
        text: 'f(x) = (x^2 ${Fmt.signed(a)})(x ${Fmt.signed(b)})',
        answer: Ans.poly(Fmt.derive(expanded), form: ExprForm.any),
      );
    }
    final a = g.n(1, 3);
    final b = g.nz(-5, 5);
    final lin = <int>[b, a];
    final cube = Fmt.mul(Fmt.mul(lin, lin), lin);
    return Question(
      topic: 'deriv',
      prompt: prompt,
      text: 'f(x) = (${Fmt.ints(lin)})^3',
      answer: Ans.poly(Fmt.derive(cube), form: ExprForm.any),
    );
  }

  static Question derivativeAt(Gen g) {
    final c = g.d == 1
        ? <int>[g.n(-9, 9), g.n(-9, 9), g.nz(-5, 5)]
        : <int>[g.n(-9, 9), g.n(-9, 9), g.n(-5, 5), g.nz(-3, 3)];
    final x = g.n(-3, 3);
    return Question(
      topic: 'derivpt',
      prompt: 'Find the derivative at the point',
      text: 'f(x) = ${Fmt.ints(c)}\nx = $x',
      answer: Ans.integer(Fmt.evalAt(Fmt.derive(c), x), negative: true),
    );
  }

  static String _integrand(List<int> c) {
    final text = Fmt.ints(c);
    var terms = 0;
    for (final v in c) {
      if (v != 0) terms++;
    }
    return terms > 1 ? '($text)' : text;
  }

  static Question integral(Gen g) {
    if (g.d == 1) {
      final m = g.n(2, 4);
      final f = List<int>.filled(m + 1, 0);
      f[m] = g.nz(-5, 5);
      return Question(
        topic: 'integral',
        prompt: 'Find the antiderivative, leaving out + C',
        text: '∫ ${_integrand(Fmt.derive(f))} dx',
        answer: Ans.poly(f),
      );
    }
    if (g.d == 2) {
      final f = <int>[0, g.nz(-5, 5), g.nz(-5, 5), g.nz(-4, 4)];
      return Question(
        topic: 'integral',
        prompt: 'Find the antiderivative, leaving out + C',
        text: '∫ ${_integrand(Fmt.derive(f))} dx',
        answer: Ans.poly(f),
      );
    }
    final f = <int>[0, g.n(-5, 5), g.nz(-4, 4), g.nz(-3, 3)];
    final lo = g.n(-2, 1);
    final hi = lo + g.n(1, 3);
    return Question(
      topic: 'integral',
      prompt: 'Evaluate the integral',
      text: '∫_{$lo}^{$hi} ${_integrand(Fmt.derive(f))} dx',
      answer: Ans.integer(
        Fmt.evalAt(f, hi) - Fmt.evalAt(f, lo),
        negative: true,
      ),
    );
  }

  static Question optimize(Gen g) {
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[0, 1] : const <int>[1, 2]);
    final v = g.pick(variants);
    if (v == 2) {
      var r1 = g.n(-4, 4);
      var r2 = g.n(-4, 4);
      while (r1 == r2 || (r1 + r2).isOdd) {
        r1 = g.n(-4, 4);
        r2 = g.n(-4, 4);
      }
      final c = <int>[0, 3 * r1 * r2, -3 * (r1 + r2) ~/ 2, 1];
      return Question(
        topic: 'optimize',
        prompt: 'Find the critical points, separated by a comma',
        text: 'f(x) = ${Fmt.ints(c)}',
        answer: ListAnswer(
          <double>[r1.toDouble(), r2.toDouble()],
          ordered: false,
        ),
        work: <String>['f\u2032(x) = ${Fmt.ints(Fmt.derive(c))}'],
      );
    }
    final a = g.pick(const <int>[1, 2, 3, -1, -2]);
    final h = g.n(-5, 5);
    final k = g.n(-9, 9);
    final c = <int>[a * h * h + k, -2 * a * h, a];
    final min = a > 0;
    if (v == 0) {
      return Question(
        topic: 'optimize',
        prompt: min
            ? 'At which x does f have its minimum?'
            : 'At which x does f have its maximum?',
        text: 'f(x) = ${Fmt.ints(c)}',
        answer: Ans.integer(h, negative: true),
      );
    }
    return Question(
      topic: 'optimize',
      prompt:
          min ? 'Find the minimum value of f' : 'Find the maximum value of f',
      text: 'f(x) = ${Fmt.ints(c)}',
      answer: Ans.integer(k, negative: true),
    );
  }

  static Question series(Gen g) {
    const prompt = 'Evaluate the sum';
    final variants = g.d == 1
        ? const <int>[0, 2]
        : (g.d == 2 ? const <int>[0, 1, 2] : const <int>[1, 3]);
    switch (g.pick(variants)) {
      case 0:
        final n = g.n(5, 30);
        return Question(
          topic: 'series',
          prompt: prompt,
          text: 'Σ_{k=1}^{$n} k',
          answer: Ans.integer(n * (n + 1) ~/ 2),
        );
      case 1:
        final n = g.n(3, 10);
        return Question(
          topic: 'series',
          prompt: prompt,
          text: 'Σ_{k=1}^{$n} k^2',
          answer: Ans.integer(n * (n + 1) * (2 * n + 1) ~/ 6),
        );
      case 2:
        final n = g.n(4, 20);
        final a = g.n(2, 5);
        final b = g.nz(-5, 5);
        return Question(
          topic: 'series',
          prompt: prompt,
          text: 'Σ_{k=1}^{$n} (${Fmt.ints(<int>[b, a], v: 'k')})',
          answer: Ans.integer(a * n * (n + 1) ~/ 2 + b * n, negative: true),
        );
      default:
        final a = g.n(1, 9);
        final q = g.n(2, 5);
        return Question(
          topic: 'series',
          prompt: prompt,
          text: 'Σ_{n=0}^{∞} $a(${_f(1, q)})^{n}',
          answer: Ans.rational(Rational(a * q, q - 1)),
          work: <String>[_f('a', '1 - r')],
        );
    }
  }

  static Question determinant(Gen g) {
    final lo = g.d == 3 ? -3 : -5;
    final hi = g.d == 3 ? 5 : 9;
    if (g.d == 1 || (g.d == 2 && g.chance())) {
      final m = <int>[for (var i = 0; i < 4; i++) g.n(lo, hi)];
      return Question(
        topic: 'det',
        prompt: 'Find the determinant',
        text: '\\det{${m[0]},${m[1]};${m[2]},${m[3]}}',
        answer: Ans.integer(m[0] * m[3] - m[1] * m[2], negative: true),
        work: <String>['ad - bc'],
      );
    }
    final m = <int>[for (var i = 0; i < 9; i++) g.n(g.d == 2 ? 0 : lo, g.d == 2 ? 4 : hi)];
    final det = m[0] * (m[4] * m[8] - m[5] * m[7]) -
        m[1] * (m[3] * m[8] - m[5] * m[6]) +
        m[2] * (m[3] * m[7] - m[4] * m[6]);
    return Question(
      topic: 'det',
      prompt: 'Find the determinant',
      text:
          '\\det{${m[0]},${m[1]},${m[2]};${m[3]},${m[4]},${m[5]};${m[6]},${m[7]},${m[8]}}',
      answer: Ans.integer(det, negative: true),
    );
  }

  static List<int> _mul(List<int> a, List<int> b) => <int>[
        a[0] * b[0] + a[1] * b[2],
        a[0] * b[1] + a[1] * b[3],
        a[2] * b[0] + a[3] * b[2],
        a[2] * b[1] + a[3] * b[3],
      ];

  static List<int> _randomMatrix(Gen g, int lo, int hi) =>
      <int>[for (var i = 0; i < 4; i++) g.n(lo, hi)];

  static Question matrix(Gen g) {
    const prompt = 'Enter the entries of the result row by row, separated by commas';
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[0, 1] : const <int>[2]);
    final a = _randomMatrix(g, -5, 9);
    final b = _randomMatrix(g, -5, 9);
    final List<int> result;
    final String text;
    switch (g.pick(variants)) {
      case 0:
        result = <int>[for (var i = 0; i < 4; i++) a[i] + b[i]];
        text = '${_mat(a)} + ${_mat(b)}';
      case 1:
        final k = g.nz(-4, 4);
        result = <int>[for (final v in a) k * v];
        text = '$k × ${_mat(a)}';
      default:
        final x = _randomMatrix(g, -3, 4);
        final y = _randomMatrix(g, -3, 4);
        result = _mul(x, y);
        text = '${_mat(x)} × ${_mat(y)}';
    }
    return Question(
      topic: 'matrix',
      prompt: prompt,
      text: text,
      answer: ListAnswer(<double>[for (final v in result) v.toDouble()]),
    );
  }

  static const List<(List<int>, List<int>)> _bases = <(List<int>, List<int>)>[
    (<int>[1, 1, 0, 1], <int>[1, -1, 0, 1]),
    (<int>[1, 0, 1, 1], <int>[1, 0, -1, 1]),
    (<int>[2, 1, 1, 1], <int>[1, -1, -1, 2]),
    (<int>[1, 1, 1, 2], <int>[2, -1, -1, 1]),
  ];

  static Question eigen(Gen g) {
    final (p, inv) = g.pick(g.d == 1 ? _bases.sublist(0, 2) : _bases);
    final span = g.by(4, 5, 7);
    final l1 = g.n(-span, span);
    var l2 = g.n(-span, span);
    while (l1 == l2) {
      l2 = g.n(-span, span);
    }
    final m = _mul(_mul(p, <int>[l1, 0, 0, l2]), inv);
    return Question(
      topic: 'eigen',
      prompt: 'Find the eigenvalues, separated by a comma',
      text: _mat(m),
      answer: ListAnswer(
        <double>[l1.toDouble(), l2.toDouble()],
        ordered: false,
      ),
      work: <String>[
        '${Fmt.ints(<int>[m[0] * m[3] - m[1] * m[2], -(m[0] + m[3]), 1])} = 0',
      ],
    );
  }

  static const List<(int, int, int, int)> _quads = <(int, int, int, int)>[
    (1, 2, 2, 3),
    (2, 3, 6, 7),
    (4, 4, 7, 9),
    (2, 6, 9, 11),
    (6, 6, 7, 11),
  ];

  static String _vec(String name, List<int> v) => '$name = (${v.join(', ')})';

  static Question vectors(Gen g) {
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[0, 1, 2] : const <int>[1, 2, 3]);
    switch (g.pick(variants)) {
      case 0:
        final u = <int>[g.n(-5, 5), g.n(-5, 5)];
        final v = <int>[g.n(-5, 5), g.n(-5, 5)];
        return Question(
          topic: 'vectors',
          prompt: 'Find the dot product',
          text: '${_vec('u', u)}\n${_vec('v', v)}',
          answer: Ans.integer(u[0] * v[0] + u[1] * v[1], negative: true),
        );
      case 1:
        final u = <int>[for (var i = 0; i < 3; i++) g.n(-5, 5)];
        final v = <int>[for (var i = 0; i < 3; i++) g.n(-5, 5)];
        return Question(
          topic: 'vectors',
          prompt: 'Find the dot product',
          text: '${_vec('u', u)}\n${_vec('v', v)}',
          answer: Ans.integer(
            u[0] * v[0] + u[1] * v[1] + u[2] * v[2],
            negative: true,
          ),
        );
      case 2:
        final (a, b, c, m) = g.pick(_quads);
        final parts = <int>[a, b, c]..shuffle(g.r);
        final w = <int>[for (final p in parts) p * g.sign()];
        return Question(
          topic: 'vectors',
          prompt: 'Find the magnitude',
          text: _vec('v', w),
          answer: Ans.integer(m),
        );
      default:
        final u = <int>[for (var i = 0; i < 3; i++) g.n(-4, 4)];
        final v = <int>[for (var i = 0; i < 3; i++) g.n(-4, 4)];
        final c = <double>[
          (u[1] * v[2] - u[2] * v[1]).toDouble(),
          (u[2] * v[0] - u[0] * v[2]).toDouble(),
          (u[0] * v[1] - u[1] * v[0]).toDouble(),
        ];
        return Question(
          topic: 'vectors',
          prompt: 'Find the cross product, written as x, y, z',
          text: '${_vec('u', u)}\n${_vec('v', v)}',
          answer: ListAnswer(c),
        );
    }
  }

  static Question modular(Gen g) {
    final variants = g.d == 1
        ? const <int>[0]
        : (g.d == 2 ? const <int>[0, 1] : const <int>[1, 2]);
    switch (g.pick(variants)) {
      case 0:
        final m = g.n(3, 12);
        final a = g.n(20, g.by(100, 300, 999));
        return Question(
          topic: 'modular',
          prompt: 'Find the remainder',
          text: '$a mod $m',
          answer: Ans.integer(a % m),
        );
      case 1:
        final a = g.n(2, 9);
        final e = g.n(2, 6);
        final m = g.n(3, 13);
        var r = 1;
        for (var i = 0; i < e; i++) {
          r = r * a % m;
        }
        return Question(
          topic: 'modular',
          prompt: 'Find the remainder',
          text: '$a^$e mod $m',
          answer: Ans.integer(r),
        );
      default:
        final m = g.pick(const <int>[5, 7, 11, 13]);
        final a = g.n(2, m - 1);
        final x = g.n(0, m - 1);
        return Question(
          topic: 'modular',
          prompt: 'Find the least non-negative solution x',
          text: '${a}x ≡ ${a * x % m} (mod $m)',
          answer: Ans.integer(x),
        );
    }
  }

  static Question bases(Gen g) {
    final n = g.n(g.by(3, 32, 256), g.by(31, 255, 1023));
    final variants = g.d == 3 ? const <int>[0, 1, 2] : const <int>[0, 1];
    switch (g.pick(variants)) {
      case 0:
        return Question(
          topic: 'bases',
          prompt: 'Convert to binary',
          text: '${n}_{10}',
          answer: ExactAnswer(n.toRadixString(2)),
        );
      case 1:
        return Question(
          topic: 'bases',
          prompt: 'Convert to decimal',
          text: '${n.toRadixString(2)}_{2}',
          answer: Ans.integer(n),
        );
      default:
        return Question(
          topic: 'bases',
          prompt: 'Convert to octal',
          text: '${n}_{10}',
          answer: ExactAnswer(n.toRadixString(8)),
        );
    }
  }

  static (List<int>, int) _dataset(Gen g, {required bool square}) {
    for (var attempt = 0; attempt < 400; attempt++) {
      final n = g.n(4, 6);
      final values = <int>[for (var i = 0; i < n; i++) g.n(1, 20)];
      final sum = values.fold(0, (a, b) => a + b);
      if (sum % n != 0) continue;
      final mean = sum ~/ n;
      final sq = values.fold(0, (a, b) => a + (b - mean) * (b - mean));
      if (sq % n != 0) continue;
      final variance = sq ~/ n;
      if (square) {
        final root = math.sqrt(variance).round();
        if (root * root != variance || variance == 0) continue;
      } else if (variance == 0) {
        continue;
      }
      return (values, variance);
    }
    return (const <int>[2, 4, 4, 4, 5, 5, 7, 9], 4);
  }

  static Question variance(Gen g) {
    final variants = g.d == 1
        ? const <int>[2]
        : (g.d == 2 ? const <int>[0, 1] : const <int>[3, 1, 0]);
    switch (g.pick(variants)) {
      case 0:
        final (values, v) = _dataset(g, square: false);
        return Question(
          topic: 'variance',
          prompt: 'Find the population variance',
          text: values.join(', '),
          answer: Ans.integer(v),
        );
      case 1:
        final n = g.n(3, 8);
        final k = g.n(0, n);
        return Question(
          topic: 'variance',
          prompt: 'Find the probability',
          text: 'X ~ Bin($n, ${_f(1, 2)})\nP(X = $k)',
          answer: Ans.rational(Rational(_choose(n, k), 1 << n)),
        );
      case 2:
        final q = g.n(2, 5);
        final n = q * g.n(2, 6);
        return Question(
          topic: 'variance',
          prompt: 'Find the expected value',
          text: 'X ~ Bin($n, ${_f(1, q)})',
          answer: Ans.integer(n ~/ q),
        );
      default:
        final (values, v) = _dataset(g, square: true);
        return Question(
          topic: 'variance',
          prompt: 'Find the population standard deviation',
          text: values.join(', '),
          answer: Ans.integer(math.sqrt(v).round()),
        );
    }
  }
}
