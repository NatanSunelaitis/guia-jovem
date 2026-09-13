import '../../../core/network/api_client.dart';
import '../domain/campus.dart';

class CampusRepository {
  CampusRepository({ApiClient? client}) : _override = client;

  final ApiClient? _override;
  ApiClient get _client => _override ?? apiClient;

  Future<CampusDetalhe> detalhe(int id) async {
    final json = await _client.get('/campus/$id');
    return CampusDetalhe.fromJson(json['data'] as Map<String, dynamic>);
  }
}

final campusRepository = CampusRepository();
