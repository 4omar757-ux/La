// فيزياء دريفت أركيدية: سرعة أمامية + سرعة جانبية (انزلاق) منفصلتين،
// مع "قبضة" (grip) تتحكم بمدى بقاء الانزلاق الجانبي بدل تصحيحه فورًا.
const CAR_PHYSICS = {
  enginePower: 15, // م/ث² تسارع أمامي
  brakePower: 26,
  reverseAccel: 8,
  maxForwardSpeed: 36, // م/ث (~130 كم/س)
  maxReverseSpeed: 9,
  dragCoeff: 0.6, // احتكاك طبيعي يبطئ السرعة الأمامية تدريجيًا
  normalGrip: 6.5, // قبضة عالية = يلغي الانزلاق الجانبي بسرعة (بدون دريفت)
  driftGrip: 0.55, // قبضة منخفضة أثناء الفرملة اليدوية = الانزلاق يستمر (دريفت)
  handbrakeKick: 1.1, // قوة الدفعة الجانبية عند بدء الدريفت بالفرملة اليدوية
  maxTurnRateDeg: 130,
  driftAngleThresholdDeg: 8, // زاوية الانزلاق اللي تُحسب دريفت فعلي (لأجل النقاط)
};

function createCar(x, z, headingDeg = 0) {
  return {
    x,
    z,
    headingDeg,
    forwardSpeed: 0,
    lateralSpeed: 0,
    driftAngleDeg: 0,
    isDrifting: false,
  };
}

// input: { steer: -1..1, throttle: -1..1, handbrake: bool }
// يرجع { driftScoreDelta } لإضافتها لنقاط اللاعب
function stepCar(car, input, dt) {
  const p = CAR_PHYSICS;
  const steer = Math.max(-1, Math.min(1, input.steer || 0));
  const throttle = Math.max(-1, Math.min(1, input.throttle || 0));
  const handbrake = !!input.handbrake;

  // تسارع/فرملة أمامية
  if (throttle > 0) {
    car.forwardSpeed += throttle * p.enginePower * dt;
  } else if (throttle < 0) {
    if (car.forwardSpeed > 0) car.forwardSpeed += throttle * p.brakePower * dt;
    else car.forwardSpeed += throttle * p.reverseAccel * dt;
  }
  // احتكاك طبيعي
  const dragSign = car.forwardSpeed > 0 ? -1 : car.forwardSpeed < 0 ? 1 : 0;
  car.forwardSpeed += dragSign * p.dragCoeff * dt;

  car.forwardSpeed = Math.max(-p.maxReverseSpeed, Math.min(p.maxForwardSpeed, car.forwardSpeed));

  // انعطاف: معدل الدوران يعتمد على السرعة الأمامية
  const speedRatio = Math.max(0.2, Math.min(1, Math.abs(car.forwardSpeed) / p.maxForwardSpeed));
  const turnDir = car.forwardSpeed >= 0 ? 1 : -1;
  car.headingDeg =
    (car.headingDeg + steer * p.maxTurnRateDeg * speedRatio * turnDir * dt + 360) % 360;

  // دفعة الفرملة اليدوية لبدء الانزلاق
  if (handbrake && Math.abs(car.forwardSpeed) > 2) {
    car.lateralSpeed -= steer * p.handbrakeKick * Math.abs(car.forwardSpeed) * dt;
  }

  // القبضة: تُخمد الانزلاق الجانبي بمعدل يعتمد على وجود فرملة يدوية
  const grip = handbrake ? p.driftGrip : p.normalGrip;
  car.lateralSpeed *= Math.max(0, 1 - grip * dt);

  // تحويل السرعة المحلية (أمام/جانب) لإحداثيات عالمية x/z
  const headingRad = (car.headingDeg * Math.PI) / 180;
  const forwardX = Math.sin(headingRad);
  const forwardZ = Math.cos(headingRad);
  const rightX = Math.cos(headingRad);
  const rightZ = -Math.sin(headingRad);

  const worldVelX = forwardX * car.forwardSpeed + rightX * car.lateralSpeed;
  const worldVelZ = forwardZ * car.forwardSpeed + rightZ * car.lateralSpeed;

  car.x += worldVelX * dt;
  car.z += worldVelZ * dt;

  // زاوية الانزلاق = الفرق بين اتجاه الحركة الفعلي واتجاه توجيه السيارة
  const speedMag = Math.hypot(worldVelX, worldVelZ);
  let driftAngleDeg = 0;
  if (speedMag > 0.5) {
    const velocityHeadingRad = Math.atan2(worldVelX, worldVelZ);
    let diff = ((velocityHeadingRad - headingRad) * 180) / Math.PI;
    diff = ((diff + 180) % 360) - 180; // تطبيع لـ -180..180
    driftAngleDeg = diff;
  }
  car.driftAngleDeg = driftAngleDeg;
  car.isDrifting = Math.abs(driftAngleDeg) > p.driftAngleThresholdDeg && speedMag > 3;

  const driftScoreDelta = car.isDrifting ? Math.abs(driftAngleDeg) * speedMag * dt * 0.5 : 0;
  return { driftScoreDelta, speedMag };
}
