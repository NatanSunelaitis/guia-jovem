import '../../admin/domain/cadastros.dart';
import '../../admin/domain/universidade_admin.dart';
import '../../../shared/utils/plural.dart';

/// Turnos aceitos pela API na oferta de curso em campus (RF20).
const turnosOferta = ['Matutino', 'Vespertino', 'Noturno', 'Integral'];

/// O que a conta de universidade pode fazer em cada seção, pela situação do
/// cadastro (Pendência 3): pendente e aprovada alteram tudo; reprovada só
/// corrige a instituição e os campi; inativa só lê.
class AcessoPainel {
  const AcessoPainel(this.status);

  final StatusUniversidade status;

  bool get _ativa => status == StatusUniversidade.pendente || status == StatusUniversidade.aprovada;

  /// Dados da instituição e campi.
  bool get editaCadastro => status != StatusUniversidade.inativa;

  /// Cursos, ofertas, programas aceitos e bolsas institucionais.
  bool get editaDominio => _ativa;

  /// Aviso das seções em modo leitura, ou null quando a seção é editável.
  String? avisoLeitura({required bool cadastro}) {
    if (cadastro ? editaCadastro : editaDominio) return null;
    return status == StatusUniversidade.inativa
        ? 'A universidade está inativa: os dados ficam disponíveis só para leitura.'
        : 'Disponível depois que o cadastro for aprovado. Corrija os dados da instituição e dos campi e reenvie o '
            'cadastro para análise.';
  }
}

class EnderecoCampus {
  EnderecoCampus({
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.complemento,
    this.cep,
  });

  factory EnderecoCampus.fromJson(Map<String, dynamic> json) => EnderecoCampus(
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

/// Campus no painel (`GET /universidades/:id/gestao/campus`).
class CampusGestao {
  CampusGestao({
    required this.id,
    required this.nome,
    required this.principal,
    required this.endereco,
    required this.totalOfertas,
    this.cnpj,
    this.telefoneCelular,
    this.telefoneFixo,
    this.emailCampus,
  });

  factory CampusGestao.fromJson(Map<String, dynamic> json) => CampusGestao(
        id: json['id'] as int,
        nome: json['nome'] as String,
        cnpj: json['cnpj'] as String?,
        telefoneCelular: json['telefoneCelular'] as String?,
        telefoneFixo: json['telefoneFixo'] as String?,
        emailCampus: json['emailCampus'] as String?,
        principal: json['principal'] as bool? ?? false,
        endereco: EnderecoCampus.fromJson(json['endereco'] as Map<String, dynamic>),
        totalOfertas: json['totalOfertas'] as int? ?? 0,
      );

  final int id;
  final String nome;
  final String? cnpj;
  final String? telefoneCelular;
  final String? telefoneFixo;
  final String? emailCampus;
  final bool principal;
  final EnderecoCampus endereco;
  final int totalOfertas;

  String get cidadeUf => '${endereco.cidade} / ${endereco.estado}';
  String? get telefone => telefoneFixo ?? telefoneCelular;
}

/// Oferta do curso em um campus, com turno e vagas.
class OfertaCurso {
  OfertaCurso({required this.cursoId, required this.campusId, required this.campusNome, this.turno, this.vagas});

  factory OfertaCurso.fromJson(Map<String, dynamic> json) => OfertaCurso(
        cursoId: json['cursoId'] as int,
        campusId: json['campusId'] as int,
        campusNome: json['campusNome'] as String? ?? '',
        turno: json['turno'] as String?,
        vagas: json['vagas'] as int?,
      );

  final int cursoId;
  final int campusId;
  final String campusNome;
  final String? turno;
  final int? vagas;

  String get resumo => [campusNome, if (turno != null) turno!, if (vagas != null) contagem(vagas!, 'vaga', 'vagas')].join(' · ');
}

/// Curso no painel (`GET /universidades/:id/gestao/cursos`).
class CursoGestao {
  CursoGestao({
    required this.id,
    required this.nome,
    required this.ofertas,
    this.areaCurso,
    this.notaMec,
    this.modalidade,
    this.grau,
    this.duracaoSemestres,
    this.descricao,
  });

  factory CursoGestao.fromJson(Map<String, dynamic> json) => CursoGestao(
        id: json['id'] as int,
        nome: json['nome'] as String,
        areaCurso: json['areaCurso'] as String?,
        notaMec: json['notaMec'] as String?,
        modalidade: json['modalidade'] as String?,
        grau: json['grau'] as String?,
        duracaoSemestres: json['duracaoSemestres'] as int?,
        descricao: json['descricao'] as String?,
        ofertas: [
          for (final oferta in json['ofertas'] as List<dynamic>? ?? const [])
            OfertaCurso.fromJson(oferta as Map<String, dynamic>),
        ],
      );

  final int id;
  final String nome;
  final String? areaCurso;
  final String? notaMec;
  final String? modalidade;
  final String? grau;
  final int? duracaoSemestres;
  final String? descricao;
  final List<OfertaCurso> ofertas;
}

/// Programa global com a marcação da universidade (`GET .../gestao/programas`).
class ProgramaAceito {
  ProgramaAceito({required this.id, required this.nome, required this.tipo, required this.aceito, this.sigla, this.observacao});

  factory ProgramaAceito.fromJson(Map<String, dynamic> json) => ProgramaAceito(
        id: json['id'] as int,
        nome: json['nome'] as String,
        sigla: json['sigla'] as String?,
        tipo: tipoProgramaDe(json['tipo'] as String),
        aceito: json['aceito'] as bool? ?? false,
        observacao: json['observacao'] as String?,
      );

  final int id;
  final String nome;
  final String? sigla;
  final TipoPrograma tipo;
  final bool aceito;
  final String? observacao;
}

/// Bolsa institucional (programa do tipo BOLSA da universidade, RF11).
class BolsaInstitucional {
  BolsaInstitucional({
    required this.id,
    required this.nome,
    required this.descricao,
    this.sigla,
    this.requisitos,
    this.comoFunciona,
    this.linkOficial,
  });

  factory BolsaInstitucional.fromJson(Map<String, dynamic> json) => BolsaInstitucional(
        id: json['id'] as int,
        nome: json['nome'] as String,
        sigla: json['sigla'] as String?,
        descricao: json['descricao'] as String,
        requisitos: json['requisitos'] as String?,
        comoFunciona: json['comoFunciona'] as String?,
        linkOficial: json['linkOficial'] as String?,
      );

  final int id;
  final String nome;
  final String? sigla;
  final String descricao;
  final String? requisitos;
  final String? comoFunciona;
  final String? linkOficial;
}

/// Card "Desempenho da página" (T23.1): visitas no período e média.
class EstatisticaUniversidade {
  EstatisticaUniversidade({required this.visitas, required this.totalAvaliacoes, this.mediaAvaliacao});

  factory EstatisticaUniversidade.fromJson(Map<String, dynamic> json) => EstatisticaUniversidade(
        visitas: json['visitas'] as int? ?? 0,
        mediaAvaliacao: (json['mediaAvaliacao'] as num?)?.toDouble(),
        totalAvaliacoes: json['totalAvaliacoes'] as int? ?? 0,
      );

  final int visitas;
  final double? mediaAvaliacao;
  final int totalAvaliacoes;
}
