import 'package:ecg/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows SpO2 dashboard after tapping start', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Spo2App());

    expect(find.text('Iniciar'), findsOneWidget);

    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    expect(find.text('98 % SpO2'), findsOneWidget);
    expect(find.text('Sano como Manzano'), findsOneWidget);
    expect(find.text('\u00F3ptimo'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('updates status when SpO2 changes with slider', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const Spo2App());
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    Slider sliderWidget() => tester.widget<Slider>(find.byType(Slider));

    sliderWidget().onChanged?.call(93);
    await tester.pumpAndSettle();
    expect(find.text('Achicopalado'), findsOneWidget);
    expect(find.text('vigilar'), findsOneWidget);

    sliderWidget().onChanged?.call(88);
    await tester.pumpAndSettle();
    expect(find.text('ahhhh'), findsOneWidget);
    expect(find.text('alerta'), findsOneWidget);

    sliderWidget().onChanged?.call(84);
    await tester.pumpAndSettle();
    expect(find.text('AAHHH'), findsOneWidget);
    expect(find.text('Se recomienda consultar a un m\u00E9dico'), findsOneWidget);
  });
}
