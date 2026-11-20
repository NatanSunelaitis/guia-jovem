import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/data/estados_brasil.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../core/utils/link_launcher.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/utils/programa_estilo.dart';
import '../../../shared/widgets/gj_aligned_grid.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_card.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tag.dart';
import '../../auth/data/session_controller.dart';
import '../../auth/presentation/exigir_aluno.dart';
import '../../favoritos/data/favoritos_repository.dart';
import '../../programas/data/programas_repository.dart';
import '../../programas/domain/programa.dart';
import '../data/universidades_repository.dart';
import '../domain/universidade.dart';
import 'salvar_pesquisa_dialog.dart';

class PesquisaUniversidadesPage extends StatefulWidget {
  const PesquisaUniversidadesPage({super.key, this.filtrosIniciais});

  final Map<String, String>? filtrosIniciais;

  @override
  State<PesquisaUniversidadesPage> createState() => _PesquisaUniversidadesPageState();
}

class _PesquisaUniversidadesPageState extends State<PesquisaUniversidadesPage> {
  late FiltrosUniversidades _filtros;
  late Future<PaginatedResult<UniversidadeResumo>> _future;
  Future<List<ProgramaResumo>>? _futureProgramas;

  final _qController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _areaCursoController = TextEditingController();
  String? _natureza;
  String _sort = 'nome';
  int? _programaId;
  String? _programaNome;
  String? _estado;
  int? _cursoId;
  double _notaMinima = 0;
  bool _filtrosAvancadosAbertos = false;

  // Pesquisa salva aberta por `/universidades?pesquisaSalva=<id>` (perfil T19).
  String? _nomePesquisaSalva;
  String? _avisoPesquisaSalva;

  // Salvar/remover faculdade direto no card, sem refazer a pesquisa.
  final _salvasAlteradas = <int, bool>{};
  final _salvandoIds = <int>{};

  @override
  void initState() {
    super.initState();
    final iniciais = widget.filtrosIniciais ?? const {};
    final pesquisaSalvaId = int.tryParse(iniciais['pesquisaSalva'] ?? '');

    if (pesquisaSalvaId != null) {
      _filtros = const FiltrosUniversidades();
      _future = _abrirPesquisaSalva(pesquisaSalvaId);
    } else {
      _aplicarFiltros(iniciais);
      _buscar();
    }
  }

  /// Preenche os campos a partir de filtros em texto, no mesmo formato da
  /// query string de GET /universidades (rota, retorno do login, pesquisa salva).
  void _aplicarFiltros(Map<String, String> filtros) {
    _qController.text = filtros['q'] ?? '';
    _cidadeController.text = filtros['cidade'] ?? '';
    _areaCursoController.text = filtros['areaCurso'] ?? '';
    _natureza = filtros['natureza'];
    _estado = filtros['estado'];
    _programaId = int.tryParse(filtros['programaId'] ?? '');
    _cursoId = int.tryParse(filtros['cursoId'] ?? '');
    _notaMinima = (double.tryParse(filtros['notaMinima'] ?? '') ?? 0).clamp(0, 5).toDouble();
    _sort = const {'nome', 'media', 'avaliacoes'}.contains(filtros['sort']) ? filtros['sort']! : 'nome';
    _resolverNomePrograma();
  }

  /// O chip "Aceita X" precisa do nome do programa, que não vem nos filtros.
  void _resolverNomePrograma() {
    final programaId = _programaId;
    if (programaId == null) return;
    _futureProgramas ??= programasRepository.listar(const FiltrosProgramas()).then((r) => r.data);
    _futureProgramas!.then((programas) {
      final programa = programas.where((p) => p.id == programaId).firstOrNull;
      if (mounted && programa != null && _programaId == programaId) {
        setState(() => _programaNome = programa.sigla ?? programa.nome);
      }
    }).catchError((_) {});
  }

  Future<PaginatedResult<UniversidadeResumo>> _abrirPesquisaSalva(int id) async {
    if (!sessionController.autenticado) {
      _avisoPesquisaSalva = 'Entre na sua conta para abrir suas pesquisas salvas.';
    } else {
      try {
        final pesquisa = await favoritosRepository.obterPesquisa(id);
        if (mounted) {
          setState(() {
            _aplicarFiltros(pesquisa.filtrosComoTexto);
            _nomePesquisaSalva = pesquisa.nome;
          });
        }
      } on ApiException catch (erro) {
        if (mounted) setState(() => _avisoPesquisaSalva = erro.message);
      }
    }

    _filtros = _montarFiltros();
    return universidadesRepository.listar(_filtros);
  }

