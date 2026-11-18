import '../../../core/network/auth_api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/usuario_sessao.dart';

class SessaoResultado {
  SessaoResultado({required this.usuario});

  final UsuarioSessao usuario;
}

class AuthRepository {
  AuthRepository({AuthApiClient? client}) : _override = client;

  final AuthApiClient? _override;
  AuthApiClient get _client => _override ?? authApiClient;

  Future<SessaoResultado> _autenticarE(Map<String, dynamic> json) async {
    final dados = json['data'] as Map<String, dynamic>;
    await tokenStorage.salvar(accessToken: dados['accessToken'] as String, refreshToken: dados['refreshToken'] as String);
    return SessaoResultado(usuario: UsuarioSessao.fromJson(dados['usuario'] as Map<String, dynamic>));
  }

  Future<SessaoResultado> registrarAluno({required String nome, required String email, required String senha}) async {
    final json = await _client.post('/auth/register/aluno', body: {'nome': nome, 'email': email, 'senha': senha});
    return _autenticarE(json);
  }

  Future<SessaoResultado> registrarUniversidade(Map<String, dynamic> corpo) async {
    final json = await _client.post('/auth/register/universidade', body: corpo);
    return _autenticarE(json);
  }

  Future<SessaoResultado> login({required String email, required String senha}) async {
    final json = await _client.post('/auth/login', body: {'email': email, 'senha': senha});
    return _autenticarE(json);
  }

  /// RF05 (Quadro 8): o ID token do Google; sem conta com o e-mail, a API
  /// cria uma conta de aluno.
  Future<SessaoResultado> loginComGoogle(String idToken) async {
    final json = await _client.post('/auth/google', body: {'idToken': idToken});
    return _autenticarE(json);
  }

  Future<void> logout() async {
    final refreshToken = await tokenStorage.lerRefreshToken();
    if (refreshToken != null) {
      try {
        await _client.post('/auth/logout', body: {'refreshToken': refreshToken});
      } catch (_) {
        // Mesmo se a chamada falhar (ex.: token já expirado), a sessão local é encerrada.
      }
    }
    await tokenStorage.limpar();
  }

  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword({required String token, required String novaSenha}) async {
    await _client.post('/auth/reset-password', body: {'token': token, 'novaSenha': novaSenha});
  }

  /// T16 Editar perfil: o próprio usuário só altera o nome (o e-mail é fixo).
  Future<String> atualizarNome(int usuarioId, String nome) async {
    final json = await _client.patch('/usuarios/$usuarioId', body: {'nome': nome});
    return (json['data'] as Map<String, dynamic>)['nome'] as String;
  }

  /// T21: a API confere a senha atual e revoga todas as sessões do usuário.
  Future<void> alterarSenha(
    int usuarioId, {
    required String senhaAtual,
    required String novaSenha,
    required String confirmacao,
  }) async {
    await _client.patch(
      '/usuarios/$usuarioId/senha',
      body: {'senhaAtual': senhaAtual, 'novaSenha': novaSenha, 'confirmacao': confirmacao},
    );
  }

  Future<void> excluirConta(int usuarioId) async {
    await _client.delete('/usuarios/$usuarioId', body: {'confirmacao': 'EXCLUIR'});
    await tokenStorage.limpar();
  }

  Future<UsuarioSessao?> tentarRestaurarSessao() async {
    final accessToken = await tokenStorage.lerAccessToken();
    if (accessToken == null) return null;

    try {
      final json = await _client.get('/auth/me');
      return UsuarioSessao.fromJson(json['data'] as Map<String, dynamic>);
    } catch (_) {
      await tokenStorage.limpar();
      return null;
    }
  }
}

final authRepository = AuthRepository();
