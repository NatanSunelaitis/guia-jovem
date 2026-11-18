int _int(dynamic valor) => (valor as num?)?.toInt() ?? 0;

/// Cartões do dashboard (`GET /estatisticas/resumo`, RF16).
class ResumoDashboard {
  ResumoDashboard({
    required this.usuarios,
    required this.alunos,
    required this.contasUniversidade,
    required this.administradores,
    required this.universidadesAprovadas,
    required this.universidadesPendentes,
    required this.universidadesReprovadas,
    required this.universidadesInativas,
    required this.cursos,
    required this.programas,
    required this.programasEntrada,
    required this.programasFinanciamento,
    required this.programasBolsa,
  });

  factory ResumoDashboard.fromJson(Map<String, dynamic> json) {
    final usuarios = json['usuariosPorPerfil'] as Map<String, dynamic>;
    final universidades = json['universidadesPorStatus'] as Map<String, dynamic>;
    final programas = json['programasPorTipo'] as Map<String, dynamic>;
    return ResumoDashboard(
      usuarios: _int(usuarios['total']),
      alunos: _int(usuarios['A']),
      contasUniversidade: _int(usuarios['U']),
      administradores: _int(usuarios['D']),
      universidadesAprovadas: _int(universidades['A']),
      universidadesPendentes: _int(universidades['P']),
      universidadesReprovadas: _int(universidades['R']),
      universidadesInativas: _int(universidades['I']),
      cursos: _int(json['cursos']),
      programas: _int(programas['total']),
      programasEntrada: _int(programas['ENTRADA']),
      programasFinanciamento: _int(programas['FINANCIAMENTO']),
      programasBolsa: _int(programas['BOLSA']),
    );
  }

  final int usuarios;
  final int alunos;
  final int contasUniversidade;
  final int administradores;
  final int universidadesAprovadas;
  final int universidadesPendentes;
  final int universidadesReprovadas;
  final int universidadesInativas;
  final int cursos;
  final int programas;
  final int programasEntrada;
  final int programasFinanciamento;
  final int programasBolsa;
}

class PontoAcessos {
  PontoAcessos({required this.periodo, required this.visitas, required this.loginsUnicos});

  factory PontoAcessos.fromJson(Map<String, dynamic> json) => PontoAcessos(
        periodo: json['periodo'] as String,
        visitas: _int(json['visitas']),
        loginsUnicos: _int(json['loginsUnicos']),
      );

  /// AAAA-MM-DD (dia) ou AAAA-MM (mês).
  final String periodo;
  final int visitas;
  final int loginsUnicos;

  /// Rótulo curto para o eixo: dd/mm no dia, mm/aa no mês.
  String get rotulo {
    final partes = periodo.split('-');
    if (partes.length == 3) return '${partes[2]}/${partes[1]}';
    return '${partes[1]}/${partes[0].substring(2)}';
  }
}

/// Visitas e logins únicos no período (`GET /estatisticas/visitas`).
class AcessosPeriodo {
  AcessosPeriodo({required this.totalVisitas, required this.loginsUnicos, required this.serie});

  factory AcessosPeriodo.fromJson(Map<String, dynamic> json) => AcessosPeriodo(
        totalVisitas: _int(json['totalVisitas']),
        loginsUnicos: _int(json['loginsUnicos']),
        serie: [
          for (final ponto in json['serie'] as List<dynamic>) PontoAcessos.fromJson(ponto as Map<String, dynamic>),
        ],
      );

  final int totalVisitas;

  /// Contas distintas no período inteiro.
  final int loginsUnicos;
  final List<PontoAcessos> serie;
}

class ItemRanking {
  ItemRanking({required this.id, required this.nome, required this.visitas});

  factory ItemRanking.fromJson(Map<String, dynamic> json) =>
      ItemRanking(id: json['id'] as int, nome: json['nome'] as String, visitas: _int(json['visitas']));

  final int id;
  final String nome;
  final int visitas;
}

/// Mais acessados no período (`GET /estatisticas/ranking`).
class RankingDashboard {
  RankingDashboard({required this.universidades, required this.programas, required this.cursos});

  factory RankingDashboard.fromJson(Map<String, dynamic> json) {
    List<ItemRanking> lista(String chave) => [
          for (final item in json[chave] as List<dynamic>? ?? const []) ItemRanking.fromJson(item as Map<String, dynamic>),
        ];
    return RankingDashboard(universidades: lista('universidades'), programas: lista('programas'), cursos: lista('cursos'));
  }

  final List<ItemRanking> universidades;
  final List<ItemRanking> programas;
  final List<ItemRanking> cursos;
}
