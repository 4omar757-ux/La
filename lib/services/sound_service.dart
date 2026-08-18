import 'package:audioplayers/audioplayers.dart';

/// أصوات المؤقت. نستخدم ملفات صوتية حقيقية بدل SystemSound.play لأنه غير
/// موثوق على أندرويد (يعتمد على إعداد "أصوات اللمس" بالنظام وغالباً صامت).
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _tickPlayer = AudioPlayer(playerId: 'tick');
  final AudioPlayer _timeUpPlayer = AudioPlayer(playerId: 'time_up');
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await _tickPlayer.setReleaseMode(ReleaseMode.stop);
    await _timeUpPlayer.setReleaseMode(ReleaseMode.stop);
    await _tickPlayer.setSource(AssetSource('sounds/tick.wav'));
    await _timeUpPlayer.setSource(AssetSource('sounds/time_up.wav'));
    _ready = true;
  }

  Future<void> playTick() async {
    try {
      await init();
      await _tickPlayer.seek(Duration.zero);
      await _tickPlayer.resume();
    } catch (_) {
      // تجاهل أي خطأ صوت حتى لا يعطل عداد الوقت
    }
  }

  Future<void> playTimeUp() async {
    try {
      await init();
      await _timeUpPlayer.seek(Duration.zero);
      await _timeUpPlayer.resume();
    } catch (_) {}
  }
}
