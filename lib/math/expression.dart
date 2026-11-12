import 'dart:math' as math;

class Poly {
  const Poly(this.c);

  factory Poly.constant(double v) => Poly(<double>[v]);

  final List<double> c;

  double at(int i) => i < c.length ? c[i] : 0;

  int get degree {
    for (var i = c.length - 1; i > 0; i--) {
      if (c[i].abs() > 1e-12) return i;
    }
    return 0;
  }

  bool get isConstant => degree == 0;
  double get constant => at(0);

  Poly operator +(Poly o) {
    final n = math.max(c.length, o.c.length);
    return Poly(<double>[for (var i = 0; i < n; i++) at(i) + o.at(i)]);
  }

  Poly operator -(Poly o) {
    final n = math.max(c.length, o.c.length);
    return Poly(<double>[for (var i = 0; i < n; i++) at(i) - o.at(i)]);
  }

  Poly operator -() => Poly(<double>[for (final v in c) -v]);

  Poly operator *(Poly o) {
    final out = List<double>.filled(c.length + o.c.length - 1, 0);
    for (var i = 0; i < c.length; i++) {
      for (var j = 0; j < o.c.length; j++) {
        out[i + j] += c[i] * o.c[j];
      }
    }
    return Poly(out);
  }

  Poly scaled(double k) => Poly(<double>[for (final v in c) v * k]);

  bool close(Poly o) {
    final n = math.max(c.length, o.c.length);
    for (var i = 0; i < n; i++) {
      if (!Expression.near(at(i), o.at(i))) return false;
    }
    return true;
  }

  int get terms {
    var count = 0;
    for (final v in c) {
      if (v.abs() > 1e-9) count++;
    }
    return count == 0 ? 1 : count;
  }
}

abstract class Expression {
  static bool near(double a, double b) =>
      (a - b).abs() <= 1e-9 * math.max(1.0, math.max(a.abs(), b.abs()));

  static Poly? polynomial(String text, {String variable = 'x'}) {
    try {
      return _Parser(text.replaceAll(' ', ''), variable).parse();
    } on _Fail {
      return null;
    }
  }

  static double? value(String text) {
    final p = polynomial(text, variable: '');
    if (p == null || !p.isConstant) return null;
    return p.constant;
  }
}

class _Fail implements Exception {
  const _Fail();
}

class _Parser {
  _Parser(this.s, this.v);

  final String s;
  final String v;
  int p = 0;

  Poly parse() {
    if (s.isEmpty) throw const _Fail();
    final r = _expr();
    if (p != s.length) throw const _Fail();
    return _finite(r);
  }

  Poly _finite(Poly r) {
    for (final x in r.c) {
      if (x.isNaN || x.isInfinite) throw const _Fail();
    }
    return r;
  }

  bool _isDigit(String ch) {
    final u = ch.codeUnitAt(0);
    return u >= 48 && u <= 57;
  }

  bool _startsAtom(String ch) =>
      ch == '(' ||
      ch == '√' ||
      ch == 'π' ||
      (v.isNotEmpty && ch == v) ||
      _isDigit(ch);

  Poly _expr() {
    var r = _term();
    while (p < s.length && (s[p] == '+' || s[p] == '-')) {
      final plus = s[p] == '+';
      p++;
      final t = _term();
      r = plus ? r + t : r - t;
    }
    return r;
  }

  Poly _term() {
    var r = _unary();
    while (p < s.length) {
      final ch = s[p];
      if (ch == '*' || ch == '×' || ch == '·') {
        p++;
        r = r * _unary();
      } else if (ch == '/') {
        p++;
        final d = _unary();
        if (!d.isConstant || d.constant.abs() < 1e-12) throw const _Fail();
        r = r.scaled(1 / d.constant);
      } else if (_startsAtom(ch)) {
        r = r * _power();
      } else {
        break;
      }
    }
    return r;
  }

  Poly _unary() {
    if (p < s.length && s[p] == '-') {
      p++;
      return -_unary();
    }
    if (p < s.length && s[p] == '+') {
      p++;
      return _unary();
    }
    return _power();
  }

  Poly _power() {
    final base = _atom();
    if (p < s.length && s[p] == '^') {
      p++;
      return _pow(base, _exponent());
    }
    return base;
  }

  Poly _exponent() {
    if (p < s.length && s[p] == '-') {
      p++;
      return -_exponent();
    }
    if (p < s.length && s[p] == '+') {
      p++;
    }
    return _power();
  }

  Poly _pow(Poly base, Poly e) {
    if (!e.isConstant) throw const _Fail();
    final k = e.constant;
    if (base.isConstant) {
      final r = math.pow(base.constant, k).toDouble();
      if (r.isNaN || r.isInfinite) throw const _Fail();
      return Poly.constant(r);
    }
    final whole = k.roundToDouble();
    if ((k - whole).abs() > 1e-9 || whole < 0 || whole > 12) {
      throw const _Fail();
    }
    final times = whole.toInt();
    if (base.degree * times > 24) throw const _Fail();
    var out = Poly.constant(1);
    for (var i = 0; i < times; i++) {
      out = out * base;
    }
    return out;
  }

  Poly _atom() {
    if (p >= s.length) throw const _Fail();
    final ch = s[p];
    if (ch == '(') {
      p++;
      final r = _expr();
      if (p >= s.length || s[p] != ')') throw const _Fail();
      p++;
      return r;
    }
    if (ch == '√') {
      p++;
      final a = _atom();
      if (!a.isConstant || a.constant < 0) throw const _Fail();
      return Poly.constant(math.sqrt(a.constant));
    }
    if (ch == 'π') {
      p++;
      return Poly.constant(math.pi);
    }
    if (v.isNotEmpty && ch == v) {
      p++;
      return const Poly(<double>[0, 1]);
    }
    if (_isDigit(ch)) {
      final start = p;
      while (p < s.length && _isDigit(s[p])) {
        p++;
      }
      if (p < s.length && s[p] == '.') {
        p++;
        final f = p;
        while (p < s.length && _isDigit(s[p])) {
          p++;
        }
        if (p == f) throw const _Fail();
      }
      return Poly.constant(double.parse(s.substring(start, p)));
    }
    throw const _Fail();
  }
}
