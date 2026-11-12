import 'package:flutter/material.dart' hide Text, Icon;
import 'package:flutter/services.dart';
import 'package:chola/localization/localization.dart';
import 'package:chola/theme/app_spacing.dart';

class AmountPicker extends StatelessWidget {
  const AmountPicker({
    required this.presets,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.fieldLabel,
    required this.onChanged,
    super.key,
  });

  static const int _custom = -1;

  final List<int> presets;
  final int value;
  final int min;
  final int max;
  final String Function(int value) label;
  final String fieldLabel;
  final ValueChanged<int> onChanged;

  Future<void> _ask(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _AmountDialog(
        initial: value,
        min: min,
        max: max,
        fieldLabel: fieldLabel,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final isPreset = presets.contains(value);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          expandedInsets: EdgeInsets.zero,
          showSelectedIcon: false,
          segments: [
            for (final preset in presets)
              ButtonSegment(value: preset, label: Text(label(preset))),
            ButtonSegment(
              value: _custom,
              label: Text(isPreset ? 'Custom' : label(value)),
            ),
          ],
          selected: {isPreset ? value : _custom},
          onSelectionChanged: (selection) {
            final picked = selection.first;
            if (picked == _custom) {
              _ask(context);
            } else {
              onChanged(picked);
            }
          },
        ),
      ),
    );
  }
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({
    required this.initial,
    required this.min,
    required this.max,
    required this.fieldLabel,
  });

  final int initial;
  final int min;
  final int max;
  final String fieldLabel;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initial}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) return;
    final bounded = parsed < widget.min
        ? widget.min
        : parsed > widget.max
            ? widget.max
            : parsed;
    Navigator.of(context).pop(bounded);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: widget.fieldLabel.tr,
          helperText: '${widget.min} – ${widget.max}'.tr,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Set')),
      ],
    );
  }
}
