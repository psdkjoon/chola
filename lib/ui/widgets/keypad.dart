import 'dart:math';

import 'package:flutter/material.dart' hide Text, Icon;
import 'package:chola/localization/localization.dart';
import 'package:chola/theme/app_spacing.dart';

class Keypad extends StatelessWidget {
  const Keypad({required this.onKey, required this.keys, super.key});

  final ValueChanged<String> onKey;
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final rest = List<String>.of(keys);
    final minus = rest.remove('-') ? '-' : '';
    var point = rest.remove('.') ? '.' : '';
    if (point.isEmpty) point = rest.remove('/') ? '/' : '';
    final rows = <List<String>>[
      ['7', '8', '9', 'back'],
      ['4', '5', '6', minus],
      ['1', '2', '3', point],
      ['skip', '0', 'enter'],
    ];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
      builder: (context, box) {
        final rowCount = rows.length + (rest.isNotEmpty ? 0.75 : 0);
        final rowHeight =
            (box.maxHeight - AppSpacing.sm * rows.length) / rowCount;
        final size = (rowHeight * 0.38).clamp(18.0, 30.0).toDouble();
        return _grid(rest, rows, size);
      },
    ),
    );
  }

  Widget _grid(List<String> rest, List<List<String>> rows, double size) {
    return Column(
      spacing: AppSpacing.sm,
      children: [
        if (rest.isNotEmpty)
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, box) {
                final count = max(rest.length, 4);
                final width =
                    (box.maxWidth - AppSpacing.sm * (count - 1)) / count;
                return Row(
                  spacing: AppSpacing.sm,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final key in rest)
                      SizedBox(
                        width: width,
                        child: _Key(keyName: key, onKey: onKey, size: size * 0.85),
                      ),
                  ],
                );
              },
            ),
          ),
        for (final row in rows)
          Expanded(
            flex: 4,
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                for (final key in row)
                  Expanded(
                    flex: key == 'enter' ? 2 : 1,
                    child: key.isEmpty
                        ? const SizedBox.shrink()
                        : _Key(keyName: key, onKey: onKey, size: size),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({required this.keyName, required this.onKey, required this.size});

  final String keyName;
  final ValueChanged<String> onKey;
  final double size;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  var _pressed = false;

  void _down(PointerDownEvent event) {
    setState(() => _pressed = true);
    widget.onKey(widget.keyName);
  }

  void _up(PointerEvent event) {
    if (mounted && _pressed) setState(() => _pressed = false);
  }

  static String _semanticLabel(String name) => switch (name) {
        'back' => 'Delete',
        'skip' => 'Skip',
        'enter' => 'Enter',
        ' ' => 'Space',
        '-' => 'Minus',
        _ => name,
      };

  static bool _digit(String name) =>
      name.length == 1 && name.codeUnitAt(0) >= 48 && name.codeUnitAt(0) <= 57;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = widget.keyName;
    final size = widget.size;
    final isEnter = name == 'enter';
    final isAction = !isEnter && !_digit(name);
    final base = isEnter
        ? scheme.primary
        : isAction
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHigh;
    final foreground = isEnter
        ? scheme.onPrimary
        : isAction
            ? scheme.onSecondaryContainer
            : scheme.onSurface;
    final color = _pressed
        ? Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.18), base)
        : base;
    final style = theme.textTheme.headlineSmall
        ?.copyWith(fontSize: size, color: foreground);
    final Widget label = switch (name) {
      'back' => Icon(Icons.backspace_outlined, color: foreground, size: size * 0.85),
      'skip' => Icon(Icons.skip_next_rounded, color: foreground, size: size),
      'enter' =>
        Icon(Icons.keyboard_return_rounded, color: foreground, size: size),
      ' ' => Icon(Icons.space_bar_rounded, color: foreground, size: size),
      '-' => Text('−', style: style),
      _ => Text(name, style: style),
    };
    return Semantics(
      button: true,
      label: L10n.tr(_semanticLabel(name)),
      onTap: () => widget.onKey(name),
      child: ExcludeSemantics(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: Center(child: label),
          ),
        ),
      ),
    );
  }
}
