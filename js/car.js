// فيزياء قيادة أركيدية بسيطة + تحويل الحركة من متر إلى إحداثيات جغرافية
const CAR_PHYSICS = {
  maxForwardSpeed: 22, // م/ث
  maxReverseSpeed: 8,
  acceleration: 12,
  deceleration: 16,
  maxTurnRateDeg: 80,
};

const METERS_PER_DEG_LAT = 111320;

function createCar(lng, lat) {
  return { lng, lat, headingDeg: 0, speed: 0 };
}

function stepCar(car, { steer = 0, throttle = 0, dt = 0.05 }) {
  const p = CAR_PHYSICS;

  if (Math.abs(throttle) < 0.05) {
    if (car.speed > 0) car.speed = Math.max(0, car.speed - p.deceleration * dt);
    else if (car.speed < 0) car.speed = Math.min(0, car.speed + p.deceleration * dt);
  } else {
    const target = throttle > 0 ? throttle * p.maxForwardSpeed : throttle * p.maxReverseSpeed;
    const maxDelta = p.acceleration * dt;
    const diff = target - car.speed;
    car.speed += Math.max(-maxDelta, Math.min(maxDelta, diff));
  }

  const speedRatio = Math.max(0.15, Math.min(1, Math.abs(car.speed) / p.maxForwardSpeed));
  car.headingDeg = (car.headingDeg + steer * p.maxTurnRateDeg * speedRatio * dt + 360) % 360;

  const headingRad = (car.headingDeg * Math.PI) / 180;
  const metersPerDegLng = METERS_PER_DEG_LAT * Math.cos((car.lat * Math.PI) / 180);
  const distance = car.speed * dt;

  car.lat += (distance * Math.cos(headingRad)) / METERS_PER_DEG_LAT;
  car.lng += (distance * Math.sin(headingRad)) / metersPerDegLng;
}
