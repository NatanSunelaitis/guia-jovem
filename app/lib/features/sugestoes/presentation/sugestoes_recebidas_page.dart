import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tabs.dart';
import '../../auth/data/session_controller.dart';
import '../../auth/domain/usuario_sessao.dart';
import '../data/sugestoes_repository.dart';
import '../domain/sugestao.dart';
import 'widgets/sugestao_card.dart';

/// `/sugestoes-recebidas` (T23.6 e T24.8, RF15): sugestões destinadas à
/// equipe (administrador) ou à universidade da conta logada, com filtro por
/// status. Rota própria até os painéis existirem (Pendência 3).
class SugestoesRecebidasPage extends StatefulWidget {
  const SugestoesRecebidasPage({super.key});

  @override
  State<SugestoesRecebidasPage> createState() => _SugestoesRecebidasPageState();
}

class _SugestoesRecebidasPageState extends State<SugestoesRecebidasPage> {
  static const _filtros = <StatusSugestao?>[
    StatusSugestao.emAnalise,
    null,
    StatusSugestao.aprovada,
    StatusSugestao.reprovada,
  ];

  static const _abas = [
    GJTabItem(label: 'Em análise', icon: Symbols.hourglass_top),
    GJTabItem(label: 'Todas', icon: Symbols.list),
    GJTabItem(label: 'Aprovadas', icon: Symbols.check_circle),
    GJTabItem(label: 'Reprovadas', icon: Symbols.cancel),
  ];

  int _aba = 0;
  final List<Sugestao> _itens = [];
  int _pagina = 0;
  int _totalPaginas = 1;
  bool _carregando = true;
  bool _carregandoMais = false;
  ApiException? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool proximaPagina = false}) async {
    final filtro = _filtros[_aba];
    final pagina = proximaPagina ? _pagina + 1 : 1;
    setState(() {
      if (proximaPagina) {
        _carregandoMais = true;
      } else {
        _carregando = true;
        _erro = null;
      }
    });

    try {
      final resultado = await sugestoesRepository.recebidas(status: filtro, page: pagina);
      // Trocou de aba enquanto carregava: descarta esta resposta.
      if (!mounted || filtro != _filtros[_aba]) return;
      setState(() {
        if (!proximaPagina) _itens.clear();
        _itens.addAll(resultado.data);
        _pagina = resultado.page;
        _totalPaginas = resultado.totalPages;
      });
    } on ApiException catch (erro) {
      if (mounted && filtro == _filtros[_aba]) setState(() => _erro = erro);
    } finally {
      if (mounted && filtro == _filtros[_aba]) {
        setState(() {
          _carregando = false;
          _carregandoMais = false;
        });
      }
    }
  }

  void _trocarAba(int indice) {
    if (indice == _aba) return;
    setState(() => _aba = indice);
    _carregar();
  }

  Widget _lista() {
    if (_carregando) {
      return Column(
        children: [
          for (var i = 0; i < 3; i++)
            const Padding(padding: EdgeInsets.only(bottom: GJSpace.s3), child: GJSkeleton(height: GJSpace.s24)),
        ],
      );
    }

    if (_erro != null) {
      return GJEmptyState(
        titulo: 'Não foi possível carregar',
        texto: _erro!.message,
        icone: Symbols.wifi_off,
        acaoLabel: 'Tentar novamente',
        onAcao: _carregar,
      );
    }

    if (_itens.isEmpty) {
      return GJEmptyState(
        titulo: _aba == 0 ? 'Nenhuma sugestão aguardando avaliação' : 'Nenhuma sugestão por aqui',
        texto: 'Quando um estudante enviar uma sugestão, você recebe uma notificação no sino.',
        icone: Symbols.forum,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final sugestao in _itens)
          Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s3),
            child: SugestaoCard(
              sugestao: sugestao,
              mostrarAutor: true,
              onTap: () => context.go('/sugestoes/${sugestao.id}'),
              acao: GJButton(
                label: sugestao.status == StatusSugestao.emAnalise ? 'Avaliar' : 'Ver detalhes',
                variant: sugestao.status == StatusSugestao.emAnalise
                    ? GJButtonVariant.primary
                    : GJButtonVariant.secondary,
                size: GJButtonSize.sm,
                onPressed: () => context.go('/sugestoes/${sugestao.id}'),
              ),
            ),
          ),
        if (_pagina < _totalPaginas)
          Center(
            child: GJButton(
              label: 'Carregar mais',
              variant: GJButtonVariant.secondary,
              loading: _carregandoMais,
              onPressed: _carregandoMais ? null : () => _carregar(proximaPagina: true),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ehUniversidade = sessionController.usuario?.tipoUsuario == TipoUsuario.universidade;

    return PublicLayout(
      child: GJPageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sugestões recebidas', style: GJTypography.h1()),
              const SizedBox(height: GJSpace.s2),
              Text(
                ehUniversidade
                    ? 'Sugestões que estudantes enviaram para a sua universidade.'
                    : 'Sugestões que estudantes enviaram para a equipe Guia Jovem.',
                style: GJTypography.body(),
              ),
              const SizedBox(height: GJSpace.s6),
              GJTabs(tabs: _abas, selectedIndex: _aba, onChanged: _trocarAba),
              const SizedBox(height: GJSpace.s6),
              _lista(),
            ],
          ),
        ),
      ),
    );
  }
}
