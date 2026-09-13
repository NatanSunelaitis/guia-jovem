import 'package:flutter/foundation.dart' show ChangeNotifier, visibleForTesting;

import '../../../core/network/auth_api_client.dart';
import '../domain/usuario_sessao.dart';
import 'auth_repository.dart';

/// Estado de sessão do app inteiro: usuário logado (ou não), com bootstrap
/// a partir do token_storage no início e reação a refresh token
/// expirado/revogado (RF07/RF08). Usado como `refreshListenable` do
/// go_router para os guards de rota reagirem a login/logout.
class SessionController extends ChangeNotifier {
  SessionController({AuthRepository? repository}) : _repository = repository ?? authRepository {
    authApiClient.onSessaoExpirada = _aoSessaoExpirar;
  }

  final AuthRepository _repository;
  UsuarioSessao? _usuario;
  bool _carregando = true;

  UsuarioSessao? get usuario => _usuario;
  bool get autenticado => _usuario != null;

  /// true só durante o bootstrap inicial (restaurando sessão do storage).
  bool get carregando => _carregando;

  Future<void> bootstrap() async {
    _usuario = await _repository.tentarRestaurarSessao();
    _carregando = false;
    notifyListeners();
  }

  Future<void> login({required String email, required String senha}) async {
    final resultado = await _repository.login(email: email, senha: senha);
    _usuario = resultado.usuario;
    notifyListeners();
  }

  Future<void> registrarAluno({required String nome, required String email, required String senha}) async {
    final resultado = await _repository.registrarAluno(nome: nome, email: email, senha: senha);
    _usuario = resultado.usuario;
    notifyListeners();
  }

  Future<void> registrarUniversidade(Map<String, dynamic> corpo) async {
    final resultado = await _repository.registrarUniversidade(corpo);
    _usuario = resultado.usuario;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
    _usuario = null;
    notifyListeners();
  }

  Future<void> excluirConta() async {
    final usuarioAtual = _usuario;
    if (usuarioAtual == null) return;
    await _repository.excluirConta(usuarioAtual.id);
    _usuario = null;
    notifyListeners();
  }

  void _aoSessaoExpirar() {
    if (_usuario == null) return;
    _usuario = null;
    notifyListeners();
  }

  @visibleForTesting
  void redefinirParaTestes({UsuarioSessao? usuario, bool carregando = false}) {
    _usuario = usuario;
    _carregando = carregando;
    notifyListeners();
  }
}

final sessionController = SessionController();
