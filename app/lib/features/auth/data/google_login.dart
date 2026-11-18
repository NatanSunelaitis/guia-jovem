import 'package:flutter/widgets.dart';

import 'google_login_stub.dart' if (dart.library.html) 'google_login_web.dart' as plataforma;

/// Identificador do cliente OAuth do Google (tipo "Aplicativo da Web"),
/// recebido na compilação: `--dart-define=GOOGLE_CLIENT_ID=...`. É o mesmo
/// valor de `GOOGLE_CLIENT_ID` na API, que confere o `aud` do ID token.
const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

/// Login com o Google (RF05, fluxo alternativo do Quadro 8). O botão oficial
/// do Google Identity Services devolve um ID token (JWT), que o app envia a
/// `POST /auth/google`; a API valida com `verifyIdToken` (google.util.js).
abstract class GoogleLogin {
  /// false quando o app foi compilado sem `GOOGLE_CLIENT_ID` (ou fora do
  /// navegador): a tela de login não mostra o botão.
  bool get disponivel;

  /// Botão "Entrar com Google". [aoReceberToken] recebe o ID token; [aoFalhar]
  /// recebe a mensagem quando o Google não pôde ser carregado.
  Widget botao({
    required void Function(String idToken) aoReceberToken,
    required void Function(String mensagem) aoFalhar,
  });
}

/// Implementação usada pelo app; os testes trocam por uma falsa.
GoogleLogin googleLogin = plataforma.criarGoogleLogin(googleClientId);
