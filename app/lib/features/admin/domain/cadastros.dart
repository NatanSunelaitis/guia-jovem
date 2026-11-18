/// Curso no cadastro do administrador (`GET /cursos/administracao`, RF19).
class CursoAdmin {
  CursoAdmin({
    required this.id,
    required this.nome,
    required this.universidadeId,
    required this.universidadeNome,
    required this.totalCampus,
    this.areaCurso,
    this.notaMec,
    this.modalidade,
    this.grau,
    this.duracaoSemestres,
    this.descricao,
  });

  factory CursoAdmin.fromJson(Map<String, dynamic> json) {
    final universidade = json['universidade'] as Map<String, dynamic>? ?? const {};
    return CursoAdmin(
      id: json['id'] as int,
      nome: json['nome'] as String,
      areaCurso: json['areaCurso'] as String?,
      notaMec: json['notaMec'] as String?,
      modalidade: json['modalidade'] as String?,
      grau: json['grau'] as String?,
      duracaoSemestres: json['duracaoSemestres'] as int?,
      descricao: json['descricao'] as String?,
      universidadeId: universidade['id'] as int? ?? 0,
      universidadeNome: universidade['nomeFantasia'] as String? ?? '-',
      totalCampus: json['totalCampus'] as int? ?? 0,
    );
  }

  final int id;
  final String nome;
  final String? areaCurso;
  final String? notaMec;
  final String? modalidade;
  final String? grau;
  final int? duracaoSemestres;
  final String? descricao;
  final int universidadeId;
  final String universidadeNome;

  /// Campus onde o curso é ofertado (impede a exclusão).
  final int totalCampus;
}

/// Os três tipos de programa usam a mesma estrutura (RF10, RF11, RF17).
enum TipoPrograma { entrada, financiamento, bolsa }

TipoPrograma tipoProgramaDe(String codigo) => switch (codigo) {
      'FINANCIAMENTO' => TipoPrograma.financiamento,
      'BOLSA' => TipoPrograma.bolsa,
      _ => TipoPrograma.entrada,
    };

String codigoTipoPrograma(TipoPrograma tipo) => switch (tipo) {
      TipoPrograma.entrada => 'ENTRADA',
      TipoPrograma.financiamento => 'FINANCIAMENTO',
      TipoPrograma.bolsa => 'BOLSA',
    };

/// Data importante do programa (programa_evento).
class EventoPrograma {
  EventoPrograma({required this.id, required this.titulo, required this.dataInicio, this.descricao, this.dataFim});

  factory EventoPrograma.fromJson(Map<String, dynamic> json) => EventoPrograma(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        descricao: json['descricao'] as String?,
        dataInicio: json['dataInicio'] as String,
        dataFim: json['dataFim'] as String?,
      );

  final int id;
  final String titulo;
  final String? descricao;

  /// AAAA-MM-DD.
  final String dataInicio;
  final String? dataFim;
}

/// AAAA-MM-DD para dd/mm/aaaa.
String dataBrasileira(String iso) {
  final partes = iso.split('-');
  return partes.length == 3 ? '${partes[2]}/${partes[1]}/${partes[0]}' : iso;
}

/// dd/mm/aaaa para AAAA-MM-DD, ou null se não for uma data válida.
String? dataIsoDe(String texto) {
  final partes = texto.trim().split('/');
  if (partes.length != 3) return null;
  final dia = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  final ano = int.tryParse(partes[2]);
  if (dia == null || mes == null || ano == null || ano < 1900) return null;
  final data = DateTime.utc(ano, mes, dia);
  if (data.day != dia || data.month != mes) return null;
  return '${ano.toString().padLeft(4, '0')}-${mes.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';
}

/// Programa global no cadastro do administrador, com as datas importantes.
class ProgramaAdmin {
  ProgramaAdmin({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.descricao,
    required this.totalUniversidades,
    required this.eventos,
    this.sigla,
    this.requisitos,
    this.comoFunciona,
    this.linkOficial,
    this.imagemUrl,
  });

  factory ProgramaAdmin.fromJson(Map<String, dynamic> json) => ProgramaAdmin(
        id: json['id'] as int,
        nome: json['nome'] as String,
        sigla: json['sigla'] as String?,
        tipo: tipoProgramaDe(json['tipo'] as String),
        descricao: json['descricao'] as String,
        requisitos: json['requisitos'] as String?,
        comoFunciona: json['comoFunciona'] as String?,
        linkOficial: json['linkOficial'] as String?,
        imagemUrl: json['imagemUrl'] as String?,
        totalUniversidades: json['totalUniversidades'] as int? ?? 0,
        eventos: [
          for (final evento in json['eventos'] as List<dynamic>? ?? const [])
            EventoPrograma.fromJson(evento as Map<String, dynamic>),
        ],
      );

  final int id;
  final String nome;
  final String? sigla;
  final TipoPrograma tipo;
  final String descricao;
  final String? requisitos;
  final String? comoFunciona;
  final String? linkOficial;
  final String? imagemUrl;

  /// Universidades que aceitam o programa (impede a exclusão).
  final int totalUniversidades;
  final List<EventoPrograma> eventos;
}
