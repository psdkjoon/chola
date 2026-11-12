import 'package:flutter/material.dart';
import 'package:chola/localization/localization.dart' show L10n;

class MathText extends StatelessWidget {
  const MathText(this.data, {this.style, super.key});

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final base = style ?? DefaultTextStyle.of(context).style;
    final resolved = base.color == null
        ? base.copyWith(color: Theme.of(context).colorScheme.onSurface)
        : base;
    final lines = data.split('\n');
    final Widget body = lines.length == 1
        ? _inline(lines.first, resolved)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (final line in lines) _inline(line, resolved)],
          );
    return Directionality(textDirection: TextDirection.ltr, child: body);
  }
}

typedef _Part = ({String text, int end});

Widget _inline(String s, TextStyle style) => Text.rich(
      TextSpan(style: style, children: _spans(s, style)),
      textAlign: TextAlign.center,
    );

bool _isDigit(String ch) {
  final u = ch.codeUnitAt(0);
  return u >= 48 && u <= 57;
}

String _plain(String t) =>
    L10n.mathDigits(t).replaceAll('-', '−').replaceAll('*', '×');

_Part _group(String s, int start) {
  if (start >= s.length) return (text: '', end: s.length);
  if (s[start] != '{') return (text: s[start], end: start + 1);
  var depth = 0;
  for (var i = start; i < s.length; i++) {
    if (s[i] == '{') {
      depth++;
    } else if (s[i] == '}') {
      depth--;
      if (depth == 0) return (text: s.substring(start + 1, i), end: i + 1);
    }
  }
  return (text: s.substring(start + 1), end: s.length);
}

_Part _script(String s, int j) {
  if (j >= s.length) return (text: '', end: j);
  if (s[j] == '{') return _group(s, j);
  var k = j;
  if (s[k] == '-' && k + 1 < s.length) k++;
  if (_isDigit(s[k])) {
    while (k < s.length && _isDigit(s[k])) {
      k++;
    }
    return (text: s.substring(j, k), end: k);
  }
  if (s[k] == '(') {
    var depth = 0;
    for (var m = k; m < s.length; m++) {
      if (s[m] == '(') {
        depth++;
      } else if (s[m] == ')') {
        depth--;
        if (depth == 0) return (text: s.substring(j, m + 1), end: m + 1);
      }
    }
  }
  return (text: s.substring(j, k + 1), end: k + 1);
}

List<InlineSpan> _spans(String s, TextStyle style) {
  final out = <InlineSpan>[];
  final buffer = StringBuffer();
  final size = style.fontSize ?? 16;

  void flush() {
    if (buffer.isEmpty) return;
    out.add(TextSpan(text: _plain(buffer.toString())));
    buffer.clear();
  }

  var i = 0;
  while (i < s.length) {
    if (s.startsWith(r'\frac', i)) {
      final a = _group(s, i + 5);
      final b = _group(s, a.end);
      flush();
      out.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _Fraction(a.text, b.text, style),
        ),
      );
      i = b.end;
    } else if (s.startsWith(r'\sqrt', i)) {
      var at = i + 5;
      var index = '';
      if (at < s.length && s[at] == '[') {
        final close = s.indexOf(']', at);
        if (close > 0) {
          index = s.substring(at + 1, close);
          at = close + 1;
        }
      }
      final body = _group(s, at);
      flush();
      out.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _Radical(index, body.text, style),
        ),
      );
      i = body.end;
    } else if (s.startsWith(r'\mat', i) || s.startsWith(r'\det', i)) {
      final bars = s.startsWith(r'\det', i);
      final body = _group(s, i + 4);
      flush();
      out.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _Grid(body.text, style, bars: bars),
        ),
      );
      i = body.end;
    } else if (s.startsWith(r'\sys', i)) {
      final body = _group(s, i + 4);
      flush();
      out.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _System(body.text, style),
        ),
      );
      i = body.end;
    } else if (s[i] == '^') {
      final t = _script(s, i + 1);
      flush();
      out.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.aboveBaseline,
          baseline: TextBaseline.alphabetic,
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.45),
            child: _inline(t.text, style.copyWith(fontSize: size * 0.65)),
          ),
        ),
      );
      i = t.end;
    } else if (s[i] == '_') {
      final sub = _script(s, i + 1);
      flush();
      final small = style.copyWith(fontSize: size * 0.65);
      if (i + 1 < s.length &&
          s[i + 1] == '{' &&
          s.startsWith('^{', sub.end)) {
        final sup = _group(s, sub.end + 1);
        out.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _inline(sup.text, small),
                _inline(sub.text, small),
              ],
            ),
          ),
        );
        i = sup.end;
      } else {
        out.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.belowBaseline,
            baseline: TextBaseline.alphabetic,
            child: _inline(sub.text, small),
          ),
        );
        i = sub.end;
      }
    } else {
      buffer.write(s[i]);
      i++;
    }
  }
  flush();
  return out;
}

