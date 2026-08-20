import 'package:flutter/material.dart';

class PodiumEntry {
  final String name;
  final int score;
  const PodiumEntry({required this.name, required this.score});
}

/// يعرض ترتيب اللاعبين بنهاية مسابقة اللعب الجماعي بشكل منصّة تتويج
/// (الأول بالنص وأعلى، الثاني يمين، الثالث يسار) مع تاج للفائز، بدل
/// القائمة البسيطة القديمة — وقائمة مختصرة لبقية اللاعبين (الرابع فما
/// فوق) تحتها.
class PodiumBoard extends StatelessWidget {
  final List<PodiumEntry> entries;

  const PodiumBoard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final sorted = [...entries]..sort((a, b) => b.score.compareTo(a.score));
    final podium = sorted.take(3).toList();
    final rest = sorted.skip(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('🎉✨🎊✨🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 22)),
        const SizedBox(height: 8),
        Text(
          '🏆 الفائز بالمسابقة: ${podium.first.name}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 22),
        _PodiumRow(podium: podium),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 22),
          for (int i = 0; i < rest.length; i++) ...[
            _RestRow(rank: i + 4, entry: rest[i]),
            if (i != rest.length - 1) const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List<PodiumEntry> podium;
  const _PodiumRow({required this.podium});

  @override
  Widget build(BuildContext context) {
    // نرتب الأعمدة بصرياً (الثاني - الأول - الثالث) حتى يطلع الفائز بالنص
    // وأعلى بند، لكن لو أقل من ٣ لاعبين نعرض بس الموجود منهم بدون أعمدة
    // فاضية (غرفة بلاعبين اثنين مثلاً).
    final second = podium.length > 1 ? podium[1] : null;
    final first = podium[0];
    final third = podium.length > 2 ? podium[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (second != null) ...[
          _PodiumColumn(entry: second, rank: 2),
          const SizedBox(width: 10),
        ],
        _PodiumColumn(entry: first, rank: 1),
        if (third != null) ...[
          const SizedBox(width: 10),
          _PodiumColumn(entry: third, rank: 3),
        ],
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final PodiumEntry entry;
  final int rank;
  const _PodiumColumn({required this.entry, required this.rank});

  static const _medalColors = {
    1: Color(0xFFD4A017),
    2: Color(0xFF9AA3AA),
    3: Color(0xFFB97A45),
  };
  static const _barHeights = {1: 108.0, 2: 76.0, 3: 56.0};
  static const _medalEmoji = {1: '🥇', 2: '🥈', 3: '🥉'};

  @override
  Widget build(BuildContext context) {
    final color = _medalColors[rank]!;
    final avatarSize = rank == 1 ? 56.0 : 46.0;
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank == 1) const Text('👑', style: TextStyle(fontSize: 20)),
          CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: color,
            child: Text(
              entry.name.isNotEmpty ? entry.name[0] : '?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 22 : 18,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            '${entry.score}',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: _barHeights[rank],
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.85), color],
              ),
            ),
            child: Text(_medalEmoji[rank]!, style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

class _RestRow extends StatelessWidget {
  final int rank;
  final PodiumEntry entry;
  const _RestRow({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$rank',
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
          Text('${entry.score}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
