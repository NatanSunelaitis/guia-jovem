import '../../../core/network/api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/campus.dart';

class CampusRepository {
  CampusRepository({ApiClient? client}) : _override = client;

  final ApiClient? _override;
  ApiClient get _client => _override ?? apiClient;

  Future<CampusDetalhe> detalhe(int id) async {
    final json = await _client.get('/campus/$id');
    return CampusDetalhe.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Cursos oferecidos no campus, paginados, com busca e filtro por área.
  Future<PaginatedResult<CampusCursoDetalhe>> cursos(int id, {int pagina = 1, int porPagina = 12, String? busca, String? area}) async {
    final json = await _client.get('/campus/$id/cursos', query: {'page': pagina, 'pageSize': porPagina, 'q': busca, 'areaCurso': area});
    return PaginatedResult.fromJson(json, CampusCursoDetalhe.fromJson);
  }
}

final campusRepository = CampusRepository();
