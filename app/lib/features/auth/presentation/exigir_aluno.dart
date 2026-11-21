import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/session_controller.dart';
import '../domain/usuario_sessao.dart';

/// Se as ações exclusivas do aluno (avaliar, salvar faculdade, salvar
/// pesquisa) aparecem: para o visitante sim (levam ao login) e para o aluno
/// sim; para universidade e administrador, que não podem executá-las, não.
bool mostrarAcoesDeAluno() {
  final usuario = sessionController.usuario;
  return usuario == null || usuario.tipoUsuario == TipoUsuario.aluno;
}

/// Guarda das ações exclusivas do aluno. Visitante vai para o login e volta
/// para [voltarPara] depois. Retorna true se pode seguir. Os botões já não
/// aparecem para os outros perfis (ver [mostrarAcoesDeAluno]).
bool exigirAluno(BuildContext context, {required String voltarPara}) {
  final usuario = sessionController.usuario;

  if (usuario == null) {
    context.go('/login', extra: {'redirect': voltarPara});
    return false;
  }

  return usuario.tipoUsuario == TipoUsuario.aluno;
}
