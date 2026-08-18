import 'package:flutter/material.dart';

class StatsBar extends StatelessWidget {
  final double gold;
  final double population;
  final int capacity;
  final double happiness;

  const StatsBar({
    super.key,
    required this.gold,
    required this.population,
    required this.capacity,
    required this.happiness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat('💰', gold.floor().toString()),
          _stat('👥', '${population.floor()}/$capacity'),
          _stat('😊', '${happiness.round()}%'),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
