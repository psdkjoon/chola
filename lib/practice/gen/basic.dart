import 'dart:math';

import 'package:chola/localization/localization.dart';
import 'package:chola/math/answer.dart';
import 'package:chola/math/rational.dart';
import 'package:chola/practice/practice_config.dart';
import 'package:chola/practice/question.dart';

typedef Amount = ({int units, int scale});

abstract class Decimals {
  static int pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  static String format(int units, int scale) {
    var digits = units.abs().toString();
    var body = digits;
    if (scale > 0) {
      digits = digits.padLeft(scale + 1, '0');
      final cut = digits.length - scale;
      final whole = digits.substring(0, cut);
      final fraction = digits.substring(cut).replaceFirst(RegExp(r'0+$'), '');
      body = fraction.isEmpty ? whole : '$whole.$fraction';
    }
    return units < 0 && body != '0' ? '-$body' : body;
  }

  static int places(String answer) {
    final dot = answer.indexOf('.');
    return dot < 0 ? 0 : answer.length - dot - 1;
  }
}

typedef _Build = Question Function(Gen g, bool whole);

abstract class Arithmetic {
  static const List<int> _percents = <int>[5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 80, 90];

  static Question add(Gen g) => _fit(g, _add);
  static Question subtract(Gen g) => _fit(g, _subtract);
  static Question multiply(Gen g) => _fit(g, _multiply);
  static Question divide(Gen g) => _fit(g, _divide);
  static Question square(Gen g) => _fit(g, _square);
  static Question root(Gen g) => _fit(g, _root);
  static Question percent(Gen g) => _fit(g, _percent);

  static Question _fit(Gen g, _Build build) {
    for (var attempt = 0; attempt < 40; attempt++) {
      final q = build(g, false);
      if (Decimals.places(q.answer.shown) <= g.config.answerPlaces) return q;
    }
    return build(g, true);
  }

  static Question _q(Gen g, String id, String text, String answer) => Question(
        topic: id,
        text: text,
        answer: ValueAnswer(
          double.parse(answer),
          shownText: answer,
          negative: g.config.allowNegative,
          decimal: g.config.kind != NumberKind.whole,
        ),
      );

  static int _scale(Gen g, bool whole, [int cap = 3]) {
    if (whole) return 0;
    final places = min(g.config.decimalPlaces, cap);
    return switch (g.config.kind) {
      NumberKind.whole => 0,
      NumberKind.decimal => 1 + g.r.nextInt(places),
      NumberKind.mixed => g.r.nextBool() ? 0 : 1 + g.r.nextInt(places),
    };
  }

  static int _units(Gen g, int digits, int scale) {
    final low = Decimals.pow10(digits - 1);
    final high = Decimals.pow10(digits) - 1;
    var value = low + g.r.nextInt(high - low + 1);
    if (scale > 0 && value % 10 == 0) value += 1 + g.r.nextInt(9);
    return value;
  }

  static Amount _amount(Gen g, bool whole, int digits, [int cap = 3]) {
    final scale = _scale(g, whole, cap);
    return (units: _units(g, digits, scale), scale: scale);
  }

  static String _show(Amount a) => Decimals.format(a.units, a.scale);

  static int _align(Amount a, int scale) =>
      a.units * Decimals.pow10(scale - a.scale);

  static Question _add(Gen g, bool whole) {
    final a = _amount(g, whole, g.config.leftDigits);
    final b = _amount(g, whole, g.config.rightDigits);
    final scale = max(a.scale, b.scale);
    return _q(g, 'add', '${_show(a)} + ${_show(b)}',
        Decimals.format(_align(a, scale) + _align(b, scale), scale));
  }

  static Question _subtract(Gen g, bool whole) {
    var a = _amount(g, whole, g.config.leftDigits);
    var b = _amount(g, whole, g.config.rightDigits);
    final scale = max(a.scale, b.scale);
    final swap = g.config.allowNegative
        ? g.r.nextBool()
        : _align(a, scale) < _align(b, scale);
    if (swap) {
      final held = a;
      a = b;
      b = held;
    }
    return _q(g, 'subtract', '${_show(a)} - ${_show(b)}',
        Decimals.format(_align(a, scale) - _align(b, scale), scale));
  }

  static Question _multiply(Gen g, bool whole) {
    final a = _amount(g, whole, g.config.leftDigits);
    final b = _amount(g, whole, g.config.rightDigits);
    return _q(g, 'multiply', '${_show(a)} × ${_show(b)}',
        Decimals.format(a.units * b.units, a.scale + b.scale));
  }

