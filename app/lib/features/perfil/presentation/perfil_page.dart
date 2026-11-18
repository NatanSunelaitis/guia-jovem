import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'perfil_aluno_page.dart';

/// `/perfil`: o aluno vê T16. A universidade (T17) e o administrador são
/// levados pelo router à seção Conta do painel de cada um.
class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final aba = GoRouterState.of(context).uri.queryParameters['aba'];
    return PerfilAlunoPage(abaInicial: PerfilAlunoPage.abaDe(aba));
  }
}
