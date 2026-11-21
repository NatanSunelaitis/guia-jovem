import '../../universidades/domain/universidade.dart' show ProgramaTag;

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
  CursoDestaque({required this.nome, this.areaCurso, required this.totalOfertas});

  factory CursoDestaque.fromJson(Map<String, dynamic> json) => CursoDestaque(
        nome: json['nome'] as String,
        areaCurso: json['areaCurso'] as String?,
        totalOfertas: json['totalOfertas'] as int,
      );

  final String nome;
  final String? areaCurso;
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

/// Universidade de uma oferta do curso, com a cidade do campus principal.
class UniversidadeDaOferta {
  UniversidadeDaOferta({required this.id, required this.nomeFantasia, this.logoUrl, this.natureza, this.cidade, this.estado});

  factory UniversidadeDaOferta.fromJson(Map<String, dynamic> json) => UniversidadeDaOferta(
        id: json['id'] as int,
        nomeFantasia: json['nomeFantasia'] as String,
        logoUrl: json['logoUrl'] as String?,
        natureza: json['natureza'] as String?,
        cidade: json['cidade'] as String?,
        estado: json['estado'] as String?,
      );

  final int id;
  final String nomeFantasia;
  final String? logoUrl;

  /// P pública, V privada.
  final String? natureza;
  final String? cidade;
  final String? estado;
}

/// Programas aceitos pela universidade, na ordem entrada, financiamento e
/// bolsa (com as bolsas institucionais dela).
List<ProgramaTag> _programasDoJson(dynamic json) {
  if (json is! Map<String, dynamic>) return const [];
  return [
    for (final tipo in const ['ENTRADA', 'FINANCIAMENTO', 'BOLSA'])
      for (final item in (json[tipo] as List<dynamic>? ?? const []))
        ProgramaTag.fromJson({...item as Map<String, dynamic>, 'tipo': tipo}),
  ];
}

/// Uma oferta do curso: cada curso pertence a uma universidade, com os
/// campi (turno e vagas) e os programas que ela aceita.
class OfertaCurso {
  OfertaCurso({
    required this.cursoId,
    this.areaCurso,
    this.grau,
    this.modalidade,
    this.duracaoSemestres,
    this.notaMec,
    this.descricao,
    required this.universidade,
    required this.campus,
    this.programas = const [],
  });

  factory OfertaCurso.fromJson(Map<String, dynamic> json) => OfertaCurso(
        cursoId: (json['cursoId'] ?? json['id']) as int,
        areaCurso: json['areaCurso'] as String?,
        grau: json['grau'] as String?,
        modalidade: json['modalidade'] as String?,
        duracaoSemestres: json['duracaoSemestres'] as int?,
        notaMec: json['notaMec'] as String?,
        descricao: json['descricao'] as String?,
        universidade: UniversidadeDaOferta.fromJson(json['universidade'] as Map<String, dynamic>),
        campus: (json['campus'] as List<dynamic>? ?? [])
            .map((item) => CampusOndeOfertado.fromJson(item as Map<String, dynamic>))
            .toList(),
        programas: _programasDoJson(json['programas']),
      );

  final int cursoId;
  final String? areaCurso;
  final String? grau;
  final String? modalidade;
  final int? duracaoSemestres;
  final String? notaMec;

  /// Texto formatado (Markdown simples).
  final String? descricao;
  final UniversidadeDaOferta universidade;
  final List<CampusOndeOfertado> campus;
  final List<ProgramaTag> programas;
}

/// Detalhe de um curso (T06 por id): uma oferta só.
class CursoDetalhe {
  CursoDetalhe({required this.nome, required this.oferta});

  factory CursoDetalhe.fromJson(Map<String, dynamic> json) =>
      CursoDetalhe(nome: json['nome'] as String, oferta: OfertaCurso.fromJson(json));

  final String nome;
  final OfertaCurso oferta;
}

class CursoPorNome {
  CursoPorNome({required this.nome, this.areaCurso, required this.universidades});

  factory CursoPorNome.fromJson(Map<String, dynamic> json) => CursoPorNome(
        nome: json['nome'] as String,
        areaCurso: json['areaCurso'] as String?,
        universidades: (json['universidades'] as List<dynamic>? ?? [])
            .map((item) => OfertaCurso.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final String nome;

  /// Área do curso, usada para a foto quando o curso não tem foto própria.
  final String? areaCurso;
  final List<OfertaCurso> universidades;
}

String _listaComE(List<String> itens) {
  if (itens.length <= 1) return itens.join();
  return '${itens.sublist(0, itens.length - 1).join(', ')} e ${itens.last}';
}

String _semestres(int semestres) {
  final anos = semestres ~/ 2;
  final meio = semestres.isOdd;
  final emAnos = anos == 0
      ? 'meio ano'
      : '$anos ${anos == 1 ? 'ano' : 'anos'}${meio ? ' e meio' : ''}';
  return '$semestres semestres ($emAnos)';
}

/// Duração no resumo do curso: "8 semestres (4 anos)" ou a faixa
/// "4 a 10 semestres" quando as ofertas têm durações diferentes.
String? duracaoDasOfertas(List<OfertaCurso> ofertas) {
  final duracoes = {for (final o in ofertas) if (o.duracaoSemestres != null) o.duracaoSemestres!}.toList()..sort();
  if (duracoes.isEmpty) return null;
  if (duracoes.length == 1) return duracoes.first == 1 ? '1 semestre' : _semestres(duracoes.first);
  return '${duracoes.first} a ${duracoes.last} semestres';
}

/// Valores distintos, na ordem em que aparecem, juntados com vírgula e "e".
String? valoresDistintos(Iterable<String?> valores) {
  final vistos = <String>[];
  for (final valor in valores) {
    if (valor != null && valor.trim().isNotEmpty && !vistos.contains(valor)) vistos.add(valor);
  }
  return vistos.isEmpty ? null : _listaComE(vistos);
}

/// Cidades onde o curso é dado (pelos campi da oferta; sem campi, a cidade
/// da universidade).
Set<String> cidadesDasOfertas(List<OfertaCurso> ofertas) => {
      for (final oferta in ofertas)
        if (oferta.campus.isNotEmpty)
          for (final campus in oferta.campus) '${campus.cidade}/${campus.estado}'
        else if (oferta.universidade.cidade != null)
          '${oferta.universidade.cidade}/${oferta.universidade.estado}',
    };

/// Descrição comum: quando todas as ofertas têm o mesmo texto, ele aparece
/// uma vez só, acima dos cards. Nulo quando há diferença ou nenhuma descrição.
String? descricaoComum(List<OfertaCurso> ofertas) {
  final textos = {for (final o in ofertas) o.descricao?.trim() ?? ''};
  if (textos.length != 1 || textos.first.isEmpty) return null;
  return textos.first;
}
