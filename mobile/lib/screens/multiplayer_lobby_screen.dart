import 'package:flutter/material.dart';

import '../models/city.dart';
import '../services/multiplayer_service.dart';
import 'multiplayer_room_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _service = MultiplayerService();

  String _cityId = kCities.keys.first;
  int _durationMinutes = 10;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'اكتب اسمك أولاً');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final (code, playerId) = await _service.createRoom(
        hostName: _nameController.text.trim(),
        cityId: _cityId,
        durationMinutes: _durationMinutes,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MultiplayerRoomScreen(roomCode: code, playerId: playerId),
        ),
      );
    } catch (e) {
      setState(() => _error = 'تعذر إنشاء الغرفة: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'اكتب اسمك أولاً');
      return;
    }
    if (_codeController.text.trim().isEmpty) {
      setState(() => _error = 'اكتب رمز الغرفة');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = _codeController.text.trim().toUpperCase();
      final playerId = await _service.joinRoom(
        roomCode: code,
        playerName: _nameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MultiplayerRoomScreen(roomCode: code, playerId: playerId),
        ),
      );
    } catch (e) {
      setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('لعب جماعي'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('اسمك', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('مثال: عمر'),
              ),
              const SizedBox(height: 28),
              const Text('إنشاء غرفة جديدة',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              const Text('المدينة', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _cityId,
                decoration: _inputDecoration(null),
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                items: [
                  for (final city in kCities.values)
                    DropdownMenuItem(value: city.id, child: Text(city.name)),
                ],
                onChanged: (v) => setState(() => _cityId = v!),
              ),
              const SizedBox(height: 12),
              const Text('مدة الجولة', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _durationMinutes,
                decoration: _inputDecoration(null),
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                items: const [5, 10, 15, 20]
                    .map((m) => DropdownMenuItem(value: m, child: Text('$m دقائق')))
                    .toList(),
                onChanged: (v) => setState(() => _durationMinutes = v!),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _busy ? null : _createRoom,
                child: const Text('إنشاء غرفة'),
              ),
              const SizedBox(height: 32),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 16),
              const Text('الانضمام لغرفة',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white, letterSpacing: 4),
                decoration: _inputDecoration('رمز الغرفة'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _busy ? null : _joinRoom,
                child: const Text('انضمام'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}
