import '../../../core/network/api_client.dart';
import '../../../core/network/auth_api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../../auth/data/session_controller.dart';
import '../domain/avaliacao.dart';
import '../domain/universidade.dart';

class FiltrosUniversidades {
  const FiltrosUniversidades({
    this.q,
    this.cidade,
    this.estado,
    this.natureza,
    this.programaId,
    this.cursoId,
    this.areaCurso,
    this.notaMinima,
    this.sort,
    this.page = 1,
  });

  final String? q;
  final String? cidade;
  final String? estado;
  final String? natureza;
  final int? programaId;
  final int? cursoId;
  final String? areaCurso;
  final double? notaMinima;
  final String? sort;
  final int page;

  Map<String, dynamic> toQuery() => {
        if (q != null && q!.isNotEmpty) 'q': q,
        if (cidade != null && cidade!.isNotEmpty) 'cidade': cidade,
        if (estado != null && estado!.isNotEmpty) 'estado': estado,
        if (natureza != null) 'natureza': natureza,
        if (programaId != null) 'programaId': programaId,
        if (cursoId != null) 'cursoId': cursoId,
        if (areaCurso != null && areaCurso!.isNotEmpty) 'areaCurso': areaCurso,
        if (notaMinima != null) 'notaMinima': notaMinima,
        if (sort != null) 'sort': sort,
        'page': page,
      };

  FiltrosUniversidades copyWith({
    String? q,
    String? cidade,
    String? estado,
    String? natureza,
    String? areaCurso,
    double? notaMinima,
    String? sort,
    int? page,
  }) {
    return FiltrosUniversidades(
      q: q ?? this.q,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      natureza: natureza ?? this.natureza,
      programaId: programaId,
      cursoId: cursoId,
      areaCurso: areaCurso ?? this.areaCurso,
      notaMinima: notaMinima ?? this.notaMinima,
      sort: sort ?? this.sort,
      page: page ?? this.page,
    );
  }
}

class UniversidadesRepository {
  UniversidadesRepository({ApiClient? client}) : _override = client;

  final ApiClient? _override;
  ApiClient get _client => _override ?? apiClient;

  /// Pesquisa e detalhe são públicos, mas com sessão a API diz se a
  /// universidade está salva e qual é a avaliação do aluno: nesse caso a
  /// leitura vai pelo AuthApiClient, que manda o token e renova a sessão.
  Future<Map<String, dynamic>> _getCatalogo(String path, {Map<String, dynamic>? query}) {
    if (_override == null && sessionController.autenticado) {
      return authApiClient.get(path, query: query);
    }
    return _client.get(path, query: query);
  }

  Future<PaginatedResult<UniversidadeResumo>> listar(FiltrosUniversidades filtros) async {
    final json = await _getCatalogo('/universidades', query: filtros.toQuery());
    return PaginatedResult.fromJson(json, UniversidadeResumo.fromJson);
  }

  Future<List<UniversidadeResumo>> destaques({int limite = 8}) async {
    final json = await _client.get('/universidades/destaques', query: {'limite': limite});
    return (json['data'] as List<dynamic>)
        .map((item) => UniversidadeResumo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UniversidadeDetalhe> detalhe(int id) async {
    final json = await _getCatalogo('/universidades/$id');
    return UniversidadeDetalhe.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<UniversidadeCampusItem>> campus(int id) async {
    final json = await _client.get('/universidades/$id/campus');
    return (json['data'] as List<dynamic>)
        .map((item) => UniversidadeCampusItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<UniversidadeCursoItem>> cursos(int id) async {
    final json = await _client.get('/universidades/$id/cursos');
    return (json['data'] as List<dynamic>)
        .map((item) => UniversidadeCursoItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PaginatedResult<Avaliacao>> avaliacoes(int id, {int page = 1}) async {
    final json = await _client.get('/universidades/$id/avaliacoes', query: {'page': page});
    return PaginatedResult.fromJson(json, Avaliacao.fromJson);
  }

  /// RF02: uma avaliação por aluno por universidade (a API responde 409 se já existe).
  Future<AvaliacaoGravada> avaliar(int universidadeId, {required int nota, String? comentario}) async {
    final json = await authApiClient.post(
      '/universidades/$universidadeId/avaliacoes',
      body: {'nota': nota, 'comentario': comentario},
    );
    return AvaliacaoGravada.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Avaliações do aluno logado, com a universidade de cada uma (perfil).
  Future<List<AvaliacaoDoAluno>> minhasAvaliacoes() async {
    final json = await authApiClient.get('/avaliacoes/minhas', query: {'pageSize': 100});
    return (json['data'] as List<dynamic>)
        .map((item) => AvaliacaoDoAluno.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AvaliacaoGravada> editarAvaliacao(int avaliacaoId, {required int nota, String? comentario}) async {
    final json = await authApiClient.put('/avaliacoes/$avaliacaoId', body: {'nota': nota, 'comentario': comentario});
    return AvaliacaoGravada.fromJson(json['data'] as Map<String, dynamic>);
  }
}

final universidadesRepository = UniversidadesRepository();
