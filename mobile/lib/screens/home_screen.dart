import 'package:flutter/material.dart';

import '../models/city.dart';
import 'singleplayer_game_screen.dart';
import 'multiplayer_lobby_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickCityAndPlaySolo(BuildContext context) async {
    final cityId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('اختر المدينة', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            for (final city in kCities.values)
              ListTile(
                title: Text(city.name, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, city.id),
              ),
          ],
        ),
      ),
    );
    if (cityId != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SinglePlayerGameScreen(cityId: cityId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏙️', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text(
                  'لعبة بناء المدن',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'الرياض وبريدة',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _pickCityAndPlaySolo(context),
                    child: const Text('لعب فردي', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MultiplayerLobbyScreen()),
                      );
                    },
                    child: const Text('لعب جماعي (منافسة)', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
