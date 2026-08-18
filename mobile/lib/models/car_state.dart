/// حالة سيارة قابلة للقيادة فوق الخريطة (وضع أركيدي - حركة حرة غير مقيدة بالشوارع)
class CarState {
  double lat;
  double lng;
  double headingDeg; // 0 = شمال، تزيد باتجاه عقارب الساعة
  double speed; // متر/ثانية، سالبة تعني تراجع للخلف

  CarState({
    required this.lat,
    required this.lng,
    this.headingDeg = 0,
    this.speed = 0,
  });

  double get speedKmh => speed.abs() * 3.6;
}
