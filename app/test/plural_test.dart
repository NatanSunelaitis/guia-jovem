import 'package:app/shared/utils/plural.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa o singular só para 1', () {
    expect(contagem(1, 'avaliação', 'avaliações'), '1 avaliação');
    expect(contagem(2, 'avaliação', 'avaliações'), '2 avaliações');
    expect(contagem(0, 'administrador', 'administradores'), '0 administradores');
    expect(contagem(1, 'administrador', 'administradores'), '1 administrador');
  });
}
