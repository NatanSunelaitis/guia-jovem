import '../../universidades/domain/universidade.dart';

class CampusCursoDetalhe {
  CampusCursoDetalhe({
    required this.id,
    required this.nome,
    this.areaCurso,
    this.grau,
    this.modalidade,
    this.turno,
    this.vagas,
  });

  factory CampusCursoDetalhe.fromJson(Map<String, dynamic> json) => CampusCursoDetalhe(
        id: json['id'] as int,
        nome: json['nome'] as String,
        areaCurso: json['areaCurso'] as String?,
        grau: json['grau'] as String?,
        modalidade: json['modalidade'] as String?,
        turno: json['turno'] as String?,
        vagas: json['vagas'] as int?,
      );

  final int id;
  final String nome;
  final String? areaCurso;
  final String? grau;
  final String? modalidade;
  final String? turno;
  final int? vagas;
}

class UniversidadeResumidaRef {
  UniversidadeResumidaRef({required this.id, required this.nomeFantasia});

  factory UniversidadeResumidaRef.fromJson(Map<String, dynamic> json) =>
      UniversidadeResumidaRef(id: json['id'] as int, nomeFantasia: json['nomeFantasia'] as String);

  final int id;
  final String nomeFantasia;
}

class CampusDetalhe {
  CampusDetalhe({
    required this.id,
    required this.nome,
    this.telefoneCelular,
    this.telefoneFixo,
    this.emailCampus,
    required this.principal,
    required this.universidade,
    required this.endereco,
    this.totalCursos = 0,
    this.areasCursos = const [],
  });

  factory CampusDetalhe.fromJson(Map<String, dynamic> json) => CampusDetalhe(
        id: json['id'] as int,
        nome: json['nome'] as String,
        telefoneCelular: json['telefoneCelular'] as String?,
        telefoneFixo: json['telefoneFixo'] as String?,
        emailCampus: json['emailCampus'] as String?,
        principal: json['principal'] as bool? ?? false,
        universidade: UniversidadeResumidaRef.fromJson(json['universidade'] as Map<String, dynamic>),
        endereco: EnderecoResumo.fromJson(json['endereco'] as Map<String, dynamic>),
        totalCursos: json['totalCursos'] as int? ?? 0,
        areasCursos: (json['areasCursos'] as List<dynamic>? ?? const []).cast<String>(),
      );

  final int id;
  final String nome;
  final String? telefoneCelular;
  final String? telefoneFixo;
  final String? emailCampus;
  final bool principal;
  final UniversidadeResumidaRef universidade;
  final EnderecoResumo endereco;

  /// Os cursos vêm paginados de /campus/:id/cursos; aqui, o total e as
  /// áreas, para o filtro.
  final int totalCursos;
  final List<String> areasCursos;
}
