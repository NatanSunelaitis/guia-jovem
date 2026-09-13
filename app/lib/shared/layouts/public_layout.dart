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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              // IntrinsicHeight + Expanded no conteúdo: quando a página é mais
              // baixa que a viewport, o footer fica colado no fim em vez de
              // deixar uma faixa branca (fundo do Scaffold) abaixo dele.
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(child: child),
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
              ),
            ),
          );
        },
      ),
    );
  }
}
