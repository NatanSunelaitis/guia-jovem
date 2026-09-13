import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/gj_footer.dart';
import '../widgets/gj_header.dart';

enum PublicRota { inicio, programas, universidades, outra }

/// Layout das telas públicas (Home, pesquisa, detalhes): header fixo +
/// conteúdo + footer. Ainda sem sessão (Fase 1 do frontend não existe),
/// então o header é sempre a variante visitante.
class PublicLayout extends StatelessWidget {
  const PublicLayout({super.key, required this.child, this.rotaAtiva = PublicRota.outra});

  final Widget child;
  final PublicRota rotaAtiva;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GJHeader.visitante(
        navItems: [
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
        ],
        onEntrar: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login chega em uma próxima fase do app.')),
        ),
      ),
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
