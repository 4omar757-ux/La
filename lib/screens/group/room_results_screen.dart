import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/room_service.dart';
import '../../widgets/leaderboard.dart';

class RoomResultsScreen extends StatelessWidget {
  final String code;
  const RoomResultsScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final roomService = RoomService();
    return Scaffold(
      appBar: AppBar(title: const Text('النتيجة النهائية')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: roomService.watchPlayers(code),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data!.docs.map((d) {
            final data = d.data();
            return LeaderboardEntry(
              name: data['name'] as String,
              score: (data['score'] as num?)?.toInt() ?? 0,
            );
          }).toList();
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.emoji_events_rounded, size: 64, color: Colors.amber),
                const SizedBox(height: 8),
                const Text(
                  'انتهت المسابقة!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Leaderboard(entries: entries),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('رجوع للرئيسية'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
