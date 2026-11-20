const _palavrasIgnoradas = {'de', 'da', 'do', 'dos', 'das', 'e'};

/// Sigla mostrada no lugar do logo quando a instituição não tem um:
/// - uma palavra já em sigla no nome (UESP, FEITU, "FCS Boituva" dá FCS);
/// - senão, uma marca com maiúscula no meio ("UniVale Sorocaba" dá UniVale);
/// - senão, as iniciais das palavras ("Faculdade Votorantim de Tecnologia"
///   dá FVT), ou a própria palavra quando o nome tem uma só.
String siglaDaInstituicao(String nome) {
  final palavras = nome.split(RegExp(r'\s+')).where((palavra) => palavra.isNotEmpty).toList();
  if (palavras.isEmpty) return '?';

  for (final palavra in palavras) {
    if (palavra.length >= 2 && RegExp(r'^[A-ZÀ-Ý0-9]+$').hasMatch(palavra)) return palavra;
  }
  for (final palavra in palavras) {
    if (RegExp(r'^[A-ZÀ-Ý][a-zà-ÿ]+[A-ZÀ-Ý]').hasMatch(palavra)) return palavra;
  }

  final significativas = palavras.where((palavra) => !_palavrasIgnoradas.contains(palavra.toLowerCase())).toList();
  if (significativas.length < 2) return significativas.isEmpty ? palavras.first : significativas.first;
  return significativas.take(4).map((palavra) => palavra[0].toUpperCase()).join();
}
