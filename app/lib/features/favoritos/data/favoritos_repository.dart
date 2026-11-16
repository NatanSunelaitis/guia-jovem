import '../../../core/network/auth_api_client.dart';
import '../domain/pesquisa_salva.dart';

/// Faculdades salvas (Figura 25) e pesquisas salvas (classe pesquisaSalva),
/// exclusivas do perfil Aluno. Todas as chamadas exigem sessão.
class FavoritosRepository {
  FavoritosRepository({AuthApiClient? client}) : _override = client;

  final AuthApiClient? _override;
  AuthApiClient get _client => _override ?? authApiClient;

  /// Idempotente: salvar de novo uma universidade já salva não é erro.
  Future<void> salvarUniversidade(int universidadeId) async {
    await _client.post('/favoritos/universidades', body: {'universidadeId': universidadeId});
  }

  /// Idempotente: remover o que não está salvo não é erro.
  Future<void> removerUniversidade(int universidadeId) async {
    await _client.delete('/favoritos/universidades/$universidadeId');
  }

  /// A API responde 409 (PESQUISA_DUPLICADA) se o aluno já usou esse nome.
  Future<PesquisaSalva> salvarPesquisa({required String nome, required Map<String, dynamic> parametros}) async {
    final json = await _client.post('/pesquisas-salvas', body: {'nome': nome, 'parametros': parametros});
    return PesquisaSalva.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PesquisaSalva> obterPesquisa(int id) async {
    final json = await _client.get('/pesquisas-salvas/$id');
    return PesquisaSalva.fromJson(json['data'] as Map<String, dynamic>);
  }
}

final favoritosRepository = FavoritosRepository();
