/// Prisma serializa campos `Decimal` (ex.: media_avaliacao) como string em
/// JSON, não como número, para preservar precisão — então aceita os dois.
double? _parseDecimal(dynamic valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor as String);
}

class ProgramaTag {
  ProgramaTag({required this.id, required this.nome, this.sigla, required this.tipo, this.observacao});

  factory ProgramaTag.fromJson(Map<String, dynamic> json) => ProgramaTag(
        id: json['id'] as int,
        nome: json['nome'] as String,
        sigla: json['sigla'] as String?,
        tipo: json['tipo'] as String,
        observacao: json['observacao'] as String?,
      );

  final int id;
  final String nome;
  final String? sigla;
  final String tipo;
  final String? observacao;
}

class EnderecoResumo {
  EnderecoResumo({
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.cep,
  });

  factory EnderecoResumo.fromJson(Map<String, dynamic> json) => EnderecoResumo(
        logradouro: json['logradouro'] as String,
        numero: json['numero'] as String,
        complemento: json['complemento'] as String?,
        bairro: json['bairro'] as String,
        cidade: json['cidade'] as String,
        estado: json['estado'] as String,
        cep: json['cep'] as String?,
      );

  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String? cep;
}

class CampusResumo {
  CampusResumo({required this.id, required this.nome, this.cidade, this.estado, required this.principal});

  factory CampusResumo.fromJson(Map<String, dynamic> json) => CampusResumo(
        id: json['id'] as int,
        nome: json['nome'] as String,
        cidade: json['cidade'] as String?,
        estado: json['estado'] as String?,
        principal: json['principal'] as bool? ?? false,
      );

  final int id;
  final String nome;
  final String? cidade;
  final String? estado;
  final bool principal;
}

class UniversidadeResumo {
  UniversidadeResumo({
    required this.id,
    required this.nomeFantasia,
    this.logoUrl,
    required this.natureza,
    this.mediaAvaliacao,
    required this.totalAvaliacoes,
    this.cidade,
    this.estado,
    required this.programas,
  });

  factory UniversidadeResumo.fromJson(Map<String, dynamic> json) => UniversidadeResumo(
        id: json['id'] as int,
        nomeFantasia: json['nomeFantasia'] as String,
        logoUrl: json['logoUrl'] as String?,
        natureza: json['natureza'] as String,
        mediaAvaliacao: _parseDecimal(json['mediaAvaliacao']),
        totalAvaliacoes: json['totalAvaliacoes'] as int? ?? 0,
        cidade: json['cidade'] as String?,
        estado: json['estado'] as String?,
        programas: (json['programas'] as List<dynamic>? ?? [])
            .map((item) => ProgramaTag.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String nomeFantasia;
  final String? logoUrl;
  final String natureza;
  final double? mediaAvaliacao;
  final int totalAvaliacoes;
  final String? cidade;
  final String? estado;
  final List<ProgramaTag> programas;
}

class UniversidadeDetalhe {
  UniversidadeDetalhe({
    required this.id,
    required this.nomeFantasia,
    required this.razaoSocial,
    this.descricao,
    this.logoUrl,
    required this.natureza,
    this.linkPagina,
    this.linkSimulados,
    this.mediaAvaliacao,
    required this.totalAvaliacoes,
    this.enderecoPrincipal,
    required this.campus,
    required this.programasPorTipo,
  });

  factory UniversidadeDetalhe.fromJson(Map<String, dynamic> json) {
    final programasJson = json['programas'] as Map<String, dynamic>? ?? const {};

    return UniversidadeDetalhe(
      id: json['id'] as int,
      nomeFantasia: json['nomeFantasia'] as String,
      razaoSocial: json['razaoSocial'] as String,
      descricao: json['descricao'] as String?,
      logoUrl: json['logoUrl'] as String?,
      natureza: json['natureza'] as String,
      linkPagina: json['linkPagina'] as String?,
      linkSimulados: json['linkSimulados'] as String?,
      mediaAvaliacao: _parseDecimal(json['mediaAvaliacao']),
      totalAvaliacoes: json['totalAvaliacoes'] as int? ?? 0,
      enderecoPrincipal: json['enderecoPrincipal'] != null
          ? EnderecoResumo.fromJson(json['enderecoPrincipal'] as Map<String, dynamic>)
          : null,
      campus: (json['campus'] as List<dynamic>? ?? [])
          .map((item) => CampusResumo.fromJson(item as Map<String, dynamic>))
          .toList(),
      programasPorTipo: {
        for (final tipo in ['ENTRADA', 'FINANCIAMENTO', 'BOLSA'])
          tipo: (programasJson[tipo] as List<dynamic>? ?? [])
              .map((item) => ProgramaTag.fromJson({...item as Map<String, dynamic>, 'tipo': tipo}))
              .toList(),
      },
    );
  }

  final int id;
  final String nomeFantasia;
  final String razaoSocial;
  final String? descricao;
  final String? logoUrl;
  final String natureza;
  final String? linkPagina;
  final String? linkSimulados;
  final double? mediaAvaliacao;
  final int totalAvaliacoes;
  final EnderecoResumo? enderecoPrincipal;
  final List<CampusResumo> campus;
  final Map<String, List<ProgramaTag>> programasPorTipo;
}

class UniversidadeCampusItem {
  UniversidadeCampusItem({
    required this.id,
    required this.nome,
    this.telefoneCelular,
    this.telefoneFixo,
    this.emailCampus,
    required this.principal,
    required this.endereco,
    required this.cursos,
  });

  factory UniversidadeCampusItem.fromJson(Map<String, dynamic> json) => UniversidadeCampusItem(
        id: json['id'] as int,
        nome: json['nome'] as String,
        telefoneCelular: json['telefoneCelular'] as String?,
        telefoneFixo: json['telefoneFixo'] as String?,
        emailCampus: json['emailCampus'] as String?,
        principal: json['principal'] as bool? ?? false,
        endereco: EnderecoResumo.fromJson(json['endereco'] as Map<String, dynamic>),
        cursos: (json['cursos'] as List<dynamic>? ?? [])
            .map((item) => CursoOfertado.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String nome;
  final String? telefoneCelular;
  final String? telefoneFixo;
  final String? emailCampus;
  final bool principal;
  final EnderecoResumo endereco;
  final List<CursoOfertado> cursos;
}

class CursoOfertado {
  CursoOfertado({required this.id, required this.nome, this.turno, this.vagas});

  factory CursoOfertado.fromJson(Map<String, dynamic> json) => CursoOfertado(
        id: json['id'] as int,
        nome: json['nome'] as String,
        turno: json['turno'] as String?,
        vagas: json['vagas'] as int?,
      );

  final int id;
  final String nome;
  final String? turno;
  final int? vagas;
}

class UniversidadeCursoItem {
  UniversidadeCursoItem({
    required this.id,
    required this.nome,
    this.areaCurso,
    this.grau,
    this.modalidade,
    this.duracaoSemestres,
  });

  factory UniversidadeCursoItem.fromJson(Map<String, dynamic> json) => UniversidadeCursoItem(
        id: json['id'] as int,
        nome: json['nome'] as String,
        areaCurso: json['areaCurso'] as String?,
        grau: json['grau'] as String?,
        modalidade: json['modalidade'] as String?,
        duracaoSemestres: json['duracaoSemestres'] as int?,
      );

  final int id;
  final String nome;
  final String? areaCurso;
  final String? grau;
  final String? modalidade;
  final int? duracaoSemestres;
}
