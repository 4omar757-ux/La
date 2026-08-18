import 'package:flutter/material.dart';

import '../models/building.dart';

class BuildingPalette extends StatelessWidget {
  final String? selectedType;
  final double gold;
  final ValueChanged<String> onSelect;

  const BuildingPalette({
    super.key,
    required this.selectedType,
    required this.gold,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: kBuildingTypes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final def = kBuildingTypes.values.elementAt(index);
          final affordable = gold >= def.cost;
          final selected = def.id == selectedType;
          return GestureDetector(
            onTap: affordable ? () => onSelect(def.id) : null,
            child: Container(
              width: 92,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF422006) : const Color(0xFF0F172A),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFACC15)
                      : const Color(0xFF334155),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Opacity(
                opacity: affordable ? 1 : 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(def.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      def.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      '💰 ${def.cost}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
