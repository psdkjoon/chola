import 'package:flutter/material.dart';
import 'package:chola/theme/catppuccin.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({required this.size, super.key});

  final double size;

  static const double _darkMix = 0.12;
  static const double _lightMix = 0.22;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final base =
        (dark ? CatppuccinPalette.mocha : CatppuccinPalette.latte).base;
    final tile = Color.lerp(base, scheme.primary, dark ? _darkMix : _lightMix)!;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _LogoPainter(glyph: scheme.primary, tile: tile),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.glyph, required this.tile});

  final Color glyph;
  final Color tile;

  static const List<(double, double, double)> _lobes = [
    (9.2, 9.6, 4.4),
    (14.8, 9.6, 4.4),
    (7.0, 13.4, 3.8),
    (17.0, 13.4, 3.8),
    (10.2, 15.6, 3.4),
    (13.8, 15.6, 3.4),
  ];

  static final Path _bolt = Path()
    ..moveTo(13.6, 6.4)
    ..lineTo(9.0, 13.0)
    ..lineTo(11.7, 13.0)
    ..lineTo(10.5, 17.8)
    ..lineTo(15.0, 11.2)
    ..lineTo(12.3, 11.2)
    ..close();

  static final Path _folds = Path()
    ..moveTo(5.6, 12.2)
    ..cubicTo(6.8, 10.4, 7.4, 13.0, 8.6, 11.6)
    ..moveTo(18.4, 12.2)
    ..cubicTo(17.2, 10.4, 16.6, 13.0, 15.4, 11.6)
    ..moveTo(6.8, 8.6)
    ..cubicTo(8.0, 7.2, 8.6, 9.4, 9.8, 8.0)
    ..moveTo(17.2, 8.6)
    ..cubicTo(16.0, 7.2, 15.4, 9.4, 14.2, 8.0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawRRect(
      RRect.fromRectXY(const Rect.fromLTWH(0, 0, 24, 24), 6.16, 6.16),
      Paint()..color = tile,
    );
    final glyphPaint = Paint()..color = glyph;
    for (final (x, y, r) in _lobes) {
      canvas.drawCircle(Offset(x, y), r, glyphPaint);
    }
    canvas.drawRRect(
      RRect.fromRectXY(const Rect.fromLTRB(10.8, 17, 13.2, 20.6), 1, 1),
      glyphPaint,
    );
    canvas.drawPath(_bolt, Paint()..color = tile);
    canvas.drawPath(
      _folds,
      Paint()
        ..color = tile
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.75
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.glyph != glyph || old.tile != tile;
}
