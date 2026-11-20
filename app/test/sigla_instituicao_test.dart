import 'package:app/shared/utils/sigla_instituicao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa a sigla do nome, a marca ou as iniciais', () {
    expect(siglaDaInstituicao('UESP'), 'UESP');
    expect(siglaDaInstituicao('FEITU'), 'FEITU');
    expect(siglaDaInstituicao('FCS Boituva'), 'FCS');
    expect(siglaDaInstituicao('Faculdade Votorantim de Tecnologia'), 'FVT');
    expect(siglaDaInstituicao('Faculdade Municipal de Salto'), 'FMS');
    expect(siglaDaInstituicao('UniVale Sorocaba'), 'UniVale');
    expect(siglaDaInstituicao('UniTatuí'), 'UniTatuí');
    expect(siglaDaInstituicao('Fatec Sorocaba'), 'FS');
  });
}
