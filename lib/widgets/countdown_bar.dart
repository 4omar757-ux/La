import 'package:flutter/material.dart';

class CountdownBar extends StatelessWidget {
  final double remainingFraction; // 0.0 - 1.0
  final int secondsLeft;

  const CountdownBar({
    super.key,
    required this.remainingFraction,
    required this.secondsLeft,
  });

  @override
  Widget build(BuildContext context) {
    final color = remainingFraction < 0.25
        ? Colors.red
        : remainingFraction < 0.5
            ? Colors.orange
            : Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: remainingFraction.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$secondsLeft',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
      ],
    );
  }
}
