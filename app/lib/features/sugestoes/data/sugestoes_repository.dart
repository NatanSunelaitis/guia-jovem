import '../domain/sugestao.dart';

/// Sugestões do usuário logado (RF08, histórico do perfil T18).
class SugestoesRepository {
  /// A API de sugestões ainda não existe: até `GET /sugestoes/minhas` ser
  /// criada, o histórico fica vazio. Ao ligar, trocar o corpo por
  /// `authApiClient.get('/sugestoes/minhas')` e `Sugestao.fromJson`.
  Future<List<Sugestao>> minhas() async => const [];
}

/// Instância compartilhada; mutável para os testes substituírem.
SugestoesRepository sugestoesRepository = SugestoesRepository();
