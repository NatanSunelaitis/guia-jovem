import '../../../core/network/auth_api_client.dart';
import '../../../core/network/paginated_result.dart';
import '../../auth/domain/usuario_sessao.dart';
import '../domain/universidade_admin.dart';
import '../domain/usuario_admin.dart';

/// Página da lista de universidades do administrador, com o total de
/// pendentes para o contador da aba.
class PaginaUniversidadesAdmin {
  const PaginaUniversidadesAdmin({required this.resultado, required this.pendentes});

  final PaginatedResult<UniversidadeAdminItem> resultado;
  final int pendentes;
}

/// Ações do painel do administrador (T24): aprovação de universidades
/// (RF23) e gerenciar usuários (RF09, Quadro 14). Todas exigem sessão.
class AdminRepository {
  Future<PaginaUniversidadesAdmin> universidades({
    StatusUniversidade? status,
    String? busca,
    int page = 1,
    int? pageSize,
  }) async {
    final json = await authApiClient.get(
      '/universidades/administracao',
      query: {
        'page': page,
        if (pageSize != null) 'pageSize': pageSize,
        if (status != null) 'status': codigoStatusUniversidade(status),
        if (busca != null && busca.isNotEmpty) 'busca': busca,
      },
    );
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PaginaUniversidadesAdmin(
      resultado: PaginatedResult.fromJson(json, UniversidadeAdminItem.fromJson),
      pendentes: meta['pendentes'] as int? ?? 0,
    );
  }

  /// Também usado pela própria universidade, no painel dela.
  Future<UniversidadeCadastro> cadastro(int id) async {
    final json = await authApiClient.get('/universidades/$id/cadastro');
    return UniversidadeCadastro.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<UniversidadeCadastro> aprovar(int id) => _acao(id, 'aprovar');

  Future<UniversidadeCadastro> reprovar(int id, {required String motivo}) =>
      _acao(id, 'reprovar', body: {'motivo': motivo});

  Future<UniversidadeCadastro> inativar(int id) => _acao(id, 'inativar');

  Future<UniversidadeCadastro> reativar(int id) => _acao(id, 'reativar');

  Future<UniversidadeCadastro> _acao(int id, String acao, {Map<String, dynamic>? body}) async {
    final json = await authApiClient.post('/universidades/$id/$acao', body: body);
    return UniversidadeCadastro.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PaginatedResult<UsuarioAdmin>> usuarios({
    String? busca,
    TipoUsuario? tipo,
    bool? ativo,
    int page = 1,
  }) async {
    final json = await authApiClient.get(
      '/usuarios',
      query: {
        'page': page,
        if (busca != null && busca.isNotEmpty) 'busca': busca,
        if (tipo != null) 'tipoUsuario': codigoTipoUsuario(tipo),
        if (ativo != null) 'ativo': ativo.toString(),
      },
    );
    return PaginatedResult.fromJson(json, UsuarioAdmin.fromJson);
  }

  /// Edição dos dados institucionais pelo administrador (RF18). 409
  /// `CNPJ_EM_USO` quando o CNPJ é de outra universidade.
  Future<UniversidadeCadastro> atualizarUniversidade(int id, Map<String, dynamic> dados) async {
    final json = await authApiClient.patch('/universidades/$id', body: dados);
    return UniversidadeCadastro.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// "Novo usuário" (Quadro 14): só Aluno ou Administrador; a conta de
  /// universidade nasce pelo cadastro da universidade.
  Future<UsuarioAdmin> criarUsuario({
    required String nome,
    required String email,
    required String senha,
    required TipoUsuario tipo,
  }) async {
    final json = await authApiClient.post(
      '/usuarios',
      body: {'nome': nome, 'email': email, 'senha': senha, 'tipoUsuario': codigoTipoUsuario(tipo)},
    );
    return UsuarioAdmin.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Nome e perfil (A ou D). Tirar o perfil do último administrador ativo
  /// responde 409 `ULTIMO_ADMINISTRADOR`.
  Future<UsuarioAdmin> atualizarUsuario(int id, {required String nome, TipoUsuario? tipo}) async {
    final json = await authApiClient.patch(
      '/usuarios/$id',
      body: {'nome': nome, if (tipo != null) 'tipoUsuario': codigoTipoUsuario(tipo)},
    );
    return UsuarioAdmin.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Ativar ou inativar (Quadro 14). A API responde 409
  /// `ULTIMO_ADMINISTRADOR` para a única conta de administrador ativa.
  Future<UsuarioAdmin> alterarSituacao(int id, {required bool ativo}) async {
    final json = await authApiClient.patch('/usuarios/$id', body: {'ativo': ativo});
    return UsuarioAdmin.fromJson(json['data'] as Map<String, dynamic>);
  }
}

/// Instância compartilhada; mutável para os testes substituírem.
AdminRepository adminRepository = AdminRepository();
