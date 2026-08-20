import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _volumePrefKey = 'sound_volume';
const double _defaultVolume = 1.0;

/// أصوات التطبيق. نستخدم ملفات صوتية حقيقية بدل SystemSound.play لأنه غير
/// موثوق على أندرويد (يعتمد على إعداد "أصوات اللمس" بالنظام وغالباً صامت).
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final Map<String, AudioPlayer> _players = {
    'tick': AudioPlayer(playerId: 'tick'),
    'time_up': AudioPlayer(playerId: 'time_up'),
    'correct': AudioPlayer(playerId: 'correct'),
    'wrong': AudioPlayer(playerId: 'wrong'),
    'celebration': AudioPlayer(playerId: 'celebration'),
  };
  // Future واحد مُخزَّن (memoized) بدل bool _ready بسيط: لو صار نداءين
  // متزامنين لـ init() قبل ما يخلص أول نداء (مثلاً المستخدم يسحب شريط
  // الصوت بالإعدادات فور فتح الشاشة، قبل ما init() الأولى من initState
  // تخلص)، كلاهما ينتظر نفس التشغيلة بدل ما ثانيهما يعيد كامل التهيئة من
  // الصفر ويكتب فوق مستوى الصوت اللي غيّره المستخدم للتو بالقيمة القديمة
  // المحفوظة.
  Future<void>? _initFuture;
  bool _volumeLoaded = false;
  double _volume = _defaultVolume;

  double get volume => _volume;

  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    for (final entry in _players.entries) {
      await entry.value.setReleaseMode(ReleaseMode.stop);
      await entry.value.setSource(AssetSource('sounds/${entry.key}.wav'));
    }
    if (!_volumeLoaded) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _volume = prefs.getDouble(_volumePrefKey) ?? _defaultVolume;
      } catch (_) {
        _volume = _defaultVolume;
      }
      _volumeLoaded = true;
    }
    for (final player in _players.values) {
      await player.setVolume(_volume);
    }
  }

  /// يغيّر مستوى الصوت (٠ إلى ١) ويحفظه حتى يبقى نفس المستوى بعد إغلاق
  /// التطبيق. لا يوقف تشغيل الصوت — ٠ يعني صوت المؤقت مكتوم بدون ما نعطل
  /// عداد الوقت نفسه.
  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    // نعلّم القيمة "محمّلة" فوراً (قبل أي await) حتى لو init() لسه شغالة
    // بالخلفية ما ترجع تكتب فوقها بالقيمة القديمة المحفوظة بعد ما تخلص.
    _volumeLoaded = true;
    await init();
    for (final player in _players.values) {
      await player.setVolume(_volume);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_volumePrefKey, _volume);
    } catch (_) {
      // تجاهل فشل الحفظ؛ يبقى المستوى ساري بهذه الجلسة فقط.
    }
  }

  Future<void> _play(String key) async {
    try {
      await init();
      final player = _players[key]!;
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      // تجاهل أي خطأ صوت حتى لا يعطل تدفق اللعبة
    }
  }

  Future<void> playTick() => _play('tick');
  Future<void> playTimeUp() => _play('time_up');
  Future<void> playCorrect() => _play('correct');
  Future<void> playWrong() => _play('wrong');
  Future<void> playCelebration() => _play('celebration');
}
