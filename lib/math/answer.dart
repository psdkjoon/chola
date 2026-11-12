import 'package:chola/math/expression.dart';
import 'package:chola/math/rational.dart';

abstract class Answer {
  const Answer();

  String get shown;
  List<String> get keys;
  bool matches(String input);
}

class ValueAnswer extends Answer {
  const ValueAnswer(
    this.value, {
    this.shownText,
    this.reduced = false,
    this.negative = false,
    this.decimal = false,
    this.fraction = false,
    this.symbols = const <String>[],
  });

  final double value;
  final String? shownText;
  final bool reduced;
  final bool negative;
  final bool decimal;
  final bool fraction;
  final List<String> symbols;

  @override
  String get shown => shownText ?? Fmt.number(value);

  @override
  List<String> get keys => <String>[
        if (negative) '-',
        if (decimal) '.',
        if (fraction) '/',
        ...symbols,
      ];

  @override
  bool matches(String input) {
    final t = input.trim();
    if (t.isEmpty) return false;
    if (reduced && !_lowest(t)) return false;
    final v = Expression.value(t);
    return v != null && Expression.near(v, value);
  }

  static bool _lowest(String t) {
    final m = RegExp(r'^-?(\d+)(?:/(\d+))?$').firstMatch(t);
    if (m == null) return false;
    final den = m.group(2);
    if (den == null) return true;
    final a = int.tryParse(m.group(1)!);
    final b = int.tryParse(den);
    if (a == null || b == null) return false;
    return b > 1 && Rational.gcd(a, b) == 1;
  }
}

class ExactAnswer extends Answer {
  const ExactAnswer(
    this.text, {
    this.shownText,
    this.symbols = const <String>[],
  });

  final String text;
  final String? shownText;
  final List<String> symbols;

  @override
  String get shown => shownText ?? text;

  @override
  List<String> get keys => symbols;

  @override
  bool matches(String input) =>
      input.trim().replaceAll(RegExp(r'\s+'), ' ') == text;
}

class ListAnswer extends Answer {
  const ListAnswer(
    this.values, {
    this.ordered = true,
    this.shownParts,
    this.negative = true,
    this.decimal = false,
    this.fraction = false,
  });

  final List<double> values;
  final bool ordered;
  final List<String>? shownParts;
  final bool negative;
  final bool decimal;
  final bool fraction;

  @override
  String get shown =>
      (shownParts ?? <String>[for (final v in values) Fmt.number(v)])
          .join(', ');

  @override
  List<String> get keys => <String>[
        if (negative) '-',
        if (decimal) '.',
        if (fraction) '/',
        ',',
      ];

  @override
  bool matches(String input) {
    final got = <double>[];
    for (final part in input.trim().split(',')) {
      final v = Expression.value(part);
      if (v == null) return false;
      got.add(v);
    }
    if (ordered) {
      if (got.length != values.length) return false;
      for (var i = 0; i < got.length; i++) {
        if (!Expression.near(got[i], values[i])) return false;
      }
      return true;
    }
    final a = _distinct(got);
    final b = _distinct(values);
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!Expression.near(a[i], b[i])) return false;
    }
    return true;
  }

  static List<double> _distinct(List<double> xs) {
    final sorted = List<double>.of(xs)..sort();
    final out = <double>[];
    for (final v in sorted) {
      if (out.isEmpty || !Expression.near(out.last, v)) out.add(v);
    }
    return out;
  }
}

enum ExprForm { any, expanded, factored }

class ExprAnswer extends Answer {
  ExprAnswer(
    this.poly,
    this.shownText, {
    this.form = ExprForm.expanded,
    this.fraction = false,
  });

  final Poly poly;
  final String shownText;
  final ExprForm form;
  final bool fraction;

  @override
  String get shown => shownText;

  @override
  List<String> get keys => <String>[
        '-',
        if (fraction) '/',
        'x',
        '^',
        '+',
        if (form != ExprForm.expanded) ...<String>['(', ')'],
      ];

  @override
  bool matches(String input) {
    final t = input.replaceAll(' ', '');
    if (t.isEmpty) return false;
    final got = Expression.polynomial(t);
    if (got == null || !got.close(poly)) return false;
    switch (form) {
      case ExprForm.any:
        return true;
      case ExprForm.expanded:
        return !t.contains('(') && _terms(t) == poly.terms;
      case ExprForm.factored:
        return _factored(t);
    }
  }