class _Fraction extends StatelessWidget {
  const _Fraction(this.top, this.bottom, this.style);

  final String top;
  final String bottom;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final small = style.copyWith(fontSize: (style.fontSize ?? 16) * 0.85);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _inline(top, small)),
            Container(
              height: 1.6,
              margin: const EdgeInsets.symmetric(vertical: 1.5),
              color: style.color,
            ),
            Center(child: _inline(bottom, small)),
          ],
        ),
      ),
    );
  }
}

class _Radical extends StatelessWidget {
  const _Radical(this.index, this.body, this.style);

  final String index;
  final String body;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 16;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (index.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.5),
            child: _inline(index, style.copyWith(fontSize: size * 0.55)),
          ),
        Text('√', style: style),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(width: 1.6, color: style.color ?? Colors.black),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
            child: _inline(body, style),
          ),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid(this.body, this.style, {required this.bars});

  final String body;
  final TextStyle style;
  final bool bars;

  @override
  Widget build(BuildContext context) {
    final rows = <List<String>>[
      for (final row in body.split(';'))
        <String>[for (final cell in row.split(',')) cell.trim()],
    ];
    final columns = rows.first.length;
    return CustomPaint(
      foregroundPainter: _BracketPainter(style.color ?? Colors.black, bars),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var c = 0; c < columns; c++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final row in rows)
                      _inline(c < row.length ? row[c] : '', style),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter(this.color, this.bars);

  final Color color;
  final bool bars;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final w = size.width;
    final h = size.height;
    if (bars) {
      canvas.drawLine(const Offset(1, 0), Offset(1, h), paint);
      canvas.drawLine(Offset(w - 1, 0), Offset(w - 1, h), paint);
      return;
    }
    const t = 6.0;
    final left = Path()
      ..moveTo(t, 1)
      ..lineTo(1, 1)
      ..lineTo(1, h - 1)
      ..lineTo(t, h - 1);
    final right = Path()
      ..moveTo(w - t, 1)
      ..lineTo(w - 1, 1)
      ..lineTo(w - 1, h - 1)
      ..lineTo(w - t, h - 1);
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.color != color || old.bars != bars;
}

class _System extends StatelessWidget {
  const _System(this.body, this.style);

  final String body;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _BracePainter(style.color ?? Colors.black),
      child: Padding(
        padding: const EdgeInsets.only(left: 18, right: 2, top: 2, bottom: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in body.split(';')) _inline(line.trim(), style),
          ],
        ),
      ),
    );
  }
}

class _BracePainter extends CustomPainter {
  const _BracePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    const w = 12.0;
    final h = size.height;
    final path = Path()
      ..moveTo(w, 1)
      ..quadraticBezierTo(w / 2, 1, w / 2, h * 0.14)
      ..lineTo(w / 2, h * 0.42)
      ..quadraticBezierTo(w / 2, h * 0.5, 1, h * 0.5)
      ..quadraticBezierTo(w / 2, h * 0.5, w / 2, h * 0.58)
      ..lineTo(w / 2, h * 0.86)
      ..quadraticBezierTo(w / 2, h - 1, w, h - 1);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracePainter old) => old.color != color;
}
