import 'package:flutter/material.dart';

/// عصا تحكم افتراضية: تُرجع (dx, dy) بين -1 و1 — dx للانعطاف، dy للتسارع
/// (أعلى = أمام موجب، أسفل = خلف سالب).
class Joystick extends StatefulWidget {
  final ValueChanged<Offset> onChanged;

  const Joystick({super.key, required this.onChanged});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  static const double _radius = 50;
  static const double _size = _radius * 2 + 20;
  Offset _knob = Offset.zero;

  void _update(Offset localPosition) {
    var vector = localPosition - const Offset(_size / 2, _size / 2);
    if (vector.distance > _radius) {
      vector = vector / vector.distance * _radius;
    }
    setState(() => _knob = vector);
    widget.onChanged(Offset(vector.dx / _radius, -vector.dy / _radius));
  }

  void _reset() {
    setState(() => _knob = Offset.zero);
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
                border: Border.all(color: Colors.white24, width: 2),
              ),
            ),
            Transform.translate(
              offset: _knob,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
