import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../services/firebase_status.dart';
import '../../services/room_service.dart';
import '../difficulty_select_screen.dart' show questionSecondsOptions;
import 'lobby_screen.dart';

class GroupSetupScreen extends StatefulWidget {
  final GroupScoringType? initialType;
  final Difficulty difficulty;
  final int questionCount;
  final QuestionSection? section;
  final int questionSeconds;
  const GroupSetupScreen({
    super.key,
    required this.initialType,
    required this.difficulty,
    required this.questionCount,
    this.section,
    required this.questionSeconds,
  });

  @override
  State<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends State<GroupSetupScreen> {
  final _roomService = RoomService();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  late GroupScoringType _scoringType;
  late int _questionSeconds;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scoringType = widget.initialType ?? GroupScoringType.fastest;
    _questionSeconds = widget.questionSeconds;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'اكتب اسمك أولاً');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final playerId = await _roomService.newPlayerId();
      final code = await _roomService.createRoom(
        scoringType: _scoringType,
        difficulty: widget.difficulty,
        questionCount: widget.questionCount,
        section: widget.section,
        questionSeconds: _questionSeconds,
        hostName: name,
        hostPlayerId: playerId,
      );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LobbyScreen(
          code: code,
          playerId: playerId,
          isHost: true,
        ),
      ));
    } catch (e) {
      setState(() => _error = 'صار خطأ، حاول مرة ثانية');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (name.isEmpty) {
      setState(() => _error = 'اكتب اسمك أولاً');
      return;
    }
    if (code.isEmpty) {
      setState(() => _error = 'اكتب كود الغرفة');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final exists = await _roomService.roomExists(code);
      if (!exists) {
        setState(() {
          _error = 'ما فيه غرفة بهذا الكود';
          _busy = false;
        });
        return;
      }
      final playerId = await _roomService.newPlayerId();
      await _roomService.joinRoom(code: code, playerId: playerId, name: name);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LobbyScreen(
          code: code,
          playerId: playerId,
          isHost: false,
        ),
      ));
    } catch (e) {
      setState(() => _error = 'صار خطأ، حاول مرة ثانية');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('اللعب الجماعي')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'اللعب الجماعي يحتاج ربط المشروع بـ Firebase أولاً',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'راجع ملف FIREBASE_SETUP.md في المشروع لخطوات الإعداد من الجوال.\nاللعب الفردي يعمل الآن بدون أي إعداد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('اللعب الجماعي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: 'اسمك', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text('إنشاء غرفة جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'مستوى الصعوبة: ${widget.difficulty.label} • عدد الأسئلة: ${widget.questionCount}'
              '${widget.section != null ? ' • القسم: ${widget.section!.label}' : ''}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('الوقت لكل سؤال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                for (final s in questionSecondsOptions) ButtonSegment(value: s, label: Text('$s ث')),
              ],
              selected: {_questionSeconds},
              onSelectionChanged: (s) => setState(() => _questionSeconds = s.first),
            ),
            const SizedBox(height: 8),
            if (widget.initialType != null)
              // جاي من مفتاح مخصص بالشاشة الرئيسية (الأسرع / الوقت) — نظام
              // النقاط محسوم مسبقاً، فما نعرض خيار تبديله حتى ما يتكرر نفس
              // الاختيار مرتين ويلخبط المستخدم.
              Row(
                children: [
                  Icon(
                    _scoringType == GroupScoringType.fastest ? Icons.bolt_rounded : Icons.timer_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'نظام النقاط: ${_scoringType == GroupScoringType.fastest ? 'الأسرع يفوز' : 'سباق الوقت'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              )
            else
              // جاي من مفتاح "أونلاين" العام — يختار نظام النقاط هنا.
              SegmentedButton<GroupScoringType>(
                segments: const [
                  ButtonSegment(value: GroupScoringType.fastest, label: Text('الأسرع يفوز')),
                  ButtonSegment(value: GroupScoringType.timed, label: Text('سباق الوقت')),
                ],
                selected: {_scoringType},
                onSelectionChanged: (s) => setState(() => _scoringType = s.first),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _createRoom,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('إنشاء غرفة'),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 16),
            const Text('الانضمام لغرفة موجودة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'كود الغرفة', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _joinRoom,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('انضمام'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
