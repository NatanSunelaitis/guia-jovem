import 'package:app/core/theme/gj_transicoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('o fade curto vale para todas as plataformas', () {
    final builders = gjPageTransitionsTheme.builders;
    expect(builders.values, everyElement(isA<GJFadeTransitionsBuilder>()));
    expect(builders.length, TargetPlatform.values.length);
  });

  test('o fade termina na primeira metade da rota (cerca de 150 ms)', () {
    expect(GJFadeTransitionsBuilder.curva.end, 0.5);
  });
}