  static Question _divide(Gen g, bool whole) {
    final divisorScale =
        g.config.kind != NumberKind.whole && !whole && g.r.nextInt(3) == 0
            ? 1
            : 0;
    var divisorUnits = _units(g, g.config.rightDigits, divisorScale);
    if (divisorUnits == 1 && divisorScale == 0) {
      divisorUnits = 2 + g.r.nextInt(8);
    }
    final divisor = (units: divisorUnits, scale: divisorScale);
    final quotient =
        _amount(g, whole, max(1, g.config.leftDigits - g.config.rightDigits));
    return _q(
      g,
      'divide',
      '${Decimals.format(divisor.units * quotient.units, divisor.scale + quotient.scale)} ÷ ${_show(divisor)}',
      _show(quotient),
    );
  }

  static Question _square(Gen g, bool whole) {
    final a = _amount(g, whole, min(g.config.leftDigits, 4), 2);
    return _q(g, 'square', '${_show(a)}^2',
        Decimals.format(a.units * a.units, a.scale * 2));
  }

  static Question _root(Gen g, bool whole) {
    final r = _amount(g, whole, max(1, (g.config.leftDigits + 1) ~/ 2), 1);
    return _q(
      g,
      'root',
      '\\sqrt{${Decimals.format(r.units * r.units, r.scale * 2)}}',
      _show(r),
    );
  }

  static Question _percent(Gen g, bool whole) {
    final percent = _percents[g.r.nextInt(_percents.length)];
    final digits = max(2, g.config.leftDigits);
    final Amount base;
    if (g.config.kind == NumberKind.whole || whole) {
      final multiples = Decimals.pow10(digits) ~/ 20;
      base = (units: 20 * (1 + g.r.nextInt(multiples)), scale: 0);
    } else {
      base = _amount(g, false, digits, 1);
    }
    return _q(
      g,
      'percent',
      '$percent% ${L10n.tr('of')} ${_show(base)}',
      Decimals.format(percent * base.units, base.scale + 2),
    );
  }
}

abstract class Sense {
  static Question missing(Gen g) {
    final hi = g.by(10, 20, 100);
    final ops = g.d == 1 ? const <String>['+', '-'] : const <String>['+', '-', '×', '÷'];
    final op = g.pick(ops);
    final left = g.chance();
    final String text;
    final int ans;
    switch (op) {
      case '+':
        final a = g.n(1, hi);
        final b = g.n(1, hi);
        text = left ? '? + $b = ${a + b}' : '$a + ? = ${a + b}';
        ans = left ? a : b;
      case '-':
        final b = g.n(1, hi);
        final a = b + g.n(1, hi);
        text = left ? '? - $b = ${a - b}' : '$a - ? = ${a - b}';
        ans = left ? a : b;
      case '×':
        final a = g.n(2, g.by(5, 9, 12));
        final b = g.n(2, g.by(5, 9, 12));
        text = left ? '? × $b = ${a * b}' : '$a × ? = ${a * b}';
        ans = left ? a : b;
      default:
        final b = g.n(2, g.by(5, 9, 12));
        final q = g.n(2, g.by(5, 9, 12));
        text = left ? '? ÷ $b = $q' : '${b * q} ÷ ? = $q';
        ans = left ? b * q : b;
    }
    return Question(
      topic: 'missing',
      prompt: 'Find the missing number',
      text: text,
      answer: Ans.integer(ans),
    );
  }

  static Question order(Gen g) {
    final String text;
    final int v;
    final t = g.n(0, g.by(2, 6, 10));
    switch (t) {
      case 0:
        final a = g.n(1, 20), b = g.n(2, 9), c = g.n(2, 9);
        text = '$a + $b × $c';
        v = a + b * c;
      case 1:
        final a = g.n(2, 9), b = g.n(2, 9);
        final c = g.n(1, a * b - 1);
        text = '$a × $b - $c';
        v = a * b - c;
      case 2:
        final a = g.n(10, 40), b = g.n(1, 9), c = g.n(1, 9);
        text = '$a - $b + $c';
        v = a - b + c;
      case 3:
        final a = g.n(1, 9), b = g.n(1, 9), c = g.n(2, 9);
        text = '($a + $b) × $c';
        v = (a + b) * c;
      case 4:
        final c = g.n(1, 8);
        final b = c + g.n(1, 8);
        final a = g.n(2, 9);
        text = '$a × ($b - $c)';
        v = a * (b - c);
      case 5:
        final c = g.n(2, 9), q = g.n(1, 9);
        final a = g.n(q + 1, q + 20);
        text = '$a - ${c * q} ÷ $c';
        v = a - q;
      case 6:
        final a = g.n(10, 30), b = g.n(2, 9), c = g.n(2, 9);
        final d = g.n(1, 9);
        text = '$a + $b × $c - $d';
        v = a + b * c - d;
      case 7:
        final d = g.n(1, 8);
        final c = d + g.n(1, 8);
        final a = g.n(1, 20), b = g.n(2, 9);
        text = '$a + $b × ($c - $d)';
        v = a + b * (c - d);
      case 8:
        final a = g.n(1, 9), b = g.n(1, 9);
        final d = g.n(1, 8);
        final c = d + g.n(1, 8);
        text = '($a + $b) × ($c - $d)';
        v = (a + b) * (c - d);
      case 9:
        final a = g.n(2, 9), b = g.n(2, 9), c = g.n(2, 9);
        text = '$a^2 - $b × $c';
        v = a * a - b * c;
      default:
        final a = g.n(2, 9), b = g.n(2, 9);
        final d = g.n(2, 6), q = g.n(2, 9);
        text = '$a × $b - ${d * q} ÷ $d';
        v = a * b - q;
    }
    return Question(
      topic: 'order',
      prompt: 'Follow the order of operations',
      text: text,
      answer: Ans.integer(v, negative: g.d == 3),
    );
  }

