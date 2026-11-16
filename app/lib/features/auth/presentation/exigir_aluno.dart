import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/session_controller.dart';
import '../domain/usuario_sessao.dart';

/// Guarda para ações exclusivas do aluno (avaliar, salvar faculdade, salvar
/// pesquisa). Visitante vai para o login e volta para [voltarPara] depois;
/// Universidade e Administrador recebem um aviso. Retorna true se pode seguir.
bool exigirAluno(BuildContext context, {required String voltarPara}) {
  final usuario = sessionController.usuario;

  if (usuario == null) {
    context.go('/login', extra: {'redirect': voltarPara});
    return false;
  }

  if (usuario.tipoUsuario != TipoUsuario.aluno) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disponível apenas para contas de aluno.')),
    );
    return false;
  }

  return true;
}
