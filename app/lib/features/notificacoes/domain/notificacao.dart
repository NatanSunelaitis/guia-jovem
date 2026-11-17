/// Notificação do sino (RF14), como vem de GET /notificacoes.
class Notificacao {
  Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    this.referenciaTipo,
    this.referenciaId,
    required this.lida,
    required this.criadoEm,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) => Notificacao(
        id: json['id'] as int,
        tipo: json['tipo'] as String,
        titulo: json['titulo'] as String,
        mensagem: json['mensagem'] as String,
        referenciaTipo: json['referenciaTipo'] as String?,
        referenciaId: json['referenciaId'] as int?,
        lida: json['lida'] as bool? ?? false,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );

  final int id;

  /// NOVA_SUGESTAO | SUGESTAO_AVALIADA | UNIVERSIDADE_PENDENTE | UNIVERSIDADE_APROVADA
  final String tipo;
  final String titulo;
  final String mensagem;

  /// O que abrir ao clicar: `sugestao` ou `universidade`, com o id em [referenciaId].
  final String? referenciaTipo;
  final int? referenciaId;
  final bool lida;
  final DateTime criadoEm;

  Notificacao comoLida() => Notificacao(
        id: id,
        tipo: tipo,
        titulo: titulo,
        mensagem: mensagem,
        referenciaTipo: referenciaTipo,
        referenciaId: referenciaId,
        lida: true,
        criadoEm: criadoEm,
      );
}
