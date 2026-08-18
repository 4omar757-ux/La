import 'dart:math';

import '../models/car_state.dart';

/// فيزياء قيادة أركيدية بسيطة: تسارع/فرملة/انعطاف، وتحويل الحركة
/// من متر إلى إحداثيات (خط عرض/طول) على الخريطة الحقيقية.
class DrivingEngine {
  static const double maxForwardSpeed = 20; // م/ث (~72 كم/س)
  static const double maxReverseSpeed = 8;
  static const double acceleration = 10; // م/ث²
  static const double deceleration = 14; // عند ترك دواسة الوقود
  static const double maxTurnRateDeg = 75; // درجة/ثانية بأقصى سرعة
  static const double _metersPerDegLat = 111320.0;

  /// steer و throttle كل واحد بين -1 و 1 (من عصا التحكم الافتراضية)
  static void step(
    CarState car, {
    required double steer,
    required double throttle,
    required double dt,
  }) {
    if (throttle.abs() < 0.05) {
      if (car.speed > 0) {
        car.speed = max(0, car.speed - deceleration * dt);
      } else if (car.speed < 0) {
        car.speed = min(0, car.speed + deceleration * dt);
      }
    } else {
      final target = throttle > 0 ? throttle * maxForwardSpeed : throttle * maxReverseSpeed;
      final maxDelta = acceleration * dt;
      car.speed += (target - car.speed).clamp(-maxDelta, maxDelta);
    }

    // اسمح بانعطاف ولو السيارة شبه واقفة (إحساس أركيدي أمتع)
    final speedRatio = (car.speed.abs() / maxForwardSpeed).clamp(0.15, 1.0);
    car.headingDeg = (car.headingDeg + steer * maxTurnRateDeg * speedRatio * dt) % 360;

    final headingRad = car.headingDeg * pi / 180;
    final metersPerDegLng = _metersPerDegLat * cos(car.lat * pi / 180);
    final distance = car.speed * dt;

    car.lat += distance * cos(headingRad) / _metersPerDegLat;
    car.lng += distance * sin(headingRad) / metersPerDegLng;
  }
}