  @override
  void dispose() {
    _qController.dispose();
    _cidadeController.dispose();
    _areaCursoController.dispose();
    super.dispose();
  }

  FiltrosUniversidades _montarFiltros({int page = 1}) {
    return FiltrosUniversidades(
      q: _qController.text,
      cidade: _cidadeController.text,
      estado: _estado,
      natureza: _natureza,
      programaId: _programaId,
      cursoId: _cursoId,
      areaCurso: _areaCursoController.text,
      notaMinima: _notaMinima > 0 ? _notaMinima : null,
      sort: _sort,
      page: page,
    );
  }

  void _buscar({int page = 1}) {
    setState(() {
      _filtros = _montarFiltros(page: page);
      _salvasAlteradas.clear();
      _future = universidadesRepository.listar(_filtros);
    });
  }

  /// Filtros da última pesquisa feita, sem paginação: é o que se salva e o
  /// que volta na URL depois do login.
  Map<String, dynamic> get _parametrosDaPesquisa => _filtros.toQuery()..remove('page');

  String get _rotaAtual {
    final parametros = {for (final e in _parametrosDaPesquisa.entries) e.key: e.value.toString()};
    return Uri(path: '/universidades', queryParameters: parametros.isEmpty ? null : parametros).toString();
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _salvarPesquisa() async {
    if (!exigirAluno(context, voltarPara: _rotaAtual)) return;

    final salva = await mostrarDialogoSalvarPesquisa(context, parametros: _parametrosDaPesquisa);
    if (salva != null && mounted) _avisar('Pesquisa "${salva.nome}" salva.');
  }

  bool _estaSalva(UniversidadeResumo universidade) => _salvasAlteradas[universidade.id] ?? universidade.salva;

  Future<void> _alternarSalva(UniversidadeResumo universidade) async {
    if (_salvandoIds.contains(universidade.id) || !exigirAluno(context, voltarPara: _rotaAtual)) return;

    final salvar = !_estaSalva(universidade);
    setState(() => _salvandoIds.add(universidade.id));
    try {
      if (salvar) {
        await favoritosRepository.salvarUniversidade(universidade.id);
      } else {
        await favoritosRepository.removerUniversidade(universidade.id);
      }
      if (!mounted) return;
      setState(() => _salvasAlteradas[universidade.id] = salvar);
      _avisar(salvar ? 'Faculdade salva.' : 'Faculdade removida das salvas.');
    } on ApiException catch (erro) {
      if (mounted) _avisar(erro.message);
    } finally {
      if (mounted) setState(() => _salvandoIds.remove(universidade.id));
    }
  }

  void _limparTudo() {
    setState(() {
      _qController.clear();
      _cidadeController.clear();
      _areaCursoController.clear();
      _estado = null;
      _programaId = null;
      _programaNome = null;
      _notaMinima = 0;
    });
    _buscar();
  }

  Uri _urlRelatorio(String formato) {
    final query = _filtros.toQuery()..remove('page');
    query['formato'] = formato;
    return Uri.parse('${apiClient.baseUrl}/relatorios/pesquisa').replace(
      queryParameters: {for (final entrada in query.entries) entrada.key: entrada.value.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return PublicLayout(
      rotaAtiva: PublicRota.universidades,
      child: GJPageContainer(
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Escolha sua faculdade e a cidade para buscar as melhores vagas', style: GJTypography.h1()),
            if (_nomePesquisaSalva != null) ...[
              const SizedBox(height: GJSpace.s2),
              Text('Pesquisa salva: $_nomePesquisaSalva', style: GJTypography.h4().copyWith(color: GJColors.primary)),
            ],
            if (_avisoPesquisaSalva != null) ...[
              const SizedBox(height: GJSpace.s2),
              Text(_avisoPesquisaSalva!, style: GJTypography.label(color: GJColors.error)),
            ],
            const SizedBox(height: GJSpace.s6),
            _filtrosCard(isMobile),
            const SizedBox(height: GJSpace.s8),
            FutureBuilder<PaginatedResult<UniversidadeResumo>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return _grade(isMobile, List.generate(6, (_) => const GJSkeletonCard()));
                }

                if (snapshot.hasError) {
                  return GJEmptyState(
                    titulo: 'Não foi possível carregar',
                    texto: snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Tente novamente.',
                    icone: Symbols.wifi_off,
                    acaoLabel: 'Tentar novamente',
                    onAcao: () => _buscar(page: _filtros.page),
                  );
                }

                final resultado = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chipsEContagem(resultado.total, isMobile),
                    const SizedBox(height: GJSpace.s4),
                    if (resultado.data.isEmpty)
                      const GJEmptyState(
                        titulo: 'Nenhuma universidade encontrada',
                        texto: 'Tente remover alguns filtros ou pesquisar por outra cidade.',
                      )
                    else ...[
                      _grade(isMobile, [
                        for (final u in resultado.data)
                          _CardUniversidadeGrid(
                            universidade: u,
                            salva: _estaSalva(u),
                            salvando: _salvandoIds.contains(u.id),
                            onAlternarSalva: () => _alternarSalva(u),
                          ),
                      ]),
                      const SizedBox(height: GJSpace.s6),
                      if (resultado.totalPages > 1) _paginacao(resultado),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _contagemLabel(int total) => total == 1 ? '1 universidade encontrada' : '$total universidades encontradas';

  Widget _chipsEContagem(int total, bool isMobile) {
    final chips = <Widget>[
      if (_qController.text.isNotEmpty)
        GJTag(label: 'Nome: ${_qController.text}', tone: GJTagTone.entrada, onRemove: () {
          _qController.clear();
          _buscar();
        }),
      if (_cidadeController.text.isNotEmpty)
        GJTag(label: _cidadeController.text, tone: GJTagTone.entrada, onRemove: () {
          _cidadeController.clear();
          _buscar();
        }),
      if (_estado != null)
        GJTag(label: 'Estado: $_estado', tone: GJTagTone.entrada, onRemove: () {
          setState(() => _estado = null);
          _buscar();
        }),
      if (_programaNome != null)
        GJTag(label: 'Aceita $_programaNome', tone: GJTagTone.entrada, onRemove: () {
          setState(() {
            _programaId = null;
            _programaNome = null;
          });
          _buscar();
        }),
      if (_areaCursoController.text.isNotEmpty)
        GJTag(label: 'Área: ${_areaCursoController.text}', tone: GJTagTone.entrada, onRemove: () {
          _areaCursoController.clear();
          _buscar();
        }),
      if (_notaMinima > 0)
        GJTag(label: 'Nota mínima ${_formatarNota(_notaMinima)}', tone: GJTagTone.entrada, onRemove: () {
          setState(() => _notaMinima = 0);
          _buscar();
        }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s4),
            child: Wrap(
              spacing: GJSpace.s2,
              runSpacing: GJSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...chips,
                GestureDetector(
                  onTap: _limparTudo,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: GJSpace.s2),
                    child: Text('Limpar tudo', style: GJTypography.caption().copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        _controlesResultado(total, isMobile),
      ],
    );
  }

  Widget _controlesResultado(int total, bool isMobile) {
    final contagem = Text(_contagemLabel(total), style: GJTypography.h4());
    final controles = Wrap(
      spacing: GJSpace.s3,
      runSpacing: GJSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ordenarPor(),
        _botaoGerarRelatorio(),
        _botaoSalvarPesquisa(),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [contagem, const SizedBox(height: GJSpace.s3), controles],
      );
    }

    // Wrap (não Row) para nunca estourar: se a tela não tiver espaço para
    // contagem + controles lado a lado, eles descem para a linha de baixo
    // em vez de um RenderFlex overflow. width:infinity é necessário para o
    // Wrap ocupar a largura toda e o spaceBetween ter o que distribuir
    // (por padrão o Wrap encolhe para o conteúdo, sem espaço sobrando).
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: GJSpace.s3,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [contagem, controles],
      ),
    );
  }

  Widget _ordenarPor() {
    return DropdownButton<String>(
      value: _sort,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: 'nome', child: Text('Ordenar por nome')),
        DropdownMenuItem(value: 'media', child: Text('Ordenar por média')),
        DropdownMenuItem(value: 'avaliacoes', child: Text('Ordenar por avaliações')),
      ],
      onChanged: (valor) => setState(() {
        _sort = valor ?? 'nome';
        _buscar();
      }),
    );
  }

  Widget _botaoGerarRelatorio() {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 48),
      onSelected: (formato) => abrirLinkExterno(_urlRelatorio(formato).toString()),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'csv', child: Row(children: [Icon(Symbols.table_view, size: 20), SizedBox(width: GJSpace.s3), Text('Exportar CSV')])),
        PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Symbols.picture_as_pdf, size: 20), SizedBox(width: GJSpace.s3), Text('Exportar PDF')])),
      ],
      child: IgnorePointer(
        child: GJButton(label: 'Gerar relatório', icon: Symbols.description, variant: GJButtonVariant.secondary, onPressed: () {}),
      ),
    );
  }

  Widget _botaoSalvarPesquisa() {
    return GJButton(
      label: 'Salvar pesquisa',
      icon: Symbols.bookmark_add,
      variant: GJButtonVariant.ghost,
      onPressed: _salvarPesquisa,
    );
  }

  Widget _paginacao(PaginatedResult<UniversidadeResumo> resultado) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Symbols.chevron_left),
          onPressed: resultado.page > 1 ? () => _buscar(page: resultado.page - 1) : null,
        ),
        Text('Página ${resultado.page} de ${resultado.totalPages}', style: GJTypography.bodySm()),
        IconButton(
          icon: const Icon(Symbols.chevron_right),
          onPressed: resultado.page < resultado.totalPages ? () => _buscar(page: resultado.page + 1) : null,
        ),
      ],
    );
  }

  Widget _grade(bool isMobile, List<Widget> cards) {
    if (isMobile) {
      return Column(
        children: [for (final card in cards) Padding(padding: const EdgeInsets.only(bottom: GJSpace.s4), child: card)],
      );
    }
    // GJAlignedGrid (não Wrap): cards da mesma linha ficam com a mesma
    // altura (a maior delas), como o align-items:stretch padrão do CSS
    // Grid; linhas diferentes continuam livres para ter alturas diferentes.
    return GJAlignedGrid(itemWidth: 300, spacing: GJSpace.s4, runSpacing: GJSpace.s4, children: cards);
  }

  Widget _filtrosCard(bool isMobile) {
    final campos = [
      GJInput(label: 'Universidade', hint: 'Nome da universidade', controller: _qController, icon: Symbols.search),
      GJInput(label: 'Cidade', hint: 'Cidade', controller: _cidadeController, icon: Symbols.location_on),
    ];

    return Container(
      padding: const EdgeInsets.all(GJSpace.s6),
      decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          isMobile
              ? Column(children: [for (final campo in campos) Padding(padding: const EdgeInsets.only(bottom: GJSpace.s3), child: campo)])
              : Row(
                  children: [
                    for (final campo in campos)
                      Expanded(child: Padding(padding: const EdgeInsets.only(right: GJSpace.s4), child: campo)),
                  ],
                ),
          const SizedBox(height: GJSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Spacer só existe dentro de Row/Column (Flex); dentro de um
              // Wrap ele derruba a tela (ParentData incompatível). O botão
              // fica de fora do Wrap, como irmão dele nesta Row.
              Expanded(
                child: Wrap(
                  spacing: GJSpace.s2,
                  runSpacing: GJSpace.s3,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(label: const Text('Todas'), selected: _natureza == null, onSelected: (_) => setState(() { _natureza = null; _buscar(); })),
                    ChoiceChip(label: const Text('Públicas/Federais'), selected: _natureza == 'P', onSelected: (_) => setState(() { _natureza = 'P'; _buscar(); })),
                    ChoiceChip(label: const Text('Privadas'), selected: _natureza == 'V', onSelected: (_) => setState(() { _natureza = 'V'; _buscar(); })),
                    const SizedBox(width: GJSpace.s2),
                    _sliderNotaMinima(),
                  ],
                ),
              ),
              const SizedBox(width: GJSpace.s4),
              GJButton(label: 'Pesquisar', icon: Symbols.search, onPressed: () => _buscar()),
            ],
          ),
          const SizedBox(height: GJSpace.s2),
          GestureDetector(
            onTap: () => setState(() {
              _filtrosAvancadosAbertos = !_filtrosAvancadosAbertos;
              _futureProgramas ??= programasRepository.listar(const FiltrosProgramas()).then((r) => r.data);
            }),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Filtros avançados', style: GJTypography.label(color: GJColors.primary)),
                const SizedBox(width: GJSpace.s1),
                Icon(_filtrosAvancadosAbertos ? Symbols.expand_less : Symbols.tune, size: 20, color: GJColors.primary),
              ],
            ),
          ),
          if (_filtrosAvancadosAbertos) ...[
            const SizedBox(height: GJSpace.s4),
            _filtrosAvancados(isMobile),
          ],
        ],
      ),
    );
  }

  Widget _sliderNotaMinima() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Nota mínima', style: GJTypography.bodySm()),
        const SizedBox(width: GJSpace.s3),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: GJColors.primaryContainer,
            // border (não surfaceHighest, quase branco): o trilho precisa
            // ter contraste visível contra o fundo da barra de filtros.
            inactiveTrackColor: GJColors.border,
            thumbColor: GJColors.surfaceLowest,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: SizedBox(
            width: 140,
            child: Slider(
              value: _notaMinima,
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (valor) => setState(() => _notaMinima = valor),
              onChangeEnd: (_) => _buscar(),
            ),
          ),
        ),
        const SizedBox(width: GJSpace.s2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: GJSpace.s2, vertical: 2),
          decoration: BoxDecoration(color: GJColors.primaryFixed, borderRadius: BorderRadius.circular(999)),
          child: Text(
            _formatarNota(_notaMinima),
            style: GJTypography.label(color: GJColors.primary).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _filtrosAvancados(bool isMobile) {
    final campos = <Widget>[
      DropdownButtonFormField<String?>(
        value: _estado,
        decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
        items: [
          const DropdownMenuItem(value: null, child: Text('Qualquer estado')),
          for (final uf in estadosBrasil) DropdownMenuItem(value: uf, child: Text(uf)),
        ],
        onChanged: (valor) => setState(() {
          _estado = valor;
          _buscar();
        }),
      ),
      FutureBuilder<List<ProgramaResumo>>(
        future: _futureProgramas,
        builder: (context, snapshot) {
          final programas = snapshot.data ?? const <ProgramaResumo>[];
          return DropdownButtonFormField<int?>(
            value: _programaId,
            decoration: const InputDecoration(labelText: 'Programa aceito', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: null, child: Text('Qualquer programa')),
              for (final programa in programas)
                DropdownMenuItem(value: programa.id, child: Text(programa.sigla ?? programa.nome)),
            ],
            onChanged: (valor) => setState(() {
              _programaId = valor;
              _programaNome = programas.firstWhere((p) => p.id == valor, orElse: () => programas.first).sigla;
              _buscar();
            }),
          );
        },
      ),
      GJInput(
        label: 'Área do curso',
        hint: 'Ex.: Saúde, Negócios...',
        controller: _areaCursoController,
        onChanged: (_) => _buscar(),
      ),
    ];

    return isMobile
        ? Column(children: [for (final campo in campos) Padding(padding: const EdgeInsets.only(bottom: GJSpace.s3), child: campo)])
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final campo in campos)
                Expanded(child: Padding(padding: const EdgeInsets.only(right: GJSpace.s4), child: campo)),
            ],
          );
  }
}

