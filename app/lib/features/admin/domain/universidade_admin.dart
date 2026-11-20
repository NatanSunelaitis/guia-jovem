import '../../../shared/utils/mascaras.dart';

export '../../../shared/utils/mascaras.dart' show formatarCnpj;

/// Status de aprovação da universidade (RF23): P pendente, A aprovada,
/// R reprovada, I inativa.
enum StatusUniversidade { pendente, aprovada, reprovada, inativa }

StatusUniversidade statusUniversidadeDe(String codigo) => switch (codigo) {
      'A' => StatusUniversidade.aprovada,
      'R' => StatusUniversidade.reprovada,
      'I' => StatusUniversidade.inativa,
      _ => StatusUniversidade.pendente,
    };

String codigoStatusUniversidade(StatusUniversidade status) => switch (status) {
      StatusUniversidade.pendente => 'P',
      StatusUniversidade.aprovada => 'A',
      StatusUniversidade.reprovada => 'R',
      StatusUniversidade.inativa => 'I',
    };

String rotuloStatusUniversidade(StatusUniversidade status) => switch (status) {
      StatusUniversidade.pendente => 'Pendente',
      StatusUniversidade.aprovada => 'Aprovada',
      StatusUniversidade.reprovada => 'Reprovada',
      StatusUniversidade.inativa => 'Inativa',
    };

String rotuloNatureza(String codigo) => codigo == 'P' ? 'Pública' : 'Privada';


DateTime? _data(dynamic valor) => valor == null ? null : DateTime.parse(valor as String);

/// Linha da lista de universidades do administrador.
class UniversidadeAdminItem {
  UniversidadeAdminItem({
    required this.id,
    required this.nomeFantasia,
    required this.razaoSocial,
    required this.status,
    required this.criadoEm,
    this.cidade,
    this.estado,
  });

  factory UniversidadeAdminItem.fromJson(Map<String, dynamic> json) => UniversidadeAdminItem(
        id: json['id'] as int,
        nomeFantasia: json['nomeFantasia'] as String,
        razaoSocial: json['razaoSocial'] as String,
        status: statusUniversidadeDe(json['status'] as String),
        cidade: json['cidade'] as String?,
        estado: json['estado'] as String?,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );

  final int id;
  final String nomeFantasia;
  final String razaoSocial;
  final StatusUniversidade status;
  final String? cidade;
  final String? estado;
  final DateTime criadoEm;

  String get cidadeUf => cidade == null ? '-' : '$cidade / ${estado ?? ''}';
}

class EnderecoCadastro {
  EnderecoCadastro({
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.estado,
    this.cep,
    this.complemento,
  });

  factory EnderecoCadastro.fromJson(Map<String, dynamic> json) => EnderecoCadastro(
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
  /// Opcional no cadastro da universidade (passo 3).
  final String? cep;

  String get completo {
    final cep = this.cep;
    final cepFormatado = cep == null || cep.isEmpty ? null : formatarCep(cep);
    final comComplemento = complemento == null || complemento!.isEmpty ? '' : ', $complemento';
    return '$logradouro, $numero$comComplemento, $bairro, $cidade / $estado${cepFormatado == null ? '' : ', CEP $cepFormatado'}';
  }
}

/// Dados do cadastro (`GET /universidades/:id/cadastro`): análise do
/// administrador e situação vista pela própria universidade.
class UniversidadeCadastro {
  UniversidadeCadastro({
    required this.id,
    required this.nomeFantasia,
    required this.razaoSocial,
    required this.cnpj,
    required this.natureza,
    required this.status,
    required this.criadoEm,
    required this.totalCampus,
    required this.programas,
    this.telefonePrincipal,
    this.descricao,
    this.linkPagina,
    this.linkSimulados,
    this.motivoReprovacao,
    this.aprovadoEm,
    this.campusPrincipalNome,
    this.campusPrincipalEndereco,
    this.campusPrincipalEmail,
    this.responsavelNome,
    this.responsavelEmail,
  });

  factory UniversidadeCadastro.fromJson(Map<String, dynamic> json) {
    final campus = json['campusPrincipal'] as Map<String, dynamic>?;
    final responsavel = json['responsavel'] as Map<String, dynamic>?;
    return UniversidadeCadastro(
      id: json['id'] as int,
      nomeFantasia: json['nomeFantasia'] as String,
      razaoSocial: json['razaoSocial'] as String,
      cnpj: json['cnpj'] as String,
      natureza: json['natureza'] as String,
      status: statusUniversidadeDe(json['status'] as String),
      telefonePrincipal: json['telefonePrincipal'] as String?,
      descricao: json['descricao'] as String?,
      linkPagina: json['linkPagina'] as String?,
      linkSimulados: json['linkSimulados'] as String?,
      motivoReprovacao: json['motivoReprovacao'] as String?,
      aprovadoEm: _data(json['aprovadoEm']),
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      totalCampus: json['totalCampus'] as int? ?? 0,
      campusPrincipalNome: campus?['nome'] as String?,
      campusPrincipalEmail: campus?['emailCampus'] as String?,
      campusPrincipalEndereco: campus?['endereco'] == null
          ? null
          : EnderecoCadastro.fromJson(campus!['endereco'] as Map<String, dynamic>),
      programas: [
        for (final programa in json['programas'] as List<dynamic>? ?? const [])
          ((programa as Map<String, dynamic>)['sigla'] as String?) ?? programa['nome'] as String,
      ],
      responsavelNome: responsavel?['nome'] as String?,
      responsavelEmail: responsavel?['email'] as String?,
    );
  }

  final int id;
  final String nomeFantasia;
  final String razaoSocial;
  final String cnpj;
  final String natureza;
  final StatusUniversidade status;
  final String? telefonePrincipal;
  final String? descricao;
  final String? linkPagina;
  final String? linkSimulados;
  final String? motivoReprovacao;
  final DateTime? aprovadoEm;
  final DateTime criadoEm;
  final int totalCampus;
  final String? campusPrincipalNome;
  final EnderecoCadastro? campusPrincipalEndereco;
  final String? campusPrincipalEmail;

  /// Siglas (ou nomes) dos programas aceitos.
  final List<String> programas;
  final String? responsavelNome;
  final String? responsavelEmail;
}
