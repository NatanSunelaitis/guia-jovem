import '../../../core/network/auth_api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/cadastros.dart';
import '../domain/dashboard.dart';

/// Dashboard (RF16) e cadastros do administrador: cursos (RF19), programas
/// globais e datas importantes (RF10, RF11, RF17). Todas exigem sessão D.
class CadastrosRepository {
  Future<ResumoDashboard> resumo() async {
    final json = await authApiClient.get('/estatisticas/resumo');
    return ResumoDashboard.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// [de] e [ate] em AAAA-MM-DD; [agrupar] 'dia' ou 'mes'.
  Future<AcessosPeriodo> acessos({required String de, required String ate, required String agrupar}) async {
    final json = await authApiClient.get('/estatisticas/visitas', query: {'de': de, 'ate': ate, 'agrupar': agrupar});
    return AcessosPeriodo.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<RankingDashboard> ranking({required String de, required String ate}) async {
    final json = await authApiClient.get('/estatisticas/ranking', query: {'de': de, 'ate': ate});
    return RankingDashboard.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PaginatedResult<CursoAdmin>> cursos({String? busca, int page = 1}) async {
    final json = await authApiClient.get(
      '/cursos/administracao',
      query: {'page': page, if (busca != null && busca.isNotEmpty) 'busca': busca},
    );
    return PaginatedResult.fromJson(json, CursoAdmin.fromJson);
  }

  Future<CursoAdmin> criarCurso(int universidadeId, Map<String, dynamic> dados) async {
    final json = await authApiClient.post('/universidades/$universidadeId/cursos', body: dados);
    return CursoAdmin.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<CursoAdmin> atualizarCurso(int id, Map<String, dynamic> dados) async {
    final json = await authApiClient.patch('/cursos/$id', body: dados);
    return CursoAdmin.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// 409 `CURSO_OFERTADO` enquanto o curso estiver ofertado em algum campus.
  Future<void> excluirCurso(int id) => authApiClient.delete('/cursos/$id');

  Future<PaginatedResult<ProgramaAdmin>> programas({required TipoPrograma tipo, String? busca, int page = 1}) async {
    final json = await authApiClient.get(
      '/programas/administracao',
      query: {'tipo': codigoTipoPrograma(tipo), 'page': page, if (busca != null && busca.isNotEmpty) 'busca': busca},
    );
    return PaginatedResult.fromJson(json, ProgramaAdmin.fromJson);
  }

  Future<ProgramaAdmin> programa(int id) async {
    final json = await authApiClient.get('/programas/administracao/$id');
    return ProgramaAdmin.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ProgramaAdmin> criarPrograma(Map<String, dynamic> dados) async {
    final json = await authApiClient.post('/programas', body: dados);
    return ProgramaAdmin.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ProgramaAdmin> atualizarPrograma(int id, Map<String, dynamic> dados) async {
    final json = await authApiClient.patch('/programas/$id', body: dados);
    return ProgramaAdmin.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// 409 `PROGRAMA_ACEITO` enquanto alguma universidade aceitar o programa.
  Future<void> excluirPrograma(int id) => authApiClient.delete('/programas/$id');

  Future<EventoPrograma> criarEvento(int programaId, Map<String, dynamic> dados) async {
    final json = await authApiClient.post('/programas/$programaId/eventos', body: dados);
    return EventoPrograma.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<EventoPrograma> atualizarEvento(int id, Map<String, dynamic> dados) async {
    final json = await authApiClient.patch('/programas/eventos/$id', body: dados);
    return EventoPrograma.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> excluirEvento(int id) => authApiClient.delete('/programas/eventos/$id');
}

/// Instância compartilhada; mutável para os testes substituírem.
CadastrosRepository cadastrosRepository = CadastrosRepository();
