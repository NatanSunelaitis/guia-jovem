import 'package:app/features/auth/data/google_login.dart';
import 'package:flutter/material.dart';

/// Substitui o botão do Google Identity Services, que só existe no navegador:
/// o toque entrega um ID token fixo (ou a falha de carregamento).
class GoogleLoginFalso implements GoogleLogin {
  GoogleLoginFalso({this.falhar = false});

  static const idToken = 'id-token-do-google';

  final bool falhar;

  @override
  bool get disponivel => true;

  @override
  Widget botao({
    required void Function(String idToken) aoReceberToken,
    required void Function(String mensagem) aoFalhar,
  }) =>
      TextButton(
        onPressed: () => falhar ? aoFalhar('Não foi possível carregar o login com Google.') : aoReceberToken(idToken),
        child: const Text('Entrar com Google'),
      );
}
