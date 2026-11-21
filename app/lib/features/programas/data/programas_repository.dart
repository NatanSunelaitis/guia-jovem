import '../../../core/network/api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../domain/programa.dart';

class FiltrosProgramas {
  const FiltrosProgramas({this.tipo, this.q, this.universidadeId, this.page = 1});

  final String? tipo;
  final String? q;
  final int? universidadeId;
  final int page;

  Map<String, dynamic> toQuery() => {
        if (tipo != null) 'tipo': tipo,
        if (q != null && q!.isNotEmpty) 'q': q,
        if (universidadeId != null) 'universidadeId': universidadeId,
        'page': page,
      };
}

class ProgramasRepository {
  ProgramasRepository({ApiClient? client}) : _override = client;

  final ApiClient? _override;
  ApiClient get _client => _override ?? apiClient;

  Future<PaginatedResult<ProgramaResumo>> listar(FiltrosProgramas filtros) async {
    final json = await _client.get('/programas', query: filtros.toQuery());
    return PaginatedResult.fromJson(json, ProgramaResumo.fromJson);
  }

  /// [tipo] filtra por ENTRADA, FINANCIAMENTO ou BOLSA (a home usa ENTRADA).
  Future<List<ProgramaResumo>> destaques({int limite = 8, String? tipo}) async {
    final json = await _client.get('/programas/destaques', query: {'limite': limite, 'tipo': tipo});
    return (json['data'] as List<dynamic>).map((item) => ProgramaResumo.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Universidades que aceitam o programa, paginadas, com busca por nome ou cidade.
  Future<PaginatedResult<UniversidadeQueAceita>> universidades(int id, {int pagina = 1, int porPagina = 8, String? busca}) async {
    final json = await _client.get('/programas/$id/universidades', query: {'page': pagina, 'pageSize': porPagina, 'q': busca});
    return PaginatedResult.fromJson(json, UniversidadeQueAceita.fromJson);
  }

  Future<ProgramaDetalhe> detalhe(int id) async {
    final json = await _client.get('/programas/$id');
    return ProgramaDetalhe.fromJson(json['data'] as Map<String, dynamic>);
  }
}

final programasRepository = ProgramasRepository();
