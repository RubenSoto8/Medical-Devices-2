import 'package:ecg/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows BPM dashboard after tapping start', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BpmApp());

    expect(find.text('Iniciar'), findsOneWidget);

    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    expect(find.text('80  bpm'), findsOneWidget);
    expect(find.text('Sano como manzano'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('updates status when BPM changes with slider', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BpmApp());
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    final slider = find.byType(Slider);

    await tester.drag(slider, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Achicopalado'), findsOneWidget);

    await tester.drag(slider, const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Aaahhh!!!'), findsOneWidget);
  });
}
