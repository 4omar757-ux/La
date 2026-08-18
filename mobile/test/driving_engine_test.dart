import 'package:flutter_test/flutter_test.dart';
import 'package:la_city_builder/models/car_state.dart';
import 'package:la_city_builder/services/driving_engine.dart';

void main() {
  test('التسارع للأمام يزيد السرعة وخط العرض (متجه شمالًا عند heading=0)', () {
    final car = CarState(lat: 24.7136, lng: 46.6753);
    for (var i = 0; i < 20; i++) {
      DrivingEngine.step(car, steer: 0, throttle: 1, dt: 0.05);
    }
    expect(car.speed, greaterThan(0));
    expect(car.lat, greaterThan(24.7136));
    expect(car.lng, closeTo(46.6753, 1e-9));
  });

  test('ترك دواسة الوقود يبطئ السيارة تدريجيًا حتى تقف', () {
    final car = CarState(lat: 24.7136, lng: 46.6753, speed: 10);
    for (var i = 0; i < 100; i++) {
      DrivingEngine.step(car, steer: 0, throttle: 0, dt: 0.05);
    }
    expect(car.speed, 0);
  });

  test('الانعطاف يغيّر اتجاه السيارة (heading)', () {
    final car = CarState(lat: 24.7136, lng: 46.6753, speed: 10);
    DrivingEngine.step(car, steer: 1, throttle: 1, dt: 0.5);
    expect(car.headingDeg, greaterThan(0));
  });
}