  static Question rounding(Gen g) {
    final kinds = g.d == 1
        ? const <int>[0, 1]
        : (g.d == 2 ? const <int>[0, 1, 2] : const <int>[0, 1, 2, 3]);
    final kind = g.pick(kinds);
    final big = g.d == 3;
    switch (kind) {
      case 0:
        final x = g.n(11, big ? 99999 : 999);
        return Question(
          topic: 'rounding',
          prompt: 'Round to the nearest ten',
          text: '$x',
          answer: Ans.integer(((x + 5) ~/ 10) * 10),
        );
      case 1:
        final x = g.n(101, big ? 999999 : 9999);
        return Question(
          topic: 'rounding',
          prompt: 'Round to the nearest hundred',
          text: '$x',
          answer: Ans.integer(((x + 50) ~/ 100) * 100),
        );
      case 2:
        final u = g.n(101, 9999);
        return Question(
          topic: 'rounding',
          prompt: 'Round to the nearest whole number',
          text: Fmt.number(u / 10),
          answer: Ans.integer((u + 5) ~/ 10),
        );
      default:
        final u = g.n(1001, 99999);
        return Question(
          topic: 'rounding',
          prompt: 'Round to the nearest tenth',
          text: Fmt.number(u / 100),
          answer: Ans.decimal(((u + 5) ~/ 10) / 10),
        );
    }
  }

  static Question remainder(Gen g) {
    final div = g.n(2, g.by(5, 9, 12));
    final q = g.n(2, g.by(9, 20, 60));
    final rem = g.n(1, div - 1);
    return Question(
      topic: 'remainder',
      prompt: 'Write the quotient, then the remainder, separated by a comma',
      text: '${div * q + rem} ÷ $div',
      answer: ListAnswer(
        <double>[q.toDouble(), rem.toDouble()],
        negative: false,
      ),
    );
  }

  static Question factors(Gen g) {
    final gcdMax = g.by(3, 12, 20);
    final span = g.by(6, 9, 12);
    final gc = g.n(1, gcdMax);
    var p = g.n(2, span);
    var q = g.n(2, span);
    while (p == q || Rational.gcd(p, q) != 1) {
      p = g.n(2, span);
      q = g.n(2, span);
    }
    final a = gc * p;
    final b = gc * q;
    final lcm = g.chance();
    return Question(
      topic: 'factors',
      prompt: lcm ? 'Least common multiple' : 'Greatest common divisor',
      text: '$a, $b',
      answer: Ans.integer(lcm ? gc * p * q : gc),
    );
  }

  static const List<(String, String, int)> _units = <(String, String, int)>[
    ('km', 'm', 1000),
    ('m', 'cm', 100),
    ('cm', 'mm', 10),
    ('m', 'mm', 1000),
    ('kg', 'g', 1000),
    ('t', 'kg', 1000),
    ('L', 'mL', 1000),
    ('h', 'min', 60),
    ('min', 's', 60),
  ];

  static Question units(Gen g) {
    final (big, small, f) = g.pick(_units);
    final k = g.by(0, 1, 2);
    final u = g.n(1, g.by(20, 99, 999));
    final scale = Decimals.pow10(k);
    final bigAmount = u / scale;
    final smallAmount = u * f / scale;
    final forward = g.d == 1 ? true : g.chance();
    return Question(
      topic: 'units',
      prompt: 'Convert the units',
      text: forward
          ? '${Fmt.number(bigAmount)} $big = ? $small'
          : '${Fmt.number(smallAmount)} $small = ? $big',
      answer: Ans.decimal(forward ? smallAmount : bigAmount),
    );
  }
}
