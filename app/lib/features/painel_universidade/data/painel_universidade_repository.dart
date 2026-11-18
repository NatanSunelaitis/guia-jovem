import '../../../core/network/auth_api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../../admin/domain/universidade_admin.dart';
import '../../universidades/domain/avaliacao.dart';
import '../domain/painel_universidade.dart';

/// Painel da universidade (T23): leituras de gestão (qualquer situação do
/// cadastro) e as escritas da própria universidade. A API decide o que cada
/// situação pode alterar (403 `UNIVERSIDADE_NAO_APROVADA`).
class PainelUniversidadeRepository {
  List<T> _lista<T>(Map<String, dynamic> json, T Function(Map<String, dynamic>) deJson) => [
        for (final item in json['data'] as List<dynamic>) deJson(item as Map<String, dynamic>),
      ];

  Future<UniversidadeCadastro> reenviar(int universidadeId) async {
    final json = await authApiClient.post('/universidades/$universidadeId/reenviar');
    return UniversidadeCadastro.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<EstatisticaUniversidade> estatisticas(int universidadeId) async {
    final json = await authApiClient.get('/universidades/$universidadeId/estatisticas');
    return EstatisticaUniversidade.fromJson(json['data'] as Map<String, dynamic>);
  }

  // Campi (RF21, RF22).

  Future<List<CampusGestao>> campus(int universidadeId) async =>
      _lista(await authApiClient.get('/universidades/$universidadeId/gestao/campus'), CampusGestao.fromJson);

  Future<CampusGestao> criarCampus(int universidadeId, Map<String, dynamic> dados) async {
    final json = await authApiClient.post('/universidades/$universidadeId/campus', body: dados);
    return CampusGestao.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<CampusGestao> atualizarCampus(int id, Map<String, dynamic> dados) async {
    final json = await authApiClient.patch('/campus/$id', body: dados);
    return CampusGestao.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// 409 `UNICO_CAMPUS`, `CAMPUS_PRINCIPAL` ou `CAMPUS_COM_OFERTAS`.
  Future<void> excluirCampus(int id) => authApiClient.delete('/campus/$id');

  // Cursos e ofertas (RF19, RF20).

  Future<List<CursoGestao>> cursos(int universidadeId) async =>
      _lista(await authApiClient.get('/universidades/$universidadeId/gestao/cursos'), CursoGestao.fromJson);

  Future<void> criarCurso(int universidadeId, Map<String, dynamic> dados) =>
      authApiClient.post('/universidades/$universidadeId/cursos', body: dados);

  Future<void> atualizarCurso(int id, Map<String, dynamic> dados) => authApiClient.patch('/cursos/$id', body: dados);

  /// 409 `CURSO_OFERTADO` enquanto houver oferta em campus.
  Future<void> excluirCurso(int id) => authApiClient.delete('/cursos/$id');

  Future<void> criarOferta(int cursoId, {required int campusId, required String turno, int? vagas}) =>
      authApiClient.post('/cursos/$cursoId/ofertas', body: {'campusId': campusId, 'turno': turno, 'vagas': vagas});

  Future<void> atualizarOferta(int cursoId, int campusId, {required String turno, int? vagas}) =>
      authApiClient.patch('/cursos/$cursoId/ofertas/$campusId', body: {'turno': turno, 'vagas': vagas});

  Future<void> excluirOferta(int cursoId, int campusId) => authApiClient.delete('/cursos/$cursoId/ofertas/$campusId');

  // Programas aceitos (RF12, RF13, RF17).

  Future<List<ProgramaAceito>> programas(int universidadeId) async =>
      _lista(await authApiClient.get('/universidades/$universidadeId/gestao/programas'), ProgramaAceito.fromJson);

  /// Substitui o conjunto: [observacoes] tem uma entrada por programa aceito.
  Future<List<ProgramaAceito>> definirProgramas(int universidadeId, Map<int, String?> observacoes) async {
    final json = await authApiClient.put(
      '/universidades/$universidadeId/programas',
      body: {
        'programas': [
          for (final entrada in observacoes.entries) {'programaId': entrada.key, 'observacao': entrada.value},
        ],
      },
    );
    return _lista(json, ProgramaAceito.fromJson);
  }

  // Bolsas institucionais (RF11).

  Future<List<BolsaInstitucional>> bolsas(int universidadeId) async =>
      _lista(await authApiClient.get('/universidades/$universidadeId/gestao/bolsas'), BolsaInstitucional.fromJson);

  Future<void> criarBolsa(int universidadeId, Map<String, dynamic> dados) =>
      authApiClient.post('/universidades/$universidadeId/bolsas', body: dados);

  Future<void> atualizarBolsa(int universidadeId, int id, Map<String, dynamic> dados) =>
      authApiClient.patch('/universidades/$universidadeId/bolsas/$id', body: dados);

  Future<void> excluirBolsa(int universidadeId, int id) => authApiClient.delete('/universidades/$universidadeId/bolsas/$id');

  // Avaliações recebidas (somente leitura).

  Future<PaginatedResult<Avaliacao>> avaliacoes(int universidadeId, {int page = 1}) async {
    final json = await authApiClient.get('/universidades/$universidadeId/gestao/avaliacoes', query: {'page': page});
    return PaginatedResult.fromJson(json, Avaliacao.fromJson);
  }
}

/// Instância compartilhada; mutável para os testes substituírem.
PainelUniversidadeRepository painelUniversidadeRepository = PainelUniversidadeRepository();
