/// Status do atendimento de uma sugestão (enum `StatusSugestao` da API).
enum StatusSugestao { emAnalise, aprovada, reprovada }

StatusSugestao statusSugestaoDe(String codigo) => switch (codigo) {
      'APROVADA' => StatusSugestao.aprovada,
      'REPROVADA' => StatusSugestao.reprovada,
      _ => StatusSugestao.emAnalise,
    };

/// Sugestão enviada pelo usuário (RF08), como virá de GET /sugestoes/minhas.
class Sugestao {
  Sugestao({
    required this.id,
    required this.titulo,
    required this.texto,
    required this.status,
    this.resposta,
    required this.criadoEm,
    this.universidadeNome,
  });

  factory Sugestao.fromJson(Map<String, dynamic> json) => Sugestao(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        texto: json['texto'] as String,
        status: statusSugestaoDe(json['status'] as String),
        resposta: json['resposta'] as String?,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
        universidadeNome: (json['universidade'] as Map<String, dynamic>?)?['nomeFantasia'] as String?,
      );

  final int id;
  final String titulo;
  final String texto;
  final StatusSugestao status;
  final String? resposta;
  final DateTime criadoEm;

  /// Universidade de destino; null quando a sugestão foi para a administração.
  final String? universidadeNome;
}
