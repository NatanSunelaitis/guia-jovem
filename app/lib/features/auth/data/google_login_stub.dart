import 'package:flutter/widgets.dart';

import 'google_login.dart';

/// Fora do navegador (testes e plataformas sem `dart:html`) não há o Google
/// Identity Services: o botão não aparece.
GoogleLogin criarGoogleLogin(String clientId) => _GoogleLoginIndisponivel();

class _GoogleLoginIndisponivel implements GoogleLogin {
  @override
  bool get disponivel => false;

  @override
  Widget botao({
    required void Function(String idToken) aoReceberToken,
    required void Function(String mensagem) aoFalhar,
  }) =>
      const SizedBox.shrink();
}
