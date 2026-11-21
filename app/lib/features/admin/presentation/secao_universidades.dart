import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/utils/formatar_data.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_data_table.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tabs.dart';
import '../data/admin_repository.dart';
import '../domain/universidade_admin.dart';
import 'widgets/confirmacao_dialogs.dart';
import 'widgets/formulario.dart';
import 'widgets/formulario_universidade.dart';
import '../../../shared/widgets/gj_aviso.dart';

/// T24.3 Universidades (RF23): abas por status (pendentes primeiro, com o
/// contador), busca por nome e acesso ao cadastro de cada uma.
class SecaoUniversidades extends StatefulWidget {
  const SecaoUniversidades({super.key});

  @override
  State<SecaoUniversidades> createState() => _SecaoUniversidadesState();
}

class _SecaoUniversidadesState extends State<SecaoUniversidades> {
  static const _filtros = <StatusUniversidade?>[
    StatusUniversidade.pendente,
    null,
    StatusUniversidade.aprovada,
    StatusUniversidade.reprovada,
    StatusUniversidade.inativa,
  ];

  int _aba = 0;
  String _busca = '';
  int _pagina = 1;
  Timer? _atrasoBusca;

  PaginaUniversidadesAdmin? _dados;
  bool _carregando = true;
  ApiException? _erro;

  /// Ignora respostas de buscas antigas (digitação rápida, troca de aba).
  int _requisicao = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _atrasoBusca?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    final requisicao = ++_requisicao;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dados = await adminRepository.universidades(status: _filtros[_aba], busca: _busca, page: _pagina);
      if (!mounted || requisicao != _requisicao) return;
      setState(() => _dados = dados);
    } on ApiException catch (erro) {
      if (mounted && requisicao == _requisicao) setState(() => _erro = erro);
    } finally {
      if (mounted && requisicao == _requisicao) setState(() => _carregando = false);
    }
  }

  void _trocarAba(int indice) {
    if (indice == _aba) return;
    setState(() {
      _aba = indice;
      _pagina = 1;
    });
    _carregar();
  }

  void _buscar(String texto) {
    _atrasoBusca?.cancel();
    _atrasoBusca = Timer(const Duration(milliseconds: 400), () {
      _busca = texto.trim();
      _pagina = 1;
      _carregar();
    });
  }

  List<GJTabItem> get _abas {
    final pendentes = _dados?.pendentes;
    return [
      GJTabItem(
        label: pendentes == null ? 'Pendentes de aprovação' : 'Pendentes de aprovação ($pendentes)',
        icon: Symbols.pending,
      ),
      const GJTabItem(label: 'Todas', icon: Symbols.list),
      const GJTabItem(label: 'Aprovadas', icon: Symbols.verified),
      const GJTabItem(label: 'Reprovadas', icon: Symbols.cancel),
      const GJTabItem(label: 'Inativas', icon: Symbols.visibility_off),
    ];
  }

  Widget _tabela() {
    if (_erro != null) {
      return GJEmptyState(
        titulo: 'Não foi possível carregar',
        texto: _erro!.message,
        icone: Symbols.wifi_off,
        acaoLabel: 'Tentar novamente',
        onAcao: _carregar,
      );
    }

    final resultado = _dados?.resultado;
    final itens = resultado?.data ?? const <UniversidadeAdminItem>[];

    return GJDataTable(
      buscaHint: 'Buscar por nome',
      onBuscaChanged: _buscar,
      colunas: const [
        GJDataColumn('Nome', flex: 3),
        GJDataColumn('Cidade / UF', flex: 2),
        GJDataColumn('Status', flex: 2),
        GJDataColumn('Enviado em', flex: 2),
        GJDataColumn('Ações', flex: 2),
      ],
      linhas: _carregando && resultado == null
          ? [
              for (var i = 0; i < 3; i++)
                [for (var c = 0; c < 5; c++) const GJSkeleton(height: GJSpace.s4)],
            ]
          : [
              for (final universidade in itens)
                [
                  Text(universidade.nomeFantasia, style: GJTypography.body(), overflow: TextOverflow.ellipsis),
                  Text(universidade.cidadeUf, style: GJTypography.bodySm()),
                  encolherSePreciso(badgeStatusUniversidade(universidade.status)),
                  Text(formatarData(universidade.criadoEm), style: GJTypography.bodySm()),
                  encolherSePreciso(GJButton(
                    label: 'Ver cadastro',
                    size: GJButtonSize.sm,
                    variant: universidade.status == StatusUniversidade.pendente
                        ? GJButtonVariant.primary
                        : GJButtonVariant.secondary,
                    onPressed: () => context.go('/admin/universidades/${universidade.id}'),
                  )),
                ],
            ],
      vazio: GJEmptyState(
        titulo: _aba == 0 && _busca.isEmpty ? 'Nenhum cadastro aguardando análise' : 'Nenhuma universidade encontrada',
        texto: _busca.isEmpty
            ? 'Quando uma universidade se cadastrar, você recebe uma notificação no sino.'
            : 'Revise o termo pesquisado ou troque o filtro de status.',
        icone: Symbols.account_balance,
      ),
      paginaAtual: resultado?.page ?? 1,
      totalPaginas: resultado?.totalPages ?? 1,
      onPaginaChanged: (pagina) {
        setState(() => _pagina = pagina);
        _carregar();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Universidades', style: GJTypography.h2()),
        const SizedBox(height: GJSpace.s4),
        GJTabs(tabs: _abas, selectedIndex: _aba, onChanged: _trocarAba),
        const SizedBox(height: GJSpace.s6),
        _tabela(),
      ],
    );
  }
}

