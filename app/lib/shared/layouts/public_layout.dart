import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/auth/data/session_controller.dart';
import '../../features/auth/domain/usuario_sessao.dart';
import '../../features/auth/presentation/widgets/excluir_conta_dialog.dart';
import '../../features/notificacoes/presentation/notificacoes_bell.dart';
import '../widgets/gj_avatar_menu.dart';
import '../widgets/gj_footer.dart';
import '../widgets/gj_header.dart';

enum PublicRota { inicio, programas, universidades, outra }

/// Layout das telas públicas (Home, pesquisa, detalhes): header fixo +
/// conteúdo + footer. O header reage à sessão (visitante x logado, seção
/// 8, "Layout público").
class PublicLayout extends StatelessWidget {
  const PublicLayout({super.key, required this.child, this.rotaAtiva = PublicRota.outra, this.tituloPainel});

  final Widget child;
  final PublicRota rotaAtiva;

  /// Com título, o header logado vira a variante de painel (T23, T24):
  /// sem a navegação do site, com o nome do painel ao lado do logo.
  final String? tituloPainel;

  List<GJHeaderNavItem> _navItems(BuildContext context) => [
        GJHeaderNavItem(label: 'Início', ativo: rotaAtiva == PublicRota.inicio, onTap: () => context.go('/')),
        GJHeaderNavItem(
          label: 'Programas de Entrada',
          ativo: rotaAtiva == PublicRota.programas,
          onTap: () => context.go('/programas'),
        ),
        GJHeaderNavItem(
          label: 'Universidades',
          ativo: rotaAtiva == PublicRota.universidades,
          onTap: () => context.go('/universidades'),
        ),
      ];

  PreferredSizeWidget _header(BuildContext context) {
    final usuario = sessionController.usuario;

    if (usuario == null) {
      return GJHeader.visitante(
        navItems: _navItems(context),
        onEntrar: () => context.go('/login', extra: {'redirect': GoRouterState.of(context).uri.toString()}),
      );
    }

    // Key pelo usuário: trocar de conta recarrega as notificações.
    final sino = NotificacoesBell(key: ValueKey('sino-${usuario.id}'));
    final avatarMenu = GJAvatarMenu(
      iniciais: usuario.primeiroNome.isNotEmpty ? usuario.primeiroNome[0].toUpperCase() : '?',
      fotoUrl: usuario.fotoUrl,
      itens: [
        GJAvatarMenuItem(label: 'Visualizar Perfil', icon: Symbols.person, onTap: () => context.go('/perfil')),
        if (usuario.tipoUsuario == TipoUsuario.universidade)
          GJAvatarMenuItem(
            label: 'Painel Administrativo',
            icon: Symbols.dashboard,
            onTap: () => context.go('/painel-universidade'),
          ),
        if (usuario.tipoUsuario == TipoUsuario.admin)
          GJAvatarMenuItem(label: 'Painel Administrativo', icon: Symbols.dashboard, onTap: () => context.go('/admin')),
        GJAvatarMenuItem(label: 'Sair', icon: Symbols.logout, onTap: () => mostrarDialogoSair(context)),
        GJAvatarMenuItem(
          label: 'Excluir conta',
          icon: Symbols.delete,
          destructivo: true,
          dividerAcima: true,
          onTap: () => mostrarDialogoExcluirConta(
            context,
            aviso: usuario.tipoUsuario == TipoUsuario.universidade
                ? 'A universidade fica inativa e deixa de aparecer no site. Os dados da instituição são mantidos, mas esta conta é apagada.'
                : null,
          ),
        ),
      ],
    );

    if (tituloPainel != null) {
      return GJHeader.painel(tituloPainel: tituloPainel, notificationBell: sino, avatarMenu: avatarMenu);
    }
    return GJHeader.logado(navItems: _navItems(context), notificationBell: sino, avatarMenu: avatarMenu);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _ReactiveHeader(builder: _header),
      // Nem IntrinsicHeight nem SliverFillRemaining com Expanded no conteúdo
      // funcionam aqui: os dois pedem pro Column esticar o conteúdo dentro
      // de uma altura pré-calculada, e essa altura é calculada a partir da
      // altura intrínseca de um Wrap (grade de cards) — o cálculo intrínseco
      // de altura de um Wrap multi-linha é impreciso (bug conhecido do
      // Flutter), então o conteúdo de verdade acaba maior do que a fatia que
      // o Expanded reservou, e dá RenderFlex overflow (só aparece em telas
      // com Wrap alto o bastante para passar da viewport, ex.: T05 com 6
      // cards, não em T01-T03).
      //
      // Em vez de esticar o conteúdo, o ConstrainedBox de altura mínima
      // fica só no `child`: se ele for mais baixo que a viewport, o próprio
      // Flutter arredonda o tamanho relatado para cima (constraints.min),
      // sem precisar redesenhar nada, e o footer (irmão dele na Column,
      // fora do ConstrainedBox) é posicionado logo depois desse tamanho
      // já corrigido — ou seja, no fim da viewport. Sem Expanded/Intrinsic,
      // então não existe estouro possível.
      body: LayoutBuilder(
        // Precisa vir ANTES do SingleChildScrollView: dentro dele, a altura
        // que a viewport de rolagem repassa pro filho já é infinita (é uma
        // rolagem vertical), então não daria pra saber a altura real da tela.
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: child,
                ),
                GJFooter(
                  links: [
                    GJFooterLink(label: 'Sobre', onTap: () {}),
                    GJFooterLink(label: 'Contato', onTap: () {}),
                    GJFooterLink(label: 'Privacidade', onTap: () {}),
                    GJFooterLink(label: 'Termos', onTap: () {}),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Reconstrói o header quando a sessão muda (login/logout), sem precisar
/// que a página inteira vire StatefulWidget.
class _ReactiveHeader extends StatelessWidget implements PreferredSizeWidget {
  const _ReactiveHeader({required this.builder});

  final PreferredSizeWidget Function(BuildContext) builder;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: sessionController, builder: (context, _) => builder(context));
  }
}
