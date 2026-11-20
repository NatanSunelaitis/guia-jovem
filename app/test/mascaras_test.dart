import 'package:app/shared/utils/mascaras.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _digitar(TextInputFormatter formatador, String texto) =>
    formatador.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: texto));

void main() {
  test('formata o CEP de 8 dígitos e deixa os outros como vieram', () {
    expect(formatarCep('18010081'), '18010-081');
    expect(formatarCep('18010-081'), '18010-081');
    expect(formatarCep(null), '');
    expect(formatarCep('123'), '123');
  });

  test('formata o CNPJ numérico e o alfanumérico', () {
    expect(formatarCnpj('11222333000181'), '11.222.333/0001-81');
    expect(formatarCnpj('12abc34501de35'), '12.ABC.345/01DE-35');
    expect(formatarCnpj('123'), '123');
  });

  test('a máscara de CNPJ pontua durante a digitação, aceita letras e limita a 14', () {
    final formatador = CnpjInputFormatter();
    expect(_digitar(formatador, '112').text, '11.2');
    expect(_digitar(formatador, '12abc34501de35').text, '12.ABC.345/01DE-35');
    expect(_digitar(formatador, '11222333000181999').text, '11.222.333/0001-81');
  });

  test('a máscara de CEP aceita só números, no formato 00000-000', () {
    final formatador = CepInputFormatter();
    expect(_digitar(formatador, '180').text, '180');
    expect(_digitar(formatador, '18010a081').text, '18010-081');
  });
}
