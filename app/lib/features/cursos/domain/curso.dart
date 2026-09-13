class UniversidadeRefCurso {
  UniversidadeRefCurso({required this.id, required this.nomeFantasia, this.logoUrl});

  factory UniversidadeRefCurso.fromJson(Map<String, dynamic> json) => UniversidadeRefCurso(
        id: json['id'] as int,
        nomeFantasia: json['nomeFantasia'] as String,
        logoUrl: json['logoUrl'] as String?,
      );

  final int id;
  final String nomeFantasia;
  final String? logoUrl;
}

class CursoResumo {
  CursoResumo({
    required this.id,
    required this.nome,
    this.areaCurso,
    this.modalidade,
    this.grau,
    required this.universidade,
  });

  factory CursoResumo.fromJson(Map<String, dynamic> json) => CursoResumo(
        id: json['id'] as int,
        nome: json['nome'] as String,
        areaCurso: json['areaCurso'] as String?,
        modalidade: json['modalidade'] as String?,
        grau: json['grau'] as String?,
        universidade: UniversidadeRefCurso.fromJson(json['universidade'] as Map<String, dynamic>),
      );

  final int id;
  final String nome;
  final String? areaCurso;
  final String? modalidade;
  final String? grau;
  final UniversidadeRefCurso universidade;
}

class CursoDestaque {
  CursoDestaque({required this.nome, required this.totalOfertas});

  factory CursoDestaque.fromJson(Map<String, dynamic> json) =>
      CursoDestaque(nome: json['nome'] as String, totalOfertas: json['totalOfertas'] as int);

  final String nome;
  final int totalOfertas;
}

class CampusOndeOfertado {
  CampusOndeOfertado({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.estado,
    this.turno,
    this.vagas,
  });

  factory CampusOndeOfertado.fromJson(Map<String, dynamic> json) => CampusOndeOfertado(
        id: json['id'] as int,
        nome: json['nome'] as String,
        cidade: json['cidade'] as String,
        estado: json['estado'] as String,
        turno: json['turno'] as String?,
        vagas: json['vagas'] as int?,
      );

  final int id;
  final String nome;
  final String cidade;
  final String estado;
  final String? turno;
  final int? vagas;
}

class CursoDetalhe {
  CursoDetalhe({
    required this.id,
    required this.nome,
    this.areaCurso,
    this.notaMec,
    this.modalidade,
    this.grau,
    this.duracaoSemestres,
    this.descricao,
    required this.universidade,
    required this.campus,
  });

  factory CursoDetalhe.fromJson(Map<String, dynamic> json) => CursoDetalhe(
        id: json['id'] as int,
        nome: json['nome'] as String,
        areaCurso: json['areaCurso'] as String?,
        notaMec: json['notaMec'] as String?,
        modalidade: json['modalidade'] as String?,
        grau: json['grau'] as String?,
        duracaoSemestres: json['duracaoSemestres'] as int?,
        descricao: json['descricao'] as String?,
        universidade: UniversidadeRefCurso.fromJson(json['universidade'] as Map<String, dynamic>),
        campus: (json['campus'] as List<dynamic>? ?? [])
            .map((item) => CampusOndeOfertado.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String nome;
  final String? areaCurso;
  final String? notaMec;
  final String? modalidade;
  final String? grau;
  final int? duracaoSemestres;
  final String? descricao;
  final UniversidadeRefCurso universidade;
  final List<CampusOndeOfertado> campus;
}

class UniversidadeComCurso {
  UniversidadeComCurso({required this.cursoId, required this.universidade, required this.campus});

  factory UniversidadeComCurso.fromJson(Map<String, dynamic> json) => UniversidadeComCurso(
        cursoId: json['cursoId'] as int,
        universidade: UniversidadeRefCurso.fromJson(json['universidade'] as Map<String, dynamic>),
        campus: (json['campus'] as List<dynamic>? ?? [])
            .map((item) => CampusOndeOfertado.fromJson({...item as Map<String, dynamic>, 'turno': null, 'vagas': null}))
            .toList(),
      );

  final int cursoId;
  final UniversidadeRefCurso universidade;
  final List<CampusOndeOfertado> campus;
}

class CursoPorNome {
  CursoPorNome({required this.nome, required this.universidades});

  factory CursoPorNome.fromJson(Map<String, dynamic> json) => CursoPorNome(
        nome: json['nome'] as String,
        universidades: (json['universidades'] as List<dynamic>? ?? [])
            .map((item) => UniversidadeComCurso.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final String nome;
  final List<UniversidadeComCurso> universidades;
}
