import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_tabs.dart';
import '../../sugestoes/presentation/sugestoes_recebidas_page.dart';
import 'secao_universidades.dart';
import 'secao_usuarios.dart';

/// Seções do painel do administrador, na ordem das abas do protótipo
/// (T24.1 a T24.8). [pronta] false: a aba aparece com o aviso "em breve".
enum SecaoAdmin {
  dashboard('dashboard', 'Dashboard', Symbols.dashboard, pronta: false),
  usuarios('usuarios', 'Usuários', Symbols.group),
  universidades('universidades', 'Universidades', Symbols.account_balance),
  cursos('cursos', 'Cursos', Symbols.menu_book, pronta: false),
  financiamento('financiamento', 'Financiamento', Symbols.account_balance_wallet, pronta: false),
  bolsas('bolsas', 'Bolsas de Estudo', Symbols.workspace_premium, pronta: false),
  programasEntrada('programas-entrada', 'Programas de Entrada', Symbols.school, pronta: false),
  sugestoes('sugestoes', 'Sugestões', Symbols.forum);

  const SecaoAdmin(this.caminho, this.rotulo, this.icone, {this.pronta = true});

  final String caminho;
  final String rotulo;
  final IconData icone;
  final bool pronta;

  /// Seção do segmento da URL (`/admin/<caminho>`); a inicial é Universidades.
  static SecaoAdmin doCaminho(String? caminho) =>
      values.firstWhere((secao) => secao.caminho == caminho, orElse: () => SecaoAdmin.universidades);
}

/// T24 Painel de Administração (Figura 34): header de painel, abas
/// horizontais e o conteúdo da seção. Cada seção tem a própria URL
/// (`/admin/usuarios`), e o cadastro de uma universidade abre em
/// `/admin/universidades/:id` (link da notificação de pendente).
class PainelAdminPage extends StatelessWidget {
  const PainelAdminPage({super.key, required this.secao, this.universidadeId});

  final SecaoAdmin secao;
  final int? universidadeId;

  Widget _conteudo() {
    if (!secao.pronta) {
      return GJEmptyState(
        titulo: 'Em breve',
        texto: 'A seção ${secao.rotulo} ainda está em construção.',
        icone: Symbols.construction,
      );
    }
    return switch (secao) {
      SecaoAdmin.universidades when universidadeId != null =>
        CadastroUniversidadeAdmin(key: ValueKey('cadastro-$universidadeId'), id: universidadeId!),
      SecaoAdmin.universidades => const SecaoUniversidades(),
      SecaoAdmin.usuarios => const SecaoUsuarios(),
      SecaoAdmin.sugestoes => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sugestões', style: GJTypography.h2()),
            const SizedBox(height: GJSpace.s2),
            Text('Sugestões que estudantes enviaram para a equipe Guia Jovem.', style: GJTypography.body()),
            const SizedBox(height: GJSpace.s4),
            const SugestoesRecebidasLista(),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      tituloPainel: 'Painel de Administração',
      child: GJPageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GJTabs(
                tabs: [
                  for (final item in SecaoAdmin.values)
                    GJTabItem(label: item.pronta ? item.rotulo : '${item.rotulo} (em breve)', icon: item.icone),
                ],
                selectedIndex: secao.index,
                onChanged: (indice) => context.go('/admin/${SecaoAdmin.values[indice].caminho}'),
              ),
              const SizedBox(height: GJSpace.s8),
              _conteudo(),
            ],
          ),
        ),
      ),
    );
  }
}