  static int _terms(String t) {
    var count = 1;
    for (var i = 1; i < t.length; i++) {
      if ((t[i] == '+' || t[i] == '-') && t[i - 1] != '^') count++;
    }
    return count;
  }

  static bool _factored(String t) {
    var depth = 0;
    var groups = 0;
    for (var i = 0; i < t.length; i++) {
      final ch = t[i];
      if (ch == '(') {
        if (depth == 0) groups++;
        depth++;
      } else if (ch == ')') {
        depth--;
      } else if (depth == 0 && i > 0 && (ch == '+' || ch == '-')) {
        if (t[i - 1] != '^') return false;
      } else if (depth > 0 && ch == '^' && i + 1 < t.length) {
        final u = t.codeUnitAt(i + 1);
        if (u >= 50 && u <= 57) return false;
        if (u == 49 && i + 2 < t.length) {
          final w = t.codeUnitAt(i + 2);
          if (w >= 48 && w <= 57) return false;
        }
      }
    }
    return groups >= 1;
  }
}

class ComplexAnswer extends Answer {
  const ComplexAnswer(this.re, this.im);

  final double re;
  final double im;

  @override
  String get shown => Fmt.complex(re.round(), im.round());

  @override
  List<String> get keys => const <String>['-', 'i', '+'];

  @override
  bool matches(String input) {
    final poly = Expression.polynomial(input, variable: 'i');
    if (poly == null) return false;
    var a = 0.0;
    var b = 0.0;
    for (var k = 0; k < poly.c.length; k++) {
      final v = poly.c[k];
      switch (k % 4) {
        case 0:
          a += v;
        case 1:
          b += v;
        case 2:
          a -= v;
        default:
          b -= v;
      }
    }
    return Expression.near(a, re) && Expression.near(b, im);
  }
}

class RelationAnswer extends Answer {
  const RelationAnswer(this.relation, this.value, {this.fraction = false});

  final String relation;
  final double value;
  final bool fraction;

  static const Map<String, String> _flip = <String, String>{
    '<': '>',
    '>': '<',
    '≤': '≥',
    '≥': '≤',
  };

  @override
  String get shown => 'x $relation ${Fmt.number(value)}';

  @override
  List<String> get keys => <String>[
        '-',
        if (fraction) '/',
        'x',
        '<',
        '>',
        '≤',
        '≥',
      ];

  @override
  bool matches(String input) {
    final t = input.replaceAll(' ', '');
    final a = RegExp(r'^x([<>≤≥])(.+)$').firstMatch(t);
    if (a != null) {
      final v = Expression.value(a.group(2)!);
      return a.group(1) == relation && v != null && Expression.near(v, value);
    }
    final b = RegExp(r'^(.+?)([<>≤≥])x$').firstMatch(t);
    if (b != null) {
      final v = Expression.value(b.group(1)!);
      return _flip[b.group(2)] == relation &&
          v != null &&
          Expression.near(v, value);
    }
    return false;
  }
}

class RadicalAnswer extends Answer {
  const RadicalAnswer(this.coefficient, this.radicand);

  final int coefficient;
  final int radicand;

  @override
  String get shown => coefficient == 1
      ? '\\sqrt{$radicand}'
      : '$coefficient\\sqrt{$radicand}';

  @override
  List<String> get keys => const <String>['√'];

  @override
  bool matches(String input) {
    final m = RegExp(r'^(\d*)√(\d+)$').firstMatch(input.replaceAll(' ', ''));
    if (m == null) return false;
    final c = m.group(1)!.isEmpty ? 1 : int.tryParse(m.group(1)!);
    final r = int.tryParse(m.group(2)!);
    return c == coefficient && r == radicand;
  }
}

abstract class Ans {
  static ValueAnswer integer(int v, {bool negative = false}) =>
      ValueAnswer(v.toDouble(), negative: negative || v < 0);

  static ValueAnswer decimal(double v, {bool negative = false}) =>
      ValueAnswer(v, decimal: true, negative: negative || v < 0);

  static ValueAnswer rational(
    Rational r, {
    bool negative = false,
    bool reduced = true,
  }) =>
      ValueAnswer(
        r.value,
        shownText: r.markup,
        reduced: reduced,
        fraction: true,
        negative: negative || r.isNegative,
      );

