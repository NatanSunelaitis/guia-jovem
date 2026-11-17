import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_tabs.dart';
import '../../auth/data/session_controller.dart';
import 'widgets/dados_perfil_card.dart';
import 'widgets/faculdades_salvas_secao.dart';
import 'widgets/historico_sugestoes_secao.dart';
import 'widgets/minhas_avaliacoes_secao.dart';
import 'widgets/pesquisas_salvas_secao.dart';

/// T16 Perfil do Aluno (`/perfil`, Figuras 25 e 26): dados e ações da conta
/// no cartão e, nas abas, faculdades salvas, pesquisas salvas (T19), as
/// avaliações do aluno e o histórico de sugestões (T18).
class PerfilAlunoPage extends StatefulWidget {
  const PerfilAlunoPage({super.key});

  @override
  State<PerfilAlunoPage> createState() => _PerfilAlunoPageState();
}

class _PerfilAlunoPageState extends State<PerfilAlunoPage> {
  int _aba = 0;

  static const _abas = [
    // Rótulos curtos (como "Faculdades" no protótipo do T19): as abas cabem
    // lado a lado ao lado do cartão em 1440px, sem rolagem horizontal.
    GJTabItem(label: 'Faculdades', icon: Symbols.bookmark),
    GJTabItem(label: 'Pesquisas salvas', icon: Symbols.saved_search),
    GJTabItem(label: 'Avaliações', icon: Symbols.star),
    GJTabItem(label: 'Sugestões', icon: Symbols.history),
  ];

  // Só a aba aberta é montada: voltar a uma aba recarrega a lista, que pode
  // ter mudado em outra tela (ex.: faculdade salva no detalhe).
  Widget _conteudoDaAba() => switch (_aba) {
        0 => const FaculdadesSalvasSecao(),
        1 => const PesquisasSalvasSecao(),
        2 => const MinhasAvaliacoesSecao(),
        _ => const HistoricoSugestoesSecao(),
      };

  Widget _secoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GJTabs(tabs: _abas, selectedIndex: _aba, onChanged: (indice) => setState(() => _aba = indice)),
        const SizedBox(height: GJSpace.s6),
        KeyedSubtree(key: ValueKey('aba-$_aba'), child: _conteudoDaAba()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    return PublicLayout(
      child: GJPageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
          child: ListenableBuilder(
            // O cartão mostra o nome novo assim que "Editar perfil" salva.
            listenable: sessionController,
            builder: (context, _) {
              final usuario = sessionController.usuario;
              if (usuario == null) return const SizedBox.shrink();

              final cartao = DadosPerfilCard(key: ValueKey('perfil-${usuario.id}'), usuario: usuario);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meu perfil', style: GJTypography.h1()),
                  const SizedBox(height: GJSpace.s6),
                  if (isMobile) ...[
                    cartao,
                    const SizedBox(height: GJSpace.s8),
                    _secoes(),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 360, child: cartao),
                        const SizedBox(width: GJSpace.s8),
                        Expanded(child: _secoes()),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
