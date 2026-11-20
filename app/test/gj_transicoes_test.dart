import 'package:app/core/theme/gj_theme.dart';
import 'package:app/core/theme/gj_transicoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('o tema usa o fade curto em todas as plataformas', () {
    final builders = GJTheme.light.pageTransitionsTheme.builders;
    expect(builders.values, everyElement(isA<GJFadeTransitionsBuilder>()));
    expect(builders.length, TargetPlatform.values.length);
  });

  test('o fade termina na primeira metade da rota (cerca de 150 ms)', () {
    expect(GJFadeTransitionsBuilder.curva.end, 0.5);
  });
}