/// Cadastro de uma universidade para a análise (T24.3), com as ações
/// conforme o status: pendente (aprovar, reprovar), reprovada (aprovar),
/// aprovada (inativar) e inativa (reativar). Aberta também pela
/// notificação "Nova universidade aguardando aprovação".
class CadastroUniversidadeAdmin extends StatefulWidget {
  const CadastroUniversidadeAdmin({super.key, required this.id});

  final int id;

  @override
  State<CadastroUniversidadeAdmin> createState() => _CadastroUniversidadeAdminState();
}

class _CadastroUniversidadeAdminState extends State<CadastroUniversidadeAdmin> {
  UniversidadeCadastro? _cadastro;
  ApiException? _erro;
  bool _carregando = true;
  bool _executando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final cadastro = await adminRepository.cadastro(widget.id);
      if (mounted) setState(() => _cadastro = cadastro);
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = erro);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _executar(Future<UniversidadeCadastro> Function() acao, String sucesso) async {
    final mensageiro = ScaffoldMessenger.of(context);
    setState(() => _executando = true);
    try {
      final atualizado = await acao();
      if (!mounted) return;
      setState(() => _cadastro = atualizado);
      mensageiro.aviso(sucesso);
    } on ApiException catch (erro) {
      if (!mounted) return;
      mensageiro.aviso(erro.message, tipo: GJAvisoTipo.erro);
      // Outro administrador pode ter decidido antes: mostra o status atual.
      if (erro.code == 'STATUS_INVALIDO') await _carregar();
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  Future<void> _aprovar(UniversidadeCadastro cadastro) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Aprovar cadastro',
      texto: '${cadastro.nomeFantasia} passa a aparecer na pesquisa pública e recebe o aviso por notificação e e-mail.',
      rotuloConfirmar: 'Aprovar',
    );
    if (!confirmou || !mounted) return;
    await _executar(
      () => adminRepository.aprovar(cadastro.id),
      'Universidade aprovada. A instituição foi avisada.',
    );
  }

  Future<void> _reprovar(UniversidadeCadastro cadastro) async {
    final motivo = await pedirMotivoReprovacao(context, nomeUniversidade: cadastro.nomeFantasia);
    if (motivo == null || !mounted) return;
    await _executar(
      () => adminRepository.reprovar(cadastro.id, motivo: motivo),
      'Cadastro reprovado. A instituição recebeu o motivo.',
    );
  }

  Future<void> _inativar(UniversidadeCadastro cadastro) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Inativar universidade',
      texto: '${cadastro.nomeFantasia} deixa de aparecer na pesquisa, nos destaques e na página de detalhes. '
          'A instituição recebe o aviso por notificação e e-mail.',
      rotuloConfirmar: 'Inativar',
      destrutiva: true,
    );
    if (!confirmou || !mounted) return;
    await _executar(
      () => adminRepository.inativar(cadastro.id),
      'Universidade inativada. A instituição foi avisada.',
    );
  }

  Future<void> _reativar(UniversidadeCadastro cadastro) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Reativar universidade',
      texto: '${cadastro.nomeFantasia} volta a aparecer no site e recebe o aviso por notificação e e-mail.',
      rotuloConfirmar: 'Reativar',
    );
    if (!confirmou || !mounted) return;
    await _executar(
      () => adminRepository.reativar(cadastro.id),
      'Universidade reativada. A instituição foi avisada.',
    );
  }

  Future<void> _editar(UniversidadeCadastro cadastro) async {
    final salvo = await abrirFormulario<UniversidadeCadastro>(
      context,
      titulo: 'Editar dados da universidade',
      formulario: FormularioUniversidade(cadastro: cadastro),
    );
    if (salvo == null) return;
    if (!mounted) return;
    setState(() => _cadastro = salvo);
    ScaffoldMessenger.of(context).aviso('Dados da universidade atualizados.');
  }

  List<Widget> _acoes(UniversidadeCadastro cadastro) {
    GJButton botao(String rotulo, VoidCallback acao, {GJButtonVariant variante = GJButtonVariant.primary}) =>
        GJButton(label: rotulo, variant: variante, onPressed: _executando ? null : acao);

    final editar = GJButton(
      label: 'Editar dados',
      icon: Symbols.edit,
      variant: GJButtonVariant.secondary,
      onPressed: _executando ? null : () => _editar(cadastro),
    );

    return [editar, ...switch (cadastro.status) {
      StatusUniversidade.pendente => [
          botao('Reprovar', () => _reprovar(cadastro), variante: GJButtonVariant.danger),
          botao('Aprovar', () => _aprovar(cadastro)),
        ],
      StatusUniversidade.reprovada => [botao('Aprovar', () => _aprovar(cadastro))],
      StatusUniversidade.aprovada => [
          botao('Inativar', () => _inativar(cadastro), variante: GJButtonVariant.danger),
        ],
      StatusUniversidade.inativa => [
          // Só volta para o site quem já foi aprovada um dia (a API recusa o resto).
          if (cadastro.aprovadoEm != null) botao('Reativar', () => _reativar(cadastro)),
        ],
    }];
  }

  Widget _dado(String rotulo, String? valor) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: GJTypography.caption()),
          const SizedBox(height: GJSpace.s1),
          SelectableText(valor == null || valor.isEmpty ? '-' : valor, style: GJTypography.body()),
        ],
      ),
    );
  }

  Widget _conteudo(UniversidadeCadastro cadastro) {
    final endereco = cadastro.campusPrincipalEndereco;
    return Container(
      padding: const EdgeInsets.all(GJSpace.s6),
      decoration: BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: GJRadius.borderLg,
        border: Border.all(color: GJColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: GJSpace.s3,
            runSpacing: GJSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(cadastro.nomeFantasia, style: GJTypography.h3()),
              badgeStatusUniversidade(cadastro.status),
            ],
          ),
          const SizedBox(height: GJSpace.s1),
          Text(
            cadastro.aprovadoEm == null
                ? 'Enviado em ${formatarData(cadastro.criadoEm)}'
                : 'Enviado em ${formatarData(cadastro.criadoEm)} · Aprovado em ${formatarData(cadastro.aprovadoEm!)}',
            style: GJTypography.bodySm(),
          ),
          if (cadastro.status == StatusUniversidade.reprovada && cadastro.motivoReprovacao != null) ...[
            const SizedBox(height: GJSpace.s4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GJSpace.s4),
              decoration: BoxDecoration(color: GJColors.errorContainer, borderRadius: GJRadius.borderMd),
              child: Text(
                'Motivo da reprovação: ${cadastro.motivoReprovacao}',
                style: GJTypography.body().copyWith(color: GJColors.errorOnContainer),
              ),
            ),
          ],
          const SizedBox(height: GJSpace.s6),
          Text('Dados da instituição', style: GJTypography.h4()),
          const SizedBox(height: GJSpace.s3),
          Wrap(
            spacing: GJSpace.s6,
            runSpacing: GJSpace.s4,
            children: [
              _dado('Razão social', cadastro.razaoSocial),
              _dado('CNPJ', formatarCnpj(cadastro.cnpj)),
              _dado('Natureza', rotuloNatureza(cadastro.natureza)),
              _dado('Telefone', cadastro.telefonePrincipal),
              _dado('Página oficial', cadastro.linkPagina),
              _dado('Simulados', cadastro.linkSimulados),
            ],
          ),
          const SizedBox(height: GJSpace.s6),
          Text('Campus principal', style: GJTypography.h4()),
          const SizedBox(height: GJSpace.s3),
          Wrap(
            spacing: GJSpace.s6,
            runSpacing: GJSpace.s4,
            children: [
              _dado('Nome', cadastro.campusPrincipalNome),
              _dado('Endereço', endereco?.completo),
              _dado('E-mail do campus', cadastro.campusPrincipalEmail),
              _dado('Campus enviados', '${cadastro.totalCampus}'),
            ],
          ),
          const SizedBox(height: GJSpace.s6),
          Text('Programas aceitos', style: GJTypography.h4()),
          const SizedBox(height: GJSpace.s3),
          Text(
            cadastro.programas.isEmpty ? 'Nenhum programa informado' : cadastro.programas.join(', '),
            style: GJTypography.body(),
          ),
          const SizedBox(height: GJSpace.s6),
          Text('Responsável', style: GJTypography.h4()),
          const SizedBox(height: GJSpace.s3),
          Wrap(
            spacing: GJSpace.s6,
            runSpacing: GJSpace.s4,
            children: [
              _dado('Nome', cadastro.responsavelNome ?? 'Conta excluída'),
              _dado('E-mail', cadastro.responsavelEmail),
            ],
          ),
          const SizedBox(height: GJSpace.s8),
          Wrap(
            spacing: GJSpace.s3,
            runSpacing: GJSpace.s3,
            alignment: WrapAlignment.end,
            children: _acoes(cadastro),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget corpo;
    if (_carregando && _cadastro == null) {
      corpo = const GJSkeleton(height: 320);
    } else if (_erro != null) {
      corpo = GJEmptyState(
        titulo: 'Não foi possível carregar o cadastro',
        texto: _erro!.message,
        icone: Symbols.wifi_off,
        acaoLabel: 'Tentar novamente',
        onAcao: _carregar,
      );
    } else {
      corpo = _conteudo(_cadastro!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/admin/universidades'),
          icon: const Icon(Symbols.arrow_back),
          label: const Text('Voltar para a lista'),
        ),
        const SizedBox(height: GJSpace.s4),
        corpo,
      ],
    );
  }
}
