import '../../../core/network/auth_api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/sugestao.dart';

/// Sugestões (RF08, RF14, RF15). Todas as chamadas exigem sessão.
class SugestoesRepository {
  /// Histórico do aluno logado (T18). A lista do perfil é curta; uma página
  /// com o máximo da API (100) basta, como nas outras abas.
  Future<List<Sugestao>> minhas() async {
    final json = await authApiClient.get('/sugestoes/minhas', query: {'pageSize': 100});
    return (json['data'] as List<dynamic>)
        .map((item) => Sugestao.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Sem [universidadeId], a sugestão vai para a equipe Guia Jovem.
  Future<Sugestao> enviar({required String titulo, required String texto, int? universidadeId}) async {
    final json = await authApiClient.post(
      '/sugestoes',
      body: {'titulo': titulo, 'texto': texto, if (universidadeId != null) 'universidadeId': universidadeId},
    );
    return Sugestao.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Recebidas pelo administrador (as da equipe) ou pela universidade (as dela).
  Future<PaginatedResult<Sugestao>> recebidas({StatusSugestao? status, int page = 1}) async {
    final json = await authApiClient.get(
      '/sugestoes',
      query: {'page': page, if (status != null) 'status': codigoStatusSugestao(status)},
    );
    return PaginatedResult.fromJson(json, Sugestao.fromJson);
  }

  Future<Sugestao> detalhe(int id) async {
    final json = await authApiClient.get('/sugestoes/$id');
    return Sugestao.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// RF15: [status] é aprovada ou reprovada, sempre com [resposta].
  Future<Sugestao> avaliar(int id, {required StatusSugestao status, required String resposta}) async {
    final json = await authApiClient.patch(
      '/sugestoes/$id/status',
      body: {'status': codigoStatusSugestao(status), 'resposta': resposta},
    );
    return Sugestao.fromJson(json['data'] as Map<String, dynamic>);
  }
}

/// Instância compartilhada; mutável para os testes substituírem.
SugestoesRepository sugestoesRepository = SugestoesRepository();
