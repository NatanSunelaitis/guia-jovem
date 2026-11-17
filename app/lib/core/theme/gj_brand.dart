/// Caminhos dos arquivos de marca do Guia Jovem (GJDS, seção 2.10).
/// Todos em `app/assets/brand/`, declarados em `pubspec.yaml`. O favicon e a
/// animação de carregamento ficam em `app/web/`, servidos fora do Flutter.
abstract final class GJBrand {
  /// Logo empilhado (símbolo sobre o nome): login, cadastro e recuperação de senha.
  static const String logo = 'assets/brand/guia-jovem-logo.svg';

  /// Logo empilhado em branco, para fundo `primary` (rodapé).
  static const String logoBranco = 'assets/brand/guia-jovem-logo-branco.svg';

  /// Logo horizontal do header.
  static const String logoHorizontal = 'assets/brand/guia-jovem-logo-horizontal.svg';

  /// Logo empilhado com a animação de entrada (CSS); reservado para telas de
  /// destaque, não usado no app por enquanto.
  static const String logoAnimado = 'assets/brand/guia-jovem-logo-animado.svg';
}