String _formatarNota(double nota) => nota.toStringAsFixed(1).replaceAll('.', ',');

class _CardUniversidadeGrid extends StatelessWidget {
  const _CardUniversidadeGrid({
    required this.universidade,
    required this.salva,
    required this.salvando,
    required this.onAlternarSalva,
  });

  final UniversidadeResumo universidade;
  final bool salva;
  final bool salvando;
  final VoidCallback onAlternarSalva;

  @override
  Widget build(BuildContext context) {
    return GJCard.universidade(
      nomeFantasia: universidade.nomeFantasia,
      logoUrl: universidade.logoUrl,
      cidade: universidade.cidade,
      estado: universidade.estado,
      mediaAvaliacao: universidade.mediaAvaliacao,
      totalAvaliacoes: universidade.totalAvaliacoes,
      tags: [
        for (final programa in universidade.programas.take(3))
          GJTag(label: programa.sigla ?? programa.nome, tone: tonePrograma(programa.tipo)),
      ],
      acao: IconButton(
        tooltip: salva ? 'Remover das salvas' : 'Salvar faculdade',
        onPressed: salvando ? null : onAlternarSalva,
        icon: Icon(Symbols.bookmark, fill: salva ? 1 : 0, color: GJColors.primary),
      ),
      onTap: () => context.go('/universidades/${universidade.id}'),
    );
  }
}
