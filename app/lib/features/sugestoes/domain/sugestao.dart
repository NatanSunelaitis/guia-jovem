/// Status do atendimento de uma sugestão (enum `StatusSugestao` da API).
enum StatusSugestao { emAnalise, aprovada, reprovada }

StatusSugestao statusSugestaoDe(String codigo) => switch (codigo) {
      'APROVADA' => StatusSugestao.aprovada,
      'REPROVADA' => StatusSugestao.reprovada,
      _ => StatusSugestao.emAnalise,
    };

/// Código do status na API (filtro de GET /sugestoes e avaliação).
String codigoStatusSugestao(StatusSugestao status) => switch (status) {
      StatusSugestao.aprovada => 'APROVADA',
      StatusSugestao.reprovada => 'REPROVADA',
      StatusSugestao.emAnalise => 'EM_ANALISE',
    };

/// Sugestão (RF08), como vem de GET /sugestoes/minhas, GET /sugestoes e
/// GET /sugestoes/:id. [autorNome] e [podeAvaliar] só vêm para o destinatário.
class Sugestao {
  Sugestao({
    required this.id,
    required this.titulo,
    required this.texto,
    required this.status,
    this.resposta,
    required this.criadoEm,
    this.avaliadoEm,
    this.universidadeId,
    this.universidadeNome,
    this.autorNome,
    this.podeAvaliar = false,
  });

  factory Sugestao.fromJson(Map<String, dynamic> json) {
    final universidade = json['universidade'] as Map<String, dynamic>?;
    final autor = json['autor'] as Map<String, dynamic>?;
    final avaliadoEm = json['avaliadoEm'] as String?;
    return Sugestao(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      texto: json['texto'] as String,
      status: statusSugestaoDe(json['status'] as String),
      resposta: json['resposta'] as String?,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      avaliadoEm: avaliadoEm == null ? null : DateTime.parse(avaliadoEm),
      universidadeId: universidade?['id'] as int?,
      universidadeNome: universidade?['nomeFantasia'] as String?,
      autorNome: autor?['nome'] as String?,
      podeAvaliar: json['podeAvaliar'] as bool? ?? false,
    );
  }

  final int id;
  final String titulo;
  final String texto;
  final StatusSugestao status;
  final String? resposta;
  final DateTime criadoEm;

  /// Data da avaliação (RF15); null enquanto está em análise.
  final DateTime? avaliadoEm;

  /// Universidade de destino; null quando a sugestão foi para a administração.
  final int? universidadeId;
  final String? universidadeNome;

  /// Nome do autor, para o destinatário; null se a conta foi excluída.
  final String? autorNome;

  /// O usuário logado é o destinatário e a sugestão ainda está em análise.
  final bool podeAvaliar;

  String get destino => universidadeNome ?? 'Equipe Guia Jovem';
}
