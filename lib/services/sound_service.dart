import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _volumePrefKey = 'sound_volume';
const double _defaultVolume = 1.0;

/// أصوات المؤقت. نستخدم ملفات صوتية حقيقية بدل SystemSound.play لأنه غير
/// موثوق على أندرويد (يعتمد على إعداد "أصوات اللمس" بالنظام وغالباً صامت).
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _tickPlayer = AudioPlayer(playerId: 'tick');
  final AudioPlayer _timeUpPlayer = AudioPlayer(playerId: 'time_up');
  bool _ready = false;
  double _volume = _defaultVolume;

  double get volume => _volume;

  Future<void> init() async {
    if (_ready) return;
    await _tickPlayer.setReleaseMode(ReleaseMode.stop);
    await _timeUpPlayer.setReleaseMode(ReleaseMode.stop);
    await _tickPlayer.setSource(AssetSource('sounds/tick.wav'));
    await _timeUpPlayer.setSource(AssetSource('sounds/time_up.wav'));
    try {
      final prefs = await SharedPreferences.getInstance();
      _volume = prefs.getDouble(_volumePrefKey) ?? _defaultVolume;
    } catch (_) {
      _volume = _defaultVolume;
    }
    await _tickPlayer.setVolume(_volume);
    await _timeUpPlayer.setVolume(_volume);
    _ready = true;
  }

  /// يغيّر مستوى الصوت (٠ إلى ١) ويحفظه حتى يبقى نفس المستوى بعد إغلاق
  /// التطبيق. لا يوقف تشغيل الصوت — ٠ يعني صوت المؤقت مكتوم بدون ما نعطل
  /// عداد الوقت نفسه.
  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    await init();
    await _tickPlayer.setVolume(_volume);
    await _timeUpPlayer.setVolume(_volume);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumePrefKey, _volume);
    } catch (_) {
      // تجاهل فشل الحفظ؛ يبقى المستوى ساري بهذه الجلسة فقط.
    }
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
