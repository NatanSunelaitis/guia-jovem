class ProgramaResumo {
  ProgramaResumo({
    required this.id,
    required this.nome,
    this.sigla,
    required this.tipo,
    required this.descricao,
    this.imagemUrl,
    this.universidadeId,
  });

  factory ProgramaResumo.fromJson(Map<String, dynamic> json) => ProgramaResumo(
        id: json['id'] as int,
        nome: json['nome'] as String,
        sigla: json['sigla'] as String?,
        tipo: json['tipo'] as String,
        descricao: json['descricao'] as String,
        imagemUrl: json['imagemUrl'] as String?,
        universidadeId: json['universidadeId'] as int?,
      );

  final int id;
  final String nome;
  final String? sigla;
  final String tipo;
  final String descricao;
  final String? imagemUrl;
  final int? universidadeId;
}

class ProgramaEvento {
  ProgramaEvento({required this.id, required this.titulo, this.descricao, required this.dataInicio, this.dataFim});

  factory ProgramaEvento.fromJson(Map<String, dynamic> json) => ProgramaEvento(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        descricao: json['descricao'] as String?,
        dataInicio: DateTime.parse(json['dataInicio'] as String),
        dataFim: json['dataFim'] != null ? DateTime.parse(json['dataFim'] as String) : null,
      );

  final int id;
  final String titulo;
  final String? descricao;
  final DateTime dataInicio;
  final DateTime? dataFim;
}

class UniversidadeQueAceita {
  UniversidadeQueAceita({required this.id, required this.nomeFantasia, this.logoUrl, this.observacao, this.cidade, this.estado});

  factory UniversidadeQueAceita.fromJson(Map<String, dynamic> json) => UniversidadeQueAceita(
        id: json['id'] as int,
        nomeFantasia: json['nomeFantasia'] as String,
        logoUrl: json['logoUrl'] as String?,
        observacao: json['observacao'] as String?,
        cidade: json['cidade'] as String?,
        estado: json['estado'] as String?,
      );

  /// Cidade do campus principal.
  final String? cidade;
  final String? estado;

  final int id;
  final String nomeFantasia;
  final String? logoUrl;
  final String? observacao;
}

class ProgramaDetalhe {
  ProgramaDetalhe({
    required this.id,
    required this.nome,
    this.sigla,
    required this.tipo,
    required this.descricao,
    this.requisitos,
    this.comoFunciona,
    this.linkOficial,
    this.imagemUrl,
    this.universidadeId,
    this.universidade,
    required this.eventos,
    required this.universidades,
    this.totalUniversidades = 0,
  });

  factory ProgramaDetalhe.fromJson(Map<String, dynamic> json) => ProgramaDetalhe(
        id: json['id'] as int,
        nome: json['nome'] as String,
        sigla: json['sigla'] as String?,
        tipo: json['tipo'] as String,
        descricao: json['descricao'] as String,
        requisitos: json['requisitos'] as String?,
        comoFunciona: json['comoFunciona'] as String?,
        linkOficial: json['linkOficial'] as String?,
        imagemUrl: json['imagemUrl'] as String?,
        universidadeId: json['universidadeId'] as int?,
        universidade: json['universidade'] is Map<String, dynamic>
            ? UniversidadeQueAceita.fromJson(json['universidade'] as Map<String, dynamic>)
            : null,
        eventos: (json['eventos'] as List<dynamic>? ?? [])
            .map((item) => ProgramaEvento.fromJson(item as Map<String, dynamic>))
            .toList(),
        universidades: (json['universidades'] as List<dynamic>? ?? [])
            .map((item) => UniversidadeQueAceita.fromJson(item as Map<String, dynamic>))
            .toList(),
        totalUniversidades: json['totalUniversidades'] as int? ?? (json['universidades'] as List<dynamic>? ?? const []).length,
      );

  /// Quantas universidades aceitam o programa; [universidades] é só a prévia.
  final int totalUniversidades;

  final int id;
  final String nome;
  final String? sigla;
  final String tipo;
  final String descricao;
  final String? requisitos;
  final String? comoFunciona;
  final String? linkOficial;
  final String? imagemUrl;
  final int? universidadeId;

  /// Universidade dona da bolsa institucional; nula nos programas globais.
  final UniversidadeQueAceita? universidade;
  final List<ProgramaEvento> eventos;
  final List<UniversidadeQueAceita> universidades;
}