  static ValueAnswer pi(Rational r) {
    final String text;
    if (r.n == 0) {
      text = '0';
    } else if (r.isInt) {
      text = r.n == 1 ? 'π' : '${r.n}π';
    } else {
      final top = r.n == 1 ? 'π' : '${r.n}π';
      text = '\\frac{$top}{${r.d}}';
    }
    return ValueAnswer(
      r.value * 3.141592653589793,
      shownText: text,
      fraction: true,
      symbols: const <String>['π'],
    );
  }

  static ExprAnswer poly(
    List<int> c, {
    ExprForm form = ExprForm.expanded,
  }) =>
      ExprAnswer(
        Poly(<double>[for (final v in c) v.toDouble()]),
        Fmt.poly(<Rational>[for (final v in c) Rational(v)]),
        form: form,
      );

  static ExprAnswer polyRational(
    List<Rational> c, {
    ExprForm form = ExprForm.expanded,
  }) =>
      ExprAnswer(
        Poly(<double>[for (final v in c) v.value]),
        Fmt.poly(c),
        form: form,
        fraction: true,
      );
}

abstract class Fmt {
  static String number(double v) {
    if ((v - v.roundToDouble()).abs() < 1e-9) return v.round().toString();
    var t = v.toStringAsFixed(6);
    t = t.replaceFirst(RegExp(r'0+$'), '');
    if (t.endsWith('.')) t = t.substring(0, t.length - 1);
    return t;
  }

  static String frac(Object a, Object b) => '\\frac{$a}{$b}';

  static String paren(int v) => v < 0 ? '($v)' : '$v';

  static String signed(int v) => v < 0 ? '- ${-v}' : '+ $v';

  static String poly(List<Rational> c, {String v = 'x'}) {
    final b = StringBuffer();
    var first = true;
    for (var k = c.length - 1; k >= 0; k--) {
      final co = c[k];
      if (co.n == 0) continue;
      final neg = co.n < 0;
      final body = _term(neg ? -co : co, k, v);
      if (first) {
        b.write(neg ? '-$body' : body);
        first = false;
      } else {
        b.write(neg ? ' - $body' : ' + $body');
      }
    }
    return first ? '0' : b.toString();
  }

  static String ints(List<int> c, {String v = 'x'}) =>
      poly(<Rational>[for (final k in c) Rational(k)], v: v);

  static String _term(Rational m, int k, String v) {
    if (k == 0) return m.markup;
    final part = k == 1 ? v : '$v^$k';
    if (m.n == 1 && m.d == 1) return part;
    return '${m.markup}$part';
  }

  static String linFactor(int r) {
    if (r == 0) return 'x';
    return r > 0 ? '(x - $r)' : '(x + ${-r})';
  }

  static String xy(int a, int b) {
    final s = StringBuffer();
    if (a != 0) {
      s.write(a == 1 ? 'x' : (a == -1 ? '-x' : '${a}x'));
    }
    if (b != 0) {
      final mag = b.abs();
      final t = mag == 1 ? 'y' : '${mag}y';
      if (s.isEmpty) {
        s.write(b < 0 ? '-$t' : t);
      } else {
        s.write(b < 0 ? ' - $t' : ' + $t');
      }
    }
    return s.toString();
  }

  static String complex(int a, int b) {
    if (b == 0) return '$a';
    final mag = b.abs();
    final t = mag == 1 ? 'i' : '${mag}i';
    if (a == 0) return b < 0 ? '-$t' : t;
    return b < 0 ? '$a - $t' : '$a + $t';
  }

  static List<int> mul(List<int> a, List<int> b) {
    final out = List<int>.filled(a.length + b.length - 1, 0);
    for (var i = 0; i < a.length; i++) {
      for (var j = 0; j < b.length; j++) {
        out[i + j] += a[i] * b[j];
      }
    }
    return out;
  }

  static List<int> add(List<int> a, List<int> b, [int sign = 1]) {
    final n = a.length > b.length ? a.length : b.length;
    return <int>[
      for (var i = 0; i < n; i++)
        (i < a.length ? a[i] : 0) + sign * (i < b.length ? b[i] : 0),
    ];
  }

  static List<int> derive(List<int> c) {
    if (c.length <= 1) return <int>[0];
    return <int>[for (var k = 1; k < c.length; k++) k * c[k]];
  }

  static int evalAt(List<int> c, int x) {
    var out = 0;
    for (var k = c.length - 1; k >= 0; k--) {
      out = out * x + c[k];
    }
    return out;
  }
}
