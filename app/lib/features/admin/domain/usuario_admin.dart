import '../../auth/domain/usuario_sessao.dart';

String rotuloTipoUsuario(TipoUsuario tipo) => switch (tipo) {
      TipoUsuario.aluno => 'Aluno',
      TipoUsuario.universidade => 'Universidade',
      TipoUsuario.admin => 'Administrador',
    };

String codigoTipoUsuario(TipoUsuario tipo) => switch (tipo) {
      TipoUsuario.aluno => 'A',
      TipoUsuario.universidade => 'U',
      TipoUsuario.admin => 'D',
    };

/// Linha de gerenciar usuários (RF09, Quadro 14), de `GET /usuarios`.
class UsuarioAdmin {
  UsuarioAdmin({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    required this.ativo,
    required this.criadoEm,
  });

  factory UsuarioAdmin.fromJson(Map<String, dynamic> json) => UsuarioAdmin(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        tipoUsuario: tipoUsuarioDe(json['tipoUsuario'] as String),
        ativo: json['ativo'] as bool,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
      );

  final int id;
  final String nome;
  final String email;
  final TipoUsuario tipoUsuario;
  final bool ativo;
  final DateTime criadoEm;
}
