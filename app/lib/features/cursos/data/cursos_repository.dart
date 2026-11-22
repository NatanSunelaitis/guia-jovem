import '../../../core/network/api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/curso.dart';

class FiltrosCursos {
  const FiltrosCursos({this.q, this.areaCurso, this.modalidade, this.grau, this.cidade, this.estado, this.page = 1});

  final String? q;
  final String? areaCurso;
  final String? modalidade;
  final String? grau;
  final String? cidade;
  final String? estado;
  final int page;

  Map<String, dynamic> toQuery() => {
        if (q != null && q!.isNotEmpty) 'q': q,
        if (areaCurso != null && areaCurso!.isNotEmpty) 'areaCurso': areaCurso,
        if (modalidade != null) 'modalidade': modalidade,
        if (grau != null) 'grau': grau,
        if (cidade != null && cidade!.isNotEmpty) 'cidade': cidade,
        if (estado != null && estado!.isNotEmpty) 'estado': estado,
        'page': page,
      };
}

class CursosRepository {
  CursosRepository({ApiClient? client}) : _override = client;

  final ApiClient? _override;
  ApiClient get _client => _override ?? apiClient;

  Future<PaginatedResult<CursoResumo>> listar(FiltrosCursos filtros) async {
    final json = await _client.get('/cursos', query: filtros.toQuery());
    return PaginatedResult.fromJson(json, CursoResumo.fromJson);
  }

  Future<List<CursoDestaque>> destaques({int limite = 8, String? q, String? areaCurso}) async {
    final json = await _client.get('/cursos/destaques', query: {
      'limite': limite,
      if (q != null && q.isNotEmpty) 'q': q,
      if (areaCurso != null && areaCurso.isNotEmpty) 'areaCurso': areaCurso,
    });
    return (json['data'] as List<dynamic>).map((item) => CursoDestaque.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Áreas dos cursos cadastrados, para o filtro "Área do curso".
  Future<List<String>> areas() async {
    final json = await _client.get('/cursos/areas');
    return (json['data'] as List<dynamic>).cast<String>();
  }

  Future<CursoDetalhe> detalhe(int id) async {
    final json = await _client.get('/cursos/$id');
    return CursoDetalhe.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<CursoPorNome> porNome(String nome) async {
    final json = await _client.get('/cursos/nome/${Uri.encodeComponent(nome)}');
    return CursoPorNome.fromJson(json['data'] as Map<String, dynamic>);
  }
}

final cursosRepository = CursosRepository();
