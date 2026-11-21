import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tabs.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/domain/universidade_admin.dart';
import '../../admin/presentation/widgets/formulario.dart';
import '../../auth/data/session_controller.dart';
import '../../sugestoes/presentation/sugestoes_recebidas_page.dart';
import '../data/painel_universidade_repository.dart';
import '../domain/painel_universidade.dart';
import 'secao_avaliacoes_conta.dart';
import 'secao_bolsas_institucionais.dart';
import 'secao_campi.dart';
import 'secao_cursos_universidade.dart';
import 'secao_dados_instituicao.dart';
import 'secao_programas_aceitos.dart';
import 'widgets/faixa_situacao.dart';
import '../../../shared/widgets/gj_aviso.dart';

/// Seções do painel da universidade (T23), uma URL por seção
/// (`/painel-universidade/<caminho>`), como no painel do administrador.
enum SecaoUniversidade {
  dados('dados', 'Dados da instituição', Symbols.domain),
  campus('campus', 'Campi', Symbols.location_city),
  cursos('cursos', 'Cursos', Symbols.menu_book),
  programas('programas', 'Programas aceitos', Symbols.school),
  bolsas('bolsas', 'Bolsas institucionais', Symbols.workspace_premium),
  sugestoes('sugestoes', 'Sugestões recebidas', Symbols.forum),
  avaliacoes('avaliacoes', 'Avaliações recebidas', Symbols.star),
  conta('conta', 'Conta', Symbols.manage_accounts);

  const SecaoUniversidade(this.caminho, this.rotulo, this.icone);

  final String caminho;
  final String rotulo;
  final IconData icone;

  /// Seção do segmento da URL; a inicial é Dados da instituição.
  static SecaoUniversidade doCaminho(String? caminho) =>
      values.firstWhere((secao) => secao.caminho == caminho, orElse: () => SecaoUniversidade.dados);
}

/// T23 Painel de Administração da Universidade (Figura 33): faixa de
/// situação do cadastro no topo, abas e o conteúdo da seção. A situação é
/// lida da API a cada abertura (a sessão guarda a do momento do login) e
/// decide o que fica editável: pendente e aprovada alteram tudo; reprovada
/// só os dados da instituição e os campi (e reenvia o cadastro); inativa só
/// lê. A API aplica as mesmas regras.
class PainelUniversidadePage extends StatefulWidget {
  const PainelUniversidadePage({super.key, this.secao = SecaoUniversidade.dados});

  final SecaoUniversidade secao;

  @override
  State<PainelUniversidadePage> createState() => _PainelUniversidadePageState();
}

class _PainelUniversidadePageState extends State<PainelUniversidadePage> {
  // Lido da sessão a cada uso: ao recarregar a página (F5), a rota monta
  // antes de a sessão ser restaurada do storage, e a universidade só chega
  // quando o bootstrap termina.
  int? get _universidadeId => sessionController.usuario?.universidade?.id;
  UniversidadeCadastro? _cadastro;
  ApiException? _erro;
  bool _reenviando = false;

  @override
  void initState() {
    super.initState();
    sessionController.addListener(_aoMudarSessao);
    _carregar();
  }

  @override
  void dispose() {
    sessionController.removeListener(_aoMudarSessao);
    super.dispose();
  }

  void _aoMudarSessao() {
    if (!mounted) return;
    if (_cadastro == null && _universidadeId != null) {
      _carregar();
    } else {
      setState(() {});
    }
  }

  Future<void> _carregar() async {
    final id = _universidadeId;
    if (id == null) return;
    setState(() => _erro = null);
    try {
      final cadastro = await adminRepository.cadastro(id);
      if (mounted) setState(() => _cadastro = cadastro);
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = erro);
    }
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      final cadastro = await painelUniversidadeRepository.reenviar(_cadastro!.id);
      if (!mounted) return;
      setState(() => _cadastro = cadastro);
      mensageiro.aviso('Cadastro reenviado para análise.');
    } on ApiException catch (erro) {
      if (mounted) mensageiro.aviso(mensagemDaApi(erro), tipo: GJAvisoTipo.erro);
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  Widget _conteudoDaSecao(UniversidadeCadastro cadastro) {
    final acesso = AcessoPainel(cadastro.status);
    final id = cadastro.id;
    return switch (widget.secao) {
      SecaoUniversidade.dados => SecaoDadosInstituicao(
          key: ValueKey('dados-${cadastro.status}'),
          cadastro: cadastro,
          acesso: acesso,
          onAlterado: (salvo) => setState(() => _cadastro = salvo),
        ),
      SecaoUniversidade.campus => SecaoCampi(universidadeId: id, acesso: acesso, onAlterado: _carregar),
      SecaoUniversidade.cursos => SecaoCursosUniversidade(universidadeId: id, acesso: acesso),
      SecaoUniversidade.programas => SecaoProgramasAceitos(universidadeId: id, acesso: acesso),
      SecaoUniversidade.bolsas => SecaoBolsasInstitucionais(universidadeId: id, acesso: acesso),
      SecaoUniversidade.sugestoes => const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabecalhoSecao(titulo: 'Sugestões recebidas', subtitulo: 'Sugestões que estudantes enviaram para a universidade.'),
            SugestoesRecebidasLista(),
          ],
        ),
      SecaoUniversidade.avaliacoes => SecaoAvaliacoesRecebidas(universidadeId: id),
      SecaoUniversidade.conta => const SecaoConta(),
    };
  }

  Widget _corpo() {
    if (_universidadeId == null && sessionController.carregando) return const GJSkeleton(height: GJSpace.s24);
    if (_universidadeId == null) {
      return const GJEmptyState(
        titulo: 'Universidade não encontrada',
        texto: 'Esta conta não está vinculada a uma universidade.',
        icone: Symbols.account_balance,
      );
    }
    final cadastro = _cadastro;
    if (cadastro == null) {
      if (_erro != null) {
        return GJEmptyState(
          titulo: 'Não foi possível carregar a situação do cadastro',
          texto: _erro!.message,
          icone: Symbols.wifi_off,
          acaoLabel: 'Tentar novamente',
          onAcao: _carregar,
        );
      }
      return const GJSkeleton(height: GJSpace.s24);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FaixaSituacao(cadastro: cadastro, onReenviar: _reenviar, reenviando: _reenviando),
        const SizedBox(height: GJSpace.s8),
        GJTabs(
          tabs: [for (final item in SecaoUniversidade.values) GJTabItem(label: item.rotulo, icon: item.icone)],
          selectedIndex: widget.secao.index,
          onChanged: (indice) => context.go('/painel-universidade/${SecaoUniversidade.values[indice].caminho}'),
        ),
        const SizedBox(height: GJSpace.s8),
        _conteudoDaSecao(cadastro),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      tituloPainel: 'Painel de Administração da Universidade',
      child: GJPageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_cadastro?.nomeFantasia ?? 'Painel da Universidade', style: GJTypography.h1()),
              const SizedBox(height: GJSpace.s6),
              _corpo(),
            ],
          ),
        ),
      ),
    );
  }
}
