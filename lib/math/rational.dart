class Rational implements Comparable<Rational> {
  const Rational._(this.n, this.d);

  factory Rational(int n, [int d = 1]) {
    if (d == 0) throw ArgumentError('zero denominator');
    var a = n;
    var b = d;
    if (b < 0) {
      a = -a;
      b = -b;
    }
    final g = gcd(a.abs(), b);
    return Rational._(a ~/ g, b ~/ g);
  }

  final int n;
  final int d;

  static int gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final t = x % y;
      x = y;
      y = t;
    }
    return x == 0 ? 1 : x;
  }

  static int lcm(int a, int b) => a ~/ gcd(a, b) * b;

  bool get isInt => d == 1;
  bool get isNegative => n < 0;
  double get value => n / d;

  Rational operator +(Rational o) => Rational(n * o.d + o.n * d, d * o.d);
  Rational operator -(Rational o) => Rational(n * o.d - o.n * d, d * o.d);
  Rational operator *(Rational o) => Rational(n * o.n, d * o.d);
  Rational operator /(Rational o) => Rational(n * o.d, d * o.n);
  Rational operator -() => Rational._(-n, d);

  String get markup {
    if (isInt) return '$n';
    if (n < 0) return '-\\frac{${-n}}{$d}';
    return '\\frac{$n}{$d}';
  }

  String get plain => isInt ? '$n' : '$n/$d';

  @override
  int compareTo(Rational other) => (n * other.d).compareTo(other.n * d);

  @override
  bool operator ==(Object other) =>
      other is Rational && other.n == n && other.d == d;

  @override
  int get hashCode => Object.hash(n, d);

  @override
  String toString() => plain;
}
