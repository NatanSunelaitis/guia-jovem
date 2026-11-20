import 'package:flutter/services.dart';

/// CEP de 8 dígitos no formato 00000-000; outros valores ficam como vieram.
String formatarCep(String? cep) {
  if (cep == null) return '';
  final digitos = cep.replaceAll(RegExp(r'\D'), '');
  if (digitos.length != 8) return cep;
  return '${digitos.substring(0, 5)}-${digitos.substring(5)}';
}

/// CNPJ de 14 caracteres (numérico ou alfanumérico da Receita) no formato
/// 00.000.000/0000-00; outros valores ficam como vieram.
String formatarCnpj(String cnpj) {
  final limpo = cnpj.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();
  if (limpo.length != 14) return cnpj;
  return _pontuarCnpj(limpo);
}

String _pontuarCnpj(String limpo) {
  final saida = StringBuffer();
  for (var i = 0; i < limpo.length; i++) {
    if (i == 2 || i == 5) saida.write('.');
    if (i == 8) saida.write('/');
    if (i == 12) saida.write('-');
    saida.write(limpo[i]);
  }
  return saida.toString();
}

/// Máscara de CNPJ durante a digitação: aceita letras e números (formato
/// alfanumérico), deixa as letras maiúsculas e põe a pontuação.
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final limpo = newValue.text.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();
    final texto = _pontuarCnpj(limpo.length > 14 ? limpo.substring(0, 14) : limpo);
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}

/// Máscara de CEP durante a digitação: só números, no formato 00000-000.
class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > 8) digitos = digitos.substring(0, 8);
    final texto = digitos.length > 5 ? '${digitos.substring(0, 5)}-${digitos.substring(5)}' : digitos;
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
