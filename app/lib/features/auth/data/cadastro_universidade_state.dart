/// Estado em memória do cadastro de universidade em 3 passos (T13 a T15,
/// fluxo 7.3). Um singleton simples (não um ChangeNotifier): cada tela do
/// wizard lê os valores já preenchidos no `initState` (para "Voltar" não
/// perder o que já foi digitado) e grava de volta antes de navegar.
class CadastroUniversidadeState {
  bool aceitouTermos = false;

  // Passo 1 — dados institucionais (T13).
  String razaoSocial = '';
  String nomeFantasia = '';
  String cnpj = '';
  String natureza = 'P';
  String telefonePrincipal = '';
  String linkPagina = '';
  String linkSimulados = '';
  String email = '';
  String senha = '';

  // Passo 2 — programas aceitos (T14).
  Set<int> programasIds = {};

  // Passo 3 — primeiro campus (T15).
  String nomeCampus = '';
  String logradouro = '';
  String numero = '';
  String complemento = '';
  String bairro = '';
  String cidade = '';
  String estado = '';
  String cep = '';
  String telefoneCampus = '';

  void reiniciar() {
    aceitouTermos = false;
    razaoSocial = '';
    nomeFantasia = '';
    cnpj = '';
    natureza = 'P';
    telefonePrincipal = '';
    linkPagina = '';
    linkSimulados = '';
    email = '';
    senha = '';
    programasIds = {};
    nomeCampus = '';
    logradouro = '';
    numero = '';
    complemento = '';
    bairro = '';
    cidade = '';
    estado = '';
    cep = '';
    telefoneCampus = '';
  }

  static String _somenteDigitos(String valor) => valor.replaceAll(RegExp(r'\D'), '');

  static String? _semVazio(String valor) => valor.trim().isEmpty ? null : valor.trim();

  static String? _comEsquema(String valor) {
    final limpo = valor.trim();
    if (limpo.isEmpty) return null;
    return limpo.startsWith('http://') || limpo.startsWith('https://') ? limpo : 'https://$limpo';
  }

  Map<String, dynamic> paraCorpoDaRequisicao() {
    return {
      'aceitouTermos': aceitouTermos,
      'usuario': {'nome': nomeFantasia, 'email': email, 'senha': senha},
      'universidade': {
        'razaoSocial': razaoSocial,
        'nomeFantasia': nomeFantasia,
        'cnpj': cnpj.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase(),
        'natureza': natureza,
        if (_semVazio(telefonePrincipal) != null) 'telefonePrincipal': telefonePrincipal.trim(),
        if (_comEsquema(linkPagina) != null) 'linkPagina': _comEsquema(linkPagina),
        if (_comEsquema(linkSimulados) != null) 'linkSimulados': _comEsquema(linkSimulados),
      },
      'programasIds': programasIds.toList(),
      'campus': {
        'nome': nomeCampus,
        if (_semVazio(telefoneCampus) != null) 'telefoneFixo': telefoneCampus.trim(),
        'endereco': {
          'logradouro': logradouro,
          'numero': numero,
          if (_semVazio(complemento) != null) 'complemento': complemento.trim(),
          'bairro': bairro,
          'cidade': cidade,
          'estado': estado,
          if (_semVazio(cep) != null) 'cep': _somenteDigitos(cep),
        },
      },
    };
  }
}

final cadastroUniversidadeState = CadastroUniversidadeState();
