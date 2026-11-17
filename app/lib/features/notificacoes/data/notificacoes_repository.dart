import '../../../core/network/auth_api_client.dart';
import '../domain/notificacao.dart';

/// Primeira página do sino com o total de não lidas (meta.naoLidas).
class PaginaNotificacoes {
  const PaginaNotificacoes({required this.itens, required this.naoLidas});

  final List<Notificacao> itens;
  final int naoLidas;
}

/// Notificações do usuário logado (RF14).
class NotificacoesRepository {
  Future<PaginaNotificacoes> recentes({int quantidade = 10}) async {
    final json = await authApiClient.get('/notificacoes', query: {'pageSize': quantidade});
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PaginaNotificacoes(
      itens: (json['data'] as List<dynamic>)
          .map((item) => Notificacao.fromJson(item as Map<String, dynamic>))
          .toList(),
      naoLidas: meta['naoLidas'] as int? ?? 0,
    );
  }

  Future<void> marcarLida(int id) async {
    await authApiClient.patch('/notificacoes/$id/lida');
  }

  Future<void> marcarTodasLidas() async {
    await authApiClient.patch('/notificacoes/lidas');
  }
}

/// Instância compartilhada; mutável para os testes substituírem.
NotificacoesRepository notificacoesRepository = NotificacoesRepository();
