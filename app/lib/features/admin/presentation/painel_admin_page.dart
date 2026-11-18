import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_tabs.dart';
import '../../sugestoes/presentation/sugestoes_recebidas_page.dart';
import '../domain/cadastros.dart';
import 'secao_cursos.dart';
import 'secao_dashboard.dart';
import 'secao_programas.dart';
import 'secao_universidades.dart';
import 'secao_usuarios.dart';

/// Seções do painel do administrador, na ordem das abas do protótipo
/// (T24.1 a T24.8).
enum SecaoAdmin {
  dashboard('dashboard', 'Dashboard', Symbols.dashboard),
  usuarios('usuarios', 'Usuários', Symbols.group),
  universidades('universidades', 'Universidades', Symbols.account_balance),
  cursos('cursos', 'Cursos', Symbols.menu_book),
  financiamento('financiamento', 'Financiamento', Symbols.account_balance_wallet),
  bolsas('bolsas', 'Bolsas de Estudo', Symbols.workspace_premium),
  programasEntrada('programas-entrada', 'Programas de Entrada', Symbols.school),
  sugestoes('sugestoes', 'Sugestões', Symbols.forum);

  const SecaoAdmin(this.caminho, this.rotulo, this.icone);

  final String caminho;
  final String rotulo;
  final IconData icone;

  /// Seção do segmento da URL (`/admin/<caminho>`); a inicial é o Dashboard.
  static SecaoAdmin doCaminho(String? caminho) =>
      values.firstWhere((secao) => secao.caminho == caminho, orElse: () => SecaoAdmin.dashboard);
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
    return switch (secao) {
      SecaoAdmin.dashboard => const SecaoDashboard(),
      SecaoAdmin.cursos => const SecaoCursos(),
      SecaoAdmin.financiamento => const SecaoProgramas(
          key: ValueKey('programas-financiamento'),
          tipo: TipoPrograma.financiamento,
          titulo: 'Financiamento',
          rotuloNovo: 'Novo financiamento',
        ),
      SecaoAdmin.bolsas => const SecaoProgramas(
          key: ValueKey('programas-bolsa'),
          tipo: TipoPrograma.bolsa,
          titulo: 'Bolsas de Estudo',
          rotuloNovo: 'Nova bolsa',
        ),
      SecaoAdmin.programasEntrada => const SecaoProgramas(
          key: ValueKey('programas-entrada'),
          tipo: TipoPrograma.entrada,
          titulo: 'Programas de Entrada',
          rotuloNovo: 'Novo programa',
        ),
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
                    GJTabItem(label: item.rotulo, icon: item.icone),
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
