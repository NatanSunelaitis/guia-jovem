class Avaliacao {
  Avaliacao({required this.id, required this.nota, this.comentario, required this.criadoEm, this.autor});

  factory Avaliacao.fromJson(Map<String, dynamic> json) => Avaliacao(
        id: json['id'] as int,
        nota: json['nota'] as int,
        comentario: json['comentario'] as String?,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
        autor: json['autor'] as String?,
      );

  final int id;
  final int nota;
  final String? comentario;
  final DateTime criadoEm;

  /// Só o primeiro nome; null se a conta do autor foi excluída (RNF07).
  final String? autor;
}

/// A avaliação do próprio aluno logado (RF01), para abrir o modal preenchido.
class MinhaAvaliacao {
  MinhaAvaliacao({required this.id, required this.nota, this.comentario});

  factory MinhaAvaliacao.fromJson(Map<String, dynamic> json) => MinhaAvaliacao(
        id: json['id'] as int,
        nota: json['nota'] as int,
        comentario: json['comentario'] as String?,
      );

  final int id;
  final int nota;
  final String? comentario;
}

/// Item de GET /avaliacoes/minhas: a avaliação e a universidade avaliada.
class AvaliacaoDoAluno {
  AvaliacaoDoAluno({
    required this.id,
    required this.nota,
    this.comentario,
    required this.criadoEm,
    required this.universidadeId,
    required this.nomeUniversidade,
    this.logoUrl,
  });

  factory AvaliacaoDoAluno.fromJson(Map<String, dynamic> json) {
    final universidade = json['universidade'] as Map<String, dynamic>;
    return AvaliacaoDoAluno(
      id: json['id'] as int,
      nota: json['nota'] as int,
      comentario: json['comentario'] as String?,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      universidadeId: universidade['id'] as int,
      nomeUniversidade: universidade['nomeFantasia'] as String,
      logoUrl: universidade['logoUrl'] as String?,
    );
  }

  final int id;
  final int nota;
  final String? comentario;
  final DateTime criadoEm;
  final int universidadeId;
  final String nomeUniversidade;
  final String? logoUrl;
}

/// Resposta de POST/PUT de avaliação: a avaliação gravada e a média já
/// recalculada da universidade, para o detalhe atualizar sem recarregar.
class AvaliacaoGravada {
  AvaliacaoGravada({required this.avaliacao, this.mediaAvaliacao, required this.totalAvaliacoes});

  factory AvaliacaoGravada.fromJson(Map<String, dynamic> json) {
    final universidade = json['universidade'] as Map<String, dynamic>;
    final media = universidade['mediaAvaliacao'];
    return AvaliacaoGravada(
      avaliacao: MinhaAvaliacao.fromJson(json),
      mediaAvaliacao: media == null ? null : (media is num ? media.toDouble() : double.tryParse(media.toString())),
      totalAvaliacoes: universidade['totalAvaliacoes'] as int? ?? 0,
    );
  }

  final MinhaAvaliacao avaliacao;
  final double? mediaAvaliacao;
  final int totalAvaliacoes;
}
