import 'package:chola/practice/gen/advanced.dart';
import 'package:chola/practice/gen/algebra.dart';
import 'package:chola/practice/gen/basic.dart';
import 'package:chola/practice/gen/fractions.dart';
import 'package:chola/practice/gen/geometry.dart';
import 'package:chola/practice/gen/university.dart';
import 'package:chola/practice/question.dart';

enum Level {
  elementary('Elementary', 'Grades 1–6'),
  middle('Middle school', 'Grades 7–9'),
  high('High school', 'Grades 10–12'),
  university('University', 'College level');

  const Level(this.label, this.range);

  final String label;
  final String range;
}

typedef Maker = Question Function(Gen g);

class Topic {
  const Topic(
    this.id,
    this.level,
    this.category,
    this.label,
    this.example,
    this.make, {
    this.usesNumbers = false,
  });

  final String id;
  final Level level;
  final String category;
  final String label;
  final String example;
  final Maker make;
  final bool usesNumbers;
}

abstract class Topics {
  static final List<Topic> all = <Topic>[
    const Topic('add', Level.elementary, 'Arithmetic', 'Add', '23 + 48', Arithmetic.add, usesNumbers: true),
    const Topic('subtract', Level.elementary, 'Arithmetic', 'Subtract', '82 - 37', Arithmetic.subtract, usesNumbers: true),
    const Topic('multiply', Level.elementary, 'Arithmetic', 'Multiply', '14 × 6', Arithmetic.multiply, usesNumbers: true),
    const Topic('divide', Level.elementary, 'Arithmetic', 'Divide', '84 ÷ 7', Arithmetic.divide, usesNumbers: true),
    const Topic('square', Level.elementary, 'Arithmetic', 'Square', '12^2', Arithmetic.square, usesNumbers: true),
    const Topic('root', Level.elementary, 'Arithmetic', 'Root', '\\sqrt{144}', Arithmetic.root, usesNumbers: true),
    const Topic('percent', Level.elementary, 'Arithmetic', 'Percent', '25% × 80', Arithmetic.percent, usesNumbers: true),
    const Topic('missing', Level.elementary, 'Number sense', 'Missing number', '7 + ? = 15', Sense.missing),
    const Topic('order', Level.elementary, 'Number sense', 'Order of operations', '3 + 4 × 2', Sense.order),
    const Topic('rounding', Level.elementary, 'Number sense', 'Rounding', '4367 ≈ 4400', Sense.rounding),
    const Topic('remainder', Level.elementary, 'Number sense', 'Division with remainder', '47 ÷ 5', Sense.remainder),
    const Topic('factors', Level.elementary, 'Number sense', 'GCD and LCM', 'gcd(12, 18)', Sense.factors),
    const Topic('units', Level.elementary, 'Number sense', 'Unit conversion', '3.5 km = ? m', Sense.units),
    const Topic('frac_simplify', Level.elementary, 'Fractions', 'Simplify fractions', '\\frac{6}{8} = \\frac{3}{4}', Fractions.simplify),
    const Topic('frac_add', Level.elementary, 'Fractions', 'Add and subtract fractions', '\\frac{1}{2} + \\frac{1}{3}', Fractions.add),
    const Topic('frac_mul', Level.elementary, 'Fractions', 'Multiply and divide fractions', '\\frac{2}{3} × \\frac{3}{4}', Fractions.multiply),
    const Topic('frac_of', Level.elementary, 'Fractions', 'Fraction of a number', '\\frac{3}{4} × 24', Fractions.of),
    const Topic('mixed', Level.elementary, 'Fractions', 'Mixed numbers', '2\\frac{1}{3} = \\frac{7}{3}', Fractions.mixed),
    const Topic('frac_compare', Level.elementary, 'Fractions', 'Compare fractions', '\\frac{3}{4} ? \\frac{2}{3}', Fractions.compare),
    const Topic('frac_decimal', Level.elementary, 'Fractions', 'Fractions and decimals', '\\frac{3}{8} = 0.375', Fractions.decimals),
    const Topic('integers', Level.middle, 'Numbers and ratios', 'Negative numbers', '-7 + 4', Algebra.integers),
    const Topic('powers', Level.middle, 'Numbers and ratios', 'Powers and roots', '2^5, \\sqrt[3]{27}', Algebra.powers),
    const Topic('ratio', Level.middle, 'Numbers and ratios', 'Ratio and proportion', '12 : 18', Algebra.ratio),
    const Topic('percentp', Level.middle, 'Numbers and ratios', 'Percent problems', '80 + 15%', Algebra.percentProblems),
    const Topic('evaluate', Level.middle, 'Algebra', 'Evaluate expressions', '3x + 2, x = 4', Algebra.evaluate),
    const Topic('terms', Level.middle, 'Algebra', 'Simplify expressions', '3(x + 4) - 2x', Algebra.simplify),
    const Topic('eq1', Level.middle, 'Algebra', 'One- and two-step equations', '2x + 3 = 11', Algebra.eq1),
    const Topic('eq2', Level.middle, 'Algebra', 'Multi-step equations', '5x - 3 = 2x + 9', Algebra.eq2),
    const Topic('ineq', Level.middle, 'Algebra', 'Inequalities', '3x - 5 > 7', Algebra.inequality),
    const Topic('system', Level.middle, 'Algebra', 'Systems of equations', 'x + y = 7, x - y = 3', Algebra.system),
    const Topic('lines', Level.middle, 'Algebra', 'Lines and slope', 'y = 2x - 6', Algebra.lines),
    const Topic('area', Level.middle, 'Geometry', 'Area and perimeter', 'A = w × h', Geometry.area),
    const Topic('pyth', Level.middle, 'Geometry', 'Pythagorean theorem', 'a^2 + b^2 = c^2', Geometry.pythagoras),
    const Topic('volume', Level.middle, 'Geometry', 'Volume', 'V = πr^2h', Geometry.volume),
    const Topic('angles', Level.middle, 'Geometry', 'Angles', '50° + 60° + ?', Geometry.angles),
    const Topic('coords', Level.middle, 'Geometry', 'Distance and midpoint', '(1, 2), (4, 6)', Geometry.coords),
    const Topic('stats', Level.middle, 'Data', 'Mean, median, mode', '4, 8, 6, 5, 3', Geometry.stats),
    const Topic('prob', Level.middle, 'Data', 'Probability', 'P(A) = \\frac{3}{8}', Geometry.probability),
    const Topic('quad', Level.high, 'Algebra', 'Quadratic equations', 'x^2 - 5x + 6 = 0', Advanced.quadratic),
    const Topic('factor', Level.high, 'Algebra', 'Factoring', 'x^2 + 5x + 6', Advanced.factor),
    const Topic('polyops', Level.high, 'Algebra', 'Expanding polynomials', '(x + 2)(x + 3)', Advanced.expand),
    const Topic('abs', Level.high, 'Algebra', 'Absolute value', '|x - 3| = 5', Advanced.absolute),
    const Topic('parabola', Level.high, 'Algebra', 'Parabolas', 'y = x^2 - 4x + 1', Advanced.parabola),
    const Topic('functions', Level.high, 'Algebra', 'Functions', 'f(g(x)), f^-1(x)', Advanced.functions),
    const Topic('radicals', Level.high, 'Algebra', 'Simplifying radicals', '\\sqrt{72}', Advanced.radicals),
    const Topic('complex', Level.high, 'Algebra', 'Complex numbers', '(2 + 3i)(1 - i)', Advanced.complex),
    const Topic('logs', Level.high, 'Exponents and logs', 'Logarithms', 'log_{2} 32', Advanced.logs),
    const Topic('expeq', Level.high, 'Exponents and logs', 'Exponential equations', '2^x = 32', Advanced.exponentialEquation),
    const Topic('trig', Level.high, 'Trigonometry', 'Exact trig values', 'sin 30°', Advanced.trig),
    const Topic('radians', Level.high, 'Trigonometry', 'Degrees and radians', '180° = π', Advanced.radians),
    const Topic('seq', Level.high, 'Sequences and counting', 'Sequences', '3, 7, 11, …', Advanced.sequences),
    const Topic('comb', Level.high, 'Sequences and counting', 'Counting', 'C(7, 3)', Advanced.counting),
    const Topic('limits', Level.university, 'Calculus', 'Limits', 'lim_{x→2} \\frac{x^2 - 4}{x - 2}', University.limits),
    const Topic('deriv', Level.university, 'Calculus', 'Derivatives', 'f(x) = 3x^4 - 2x^2', University.derivative),
    const Topic('derivpt', Level.university, 'Calculus', 'Derivative at a point', 'f\u2032(2)', University.derivativeAt),
    const Topic('integral', Level.university, 'Calculus', 'Integrals', '∫ 6x^2 dx', University.integral),
    const Topic('optimize', Level.university, 'Calculus', 'Maxima and minima', 'f\u2032(x) = 0', University.optimize),
    const Topic('series', Level.university, 'Calculus', 'Sums and series', 'Σ_{k=1}^{n} k', University.series),
    const Topic('det', Level.university, 'Linear algebra', 'Determinants', '\\det{1,2;3,4}', University.determinant),
    const Topic('matrix', Level.university, 'Linear algebra', 'Matrix arithmetic', '\\mat{1,2;3,4}', University.matrix),
    const Topic('eigen', Level.university, 'Linear algebra', 'Eigenvalues', 'Av = λv', University.eigen),
    const Topic('vectors', Level.university, 'Linear algebra', 'Vectors', 'u · v', University.vectors),
    const Topic('modular', Level.university, 'Discrete and statistics', 'Modular arithmetic', '17 mod 5', University.modular),
    const Topic('bases', Level.university, 'Discrete and statistics', 'Number bases', '1011_{2}', University.bases),
    const Topic('variance', Level.university, 'Discrete and statistics', 'Variance and binomials', 'σ^2, Bin(n, p)', University.variance),
  ];

  static final Map<String, Topic> _byId = <String, Topic>{
    for (final topic in all) topic.id: topic,
  };

  static Topic? byId(String id) => _byId[id];

  static List<Topic> forLevel(Level level) => <Topic>[
        for (final topic in all)
          if (topic.level == level) topic,
      ];

  static List<String> categories(Level level) {
    final out = <String>[];
    for (final topic in forLevel(level)) {
      if (!out.contains(topic.category)) out.add(topic.category);
    }
    return out;
  }

  static List<Topic> inCategory(Level level, String category) => <Topic>[
        for (final topic in forLevel(level))
          if (topic.category == category) topic,
      ];

  static Level levelNamed(String name) {
    for (final level in Level.values) {
      if (level.name == name) return level;
    }
    return Level.elementary;
  }
}
