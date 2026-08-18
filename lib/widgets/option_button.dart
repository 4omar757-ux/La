import 'package:flutter/material.dart';

enum OptionState { idle, selected, correct, wrong }

class OptionButton extends StatelessWidget {
  final String label;
  final OptionState state;
  final VoidCallback? onTap;

  const OptionButton({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  Color _bgColor(BuildContext context) {
    switch (state) {
      case OptionState.correct:
        return Colors.green.shade600;
      case OptionState.wrong:
        return Colors.red.shade600;
      case OptionState.selected:
        return Theme.of(context).colorScheme.primary;
      case OptionState.idle:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Color _fgColor(BuildContext context) {
    if (state == OptionState.idle) {
      return Theme.of(context).colorScheme.onSurface;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _bgColor(context),
          foregroundColor: _fgColor(context),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ),
    );
  }
}
