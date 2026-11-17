/// Perfis de usuário (seção 2 da especificação): Aluno, Universidade, aDmin.
enum TipoUsuario { aluno, universidade, admin }

TipoUsuario tipoUsuarioDe(String codigo) => switch (codigo) {
      'U' => TipoUsuario.universidade,
      'D' => TipoUsuario.admin,
      _ => TipoUsuario.aluno,
    };

class UniversidadeDoUsuario {
  UniversidadeDoUsuario({required this.id, required this.status});

  factory UniversidadeDoUsuario.fromJson(Map<String, dynamic> json) =>
      UniversidadeDoUsuario(id: json['id'] as int, status: json['status'] as String);

  final int id;

  /// P pendente | A aprovada | R reprovada | I inativa (seção 5.1).
  final String status;
}

/// Usuário autenticado, como retornado por login/register/refresh/me.
class UsuarioSessao {
  UsuarioSessao({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    this.fotoUrl,
    this.universidade,
  });

  factory UsuarioSessao.fromJson(Map<String, dynamic> json) => UsuarioSessao(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        tipoUsuario: tipoUsuarioDe(json['tipoUsuario'] as String),
        fotoUrl: json['fotoUrl'] as String?,
        universidade: json['universidade'] != null
            ? UniversidadeDoUsuario.fromJson(json['universidade'] as Map<String, dynamic>)
            : null,
      );

  final int id;
  final String nome;
  final String email;
  final TipoUsuario tipoUsuario;
  final String? fotoUrl;
  final UniversidadeDoUsuario? universidade;

  String get primeiroNome => nome.split(' ').first;

  UsuarioSessao copyWith({String? nome}) => UsuarioSessao(
        id: id,
        nome: nome ?? this.nome,
        email: email,
        tipoUsuario: tipoUsuario,
        fotoUrl: fotoUrl,
        universidade: universidade,
      );
}
