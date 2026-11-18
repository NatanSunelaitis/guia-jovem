// O Google Identity Services só existe no navegador; este arquivo é escolhido
// pelo import condicional de google_login.dart quando há `dart:html`.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import 'google_login.dart';

GoogleLogin criarGoogleLogin(String clientId) => GoogleLoginWeb(clientId);

const _scriptGis = 'https://accounts.google.com/gsi/client';
const _tipoDaView = 'gj-google-login';
const _larguraBotao = 320;
const _alturaBotao = 44.0;

/// Google Identity Services no navegador: carrega o script só quando o botão
/// é montado, inicializa com o client ID e desenha o botão oficial do Google
/// numa view HTML. O retorno (`credential`) é o ID token que a API valida.
class GoogleLoginWeb implements GoogleLogin {
  GoogleLoginWeb(this.clientId);

  final String clientId;

  Future<void>? _script;
  bool _inicializado = false;
  bool _viewRegistrada = false;

  // Destino do token e da falha: o botão montado por último (a tela de
  // login aberta).
  void Function(String idToken)? _aoReceberToken;
  void Function(String mensagem)? _aoFalhar;

  @override
  bool get disponivel => clientId.isNotEmpty;

  Future<void> _carregarScript() {
    return _script ??= () {
      final pronto = Completer<void>();
      if (js_util.hasProperty(html.window, 'google')) {
        pronto.complete();
        return pronto.future;
      }
      final script = html.ScriptElement()
        ..src = _scriptGis
        ..async = true
        ..defer = true;
      script.onLoad.first.then((_) => pronto.complete());
      script.onError.first.then((_) {
        _script = null;
        pronto.completeError(StateError('script do Google não carregou'));
      });
      html.document.head!.append(script);
      return pronto.future;
    }();
  }

  Object get _accountsId {
    final google = js_util.getProperty<Object>(html.window, 'google');
    final accounts = js_util.getProperty<Object>(google, 'accounts');
    return js_util.getProperty<Object>(accounts, 'id');
  }

  void _inicializar() {
    if (_inicializado) return;
    final opcoes = js_util.newObject<Object>();
    js_util.setProperty(opcoes, 'client_id', clientId);
    js_util.setProperty(opcoes, 'ux_mode', 'popup');
    js_util.setProperty(
      opcoes,
      'callback',
      js_util.allowInterop((Object resposta) {
        final token = js_util.getProperty<Object?>(resposta, 'credential');
        if (token is String && token.isNotEmpty) _aoReceberToken?.call(token);
      }),
    );
    js_util.callMethod<void>(_accountsId, 'initialize', [opcoes]);
    _inicializado = true;
  }

  void _desenharBotao(html.Element alvo) {
    final opcoes = js_util.newObject<Object>();
    js_util.setProperty(opcoes, 'type', 'standard');
    js_util.setProperty(opcoes, 'theme', 'outline');
    js_util.setProperty(opcoes, 'size', 'large');
    js_util.setProperty(opcoes, 'text', 'signin_with');
    js_util.setProperty(opcoes, 'shape', 'pill');
    js_util.setProperty(opcoes, 'locale', 'pt-BR');
    js_util.setProperty(opcoes, 'width', _larguraBotao);
    js_util.callMethod<void>(_accountsId, 'renderButton', [alvo, opcoes]);
  }

  void _registrarView() {
    if (_viewRegistrada) return;
    ui_web.platformViewRegistry.registerViewFactory(_tipoDaView, (int _) {
      final alvo = html.DivElement()
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center'
        ..style.width = '100%'
        ..style.height = '100%';
      _carregarScript().then((_) {
        _inicializar();
        _desenharBotao(alvo);
      }).catchError((Object _) {
        _aoFalhar?.call('Não foi possível carregar o login com Google. Confira a conexão e tente de novo.');
      });
      return alvo;
    });
    _viewRegistrada = true;
  }

  @override
  Widget botao({
    required void Function(String idToken) aoReceberToken,
    required void Function(String mensagem) aoFalhar,
  }) {
    _aoReceberToken = aoReceberToken;
    _aoFalhar = aoFalhar;
    _registrarView();
    return const SizedBox(
      height: _alturaBotao,
      child: HtmlElementView(viewType: _tipoDaView),
    );
  }
}
