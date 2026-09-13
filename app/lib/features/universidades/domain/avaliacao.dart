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

  /// Só o primeiro nome; null se a conta do autor foi excluída (RNF17/RNF24).
  final String? autor;
}
