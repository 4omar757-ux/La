import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:la_city_builder/screens/home_screen.dart';

void main() {
  testWidgets('الشاشة الرئيسية تعرض خياري اللعب الفردي والجماعي', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: HomeScreen()),
    ));

    expect(find.text('لعب فردي'), findsOneWidget);
    expect(find.text('لعب جماعي (منافسة)'), findsOneWidget);
  });
}
