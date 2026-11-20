import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_data_table.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../data/cadastros_repository.dart';
import '../domain/cadastros.dart';
import 'widgets/confirmacao_dialogs.dart';
import 'widgets/formulario.dart';
import '../../../shared/widgets/gj_remote_or_asset_image.dart';

String rotuloTipoPrograma(TipoPrograma tipo) => switch (tipo) {
      TipoPrograma.entrada => 'Programa de Entrada',
      TipoPrograma.financiamento => 'Financiamento',
      TipoPrograma.bolsa => 'Bolsa de Estudo',
    };

/// T24.5 a T24.7: Financiamento, Bolsas de Estudo e Programas de Entrada.
/// Mesma estrutura para os três tipos (RF10, RF11, RF17); cada aba do painel
/// é este cadastro filtrado por [tipo], como no protótipo.
class SecaoProgramas extends StatefulWidget {
  const SecaoProgramas({super.key, required this.tipo, required this.titulo, required this.rotuloNovo});

  final TipoPrograma tipo;
  final String titulo;
  final String rotuloNovo;

  @override
  State<SecaoProgramas> createState() => _SecaoProgramasState();
}

class _SecaoProgramasState extends State<SecaoProgramas> {
  String _busca = '';
  int _pagina = 1;
  Timer? _atrasoBusca;
  List<ProgramaAdmin> _itens = const [];
  int _totalPaginas = 1;
  bool _carregando = true;
  ApiException? _erro;
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
      final resultado = await cadastrosRepository.programas(tipo: widget.tipo, busca: _busca, page: _pagina);
      if (!mounted || requisicao != _requisicao) return;
      setState(() {
        _itens = resultado.data;
        _totalPaginas = resultado.totalPages;
      });
    } on ApiException catch (erro) {
      if (mounted && requisicao == _requisicao) setState(() => _erro = erro);
    } finally {
      if (mounted && requisicao == _requisicao) setState(() => _carregando = false);
    }
  }

  void _buscar(String texto) {
    _atrasoBusca?.cancel();
    _atrasoBusca = Timer(const Duration(milliseconds: 400), () {
      _busca = texto.trim();
      _pagina = 1;
      _carregar();
    });
  }

  Future<void> _abrirFormulario([ProgramaAdmin? programa]) async {
    await abrirFormulario<ProgramaAdmin>(
      context,
      titulo: programa == null ? widget.rotuloNovo : 'Editar programa',
      formulario: FormularioPrograma(tipo: widget.tipo, programaId: programa?.id),
    );
    // As datas importantes são gravadas na hora, então recarrega mesmo sem salvar o programa.
    if (mounted) await _carregar();
  }

  Future<void> _excluir(ProgramaAdmin programa) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Excluir programa',
      texto: '${programa.sigla ?? programa.nome} deixa de aparecer no site, com as datas importantes.',
      rotuloConfirmar: 'Excluir',
      destrutiva: true,
    );
    if (!confirmou) return;
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await cadastrosRepository.excluirPrograma(programa.id);
      if (!mounted) return;
      mensageiro.showSnackBar(const SnackBar(content: Text('Programa excluído.')));
      await _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      if (erro.code == 'PROGRAMA_ACEITO') {
        await mostrarAcaoBloqueada(context, erro.message);
      } else {
        mensageiro.showSnackBar(SnackBar(content: Text(erro.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.titulo, style: GJTypography.h2()),
        const SizedBox(height: GJSpace.s4),
        if (_erro != null)
          GJEmptyState(
            titulo: 'Não foi possível carregar',
            texto: _erro!.message,
            icone: Symbols.wifi_off,
            acaoLabel: 'Tentar novamente',
            onAcao: _carregar,
          )
        else
          GJDataTable(
            buscaHint: 'Buscar por nome ou sigla',
            onBuscaChanged: _buscar,
            acaoPrimariaLabel: widget.rotuloNovo,
            onAcaoPrimaria: () => _abrirFormulario(),
            colunas: const [
              GJDataColumn('Sigla', flex: 2),
              GJDataColumn('Nome', flex: 4),
              GJDataColumn('Universidades', flex: 2),
              GJDataColumn('Datas importantes', flex: 2),
              GJDataColumn('Ações', flex: 2),
            ],
            linhas: _carregando && _itens.isEmpty
                ? [
                    for (var i = 0; i < 3; i++) [for (var c = 0; c < 5; c++) const GJSkeleton(height: GJSpace.s4)],
                  ]
                : [
                    for (final programa in _itens)
                      [
                        Text(programa.sigla ?? '-', style: GJTypography.label(color: GJColors.primary)),
                        Text(programa.nome, style: GJTypography.body(), overflow: TextOverflow.ellipsis),
                        Text('${programa.totalUniversidades}', style: GJTypography.bodySm()),
                        Text('${programa.eventos.length}', style: GJTypography.bodySm()),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Editar ${programa.nome}',
                              icon: const Icon(Symbols.edit),
                              onPressed: () => _abrirFormulario(programa),
                            ),
                            IconButton(
                              tooltip: 'Excluir ${programa.nome}',
                              icon: const Icon(Symbols.delete),
                              onPressed: () => _excluir(programa),
                            ),
                          ],
                        ),
                      ],
                  ],
            vazio: GJEmptyState(
              titulo: 'Nenhum programa encontrado',
              texto: _busca.isEmpty ? 'Cadastre o primeiro em "${widget.rotuloNovo}".' : 'Revise o termo pesquisado.',
              icone: Symbols.school,
            ),
            paginaAtual: _pagina,
            totalPaginas: _totalPaginas,
            onPaginaChanged: (pagina) {
              setState(() => _pagina = pagina);
              _carregar();
            },
          ),
      ],
    );
  }
}

/// Formulário do programa com os campos da página de detalhe (T08, RF25)
/// e, na edição, a gestão das datas importantes. Um programa novo recebe as
/// datas depois de salvo (elas precisam do id).
class FormularioPrograma extends StatefulWidget {
  const FormularioPrograma({super.key, required this.tipo, this.programaId});

  final TipoPrograma tipo;
  final int? programaId;

  @override
  State<FormularioPrograma> createState() => _FormularioProgramaState();
}

class _FormularioProgramaState extends State<FormularioPrograma> {
  final _nome = TextEditingController();
  final _sigla = TextEditingController();
  final _descricao = TextEditingController();
  final _requisitos = TextEditingController();
  final _comoFunciona = TextEditingController();
  final _linkOficial = TextEditingController();
  final _imagemUrl = TextEditingController();
  late TipoPrograma _tipo = widget.tipo;

  int? _id;
  List<EventoPrograma> _eventos = const [];

  /// Ilustração empacotada no app (`assets/...`): não aparece como endereço
  /// no campo, só como prévia, e continua valendo se o campo ficar vazio.
  String? _imagemInterna;
  bool _carregando = false;
  ApiException? _erroCarregar;
  Map<String, String> _erros = const {};
  String? _erroGeral;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _id = widget.programaId;
    if (_id != null) _carregar();
  }

  @override
  void dispose() {
    for (final c in [_nome, _sigla, _descricao, _requisitos, _comoFunciona, _linkOficial, _imagemUrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _preencher(ProgramaAdmin programa) {
    _nome.text = programa.nome;
    _sigla.text = programa.sigla ?? '';
    _descricao.text = programa.descricao;
    _requisitos.text = programa.requisitos ?? '';
    _comoFunciona.text = programa.comoFunciona ?? '';
    _linkOficial.text = programa.linkOficial ?? '';
    final imagem = programa.imagemUrl;
    _imagemInterna = imagem != null && imagem.startsWith('assets/') ? imagem : null;
    _imagemUrl.text = _imagemInterna != null ? '' : imagem ?? '';
    _tipo = programa.tipo;
    _eventos = programa.eventos;
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erroCarregar = null;
    });
    try {
      final programa = await cadastrosRepository.programa(_id!);
      if (mounted) setState(() => _preencher(programa));
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erroCarregar = erro);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    final erros = <String, String>{};
    if (_nome.text.trim().isEmpty) erros['nome'] = 'Informe o nome do programa';
    if (_descricao.text.trim().isEmpty) erros['descricao'] = 'Informe a descrição';
    setState(() {
      _erros = erros;
      _erroGeral = null;
    });
    if (erros.isNotEmpty) return;

    final dados = <String, dynamic>{
      'nome': _nome.text.trim(),
      'sigla': textoOuNulo(_sigla),
      'tipo': codigoTipoPrograma(_tipo),
      'descricao': _descricao.text.trim(),
      'requisitos': textoOuNulo(_requisitos),
      'comoFunciona': textoOuNulo(_comoFunciona),
      'linkOficial': textoOuNulo(_linkOficial),
      'imagemUrl': textoOuNulo(_imagemUrl) ?? _imagemInterna,
    };

    setState(() => _salvando = true);
    try {
      if (_id == null) {
        final criado = await cadastrosRepository.criarPrograma(dados);
        if (!mounted) return;
        // Fica aberto, já em edição, para cadastrar as datas importantes.
        setState(() {
          _id = criado.id;
          _preencher(criado);
          _salvando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Programa criado. Agora você pode cadastrar as datas importantes.')),
        );
        return;
      }
      final salvo = await cadastrosRepository.atualizarPrograma(_id!, dados);
      if (mounted) Navigator.of(context).pop(salvo);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erros = errosPorCampo(erro);
        _erroGeral = mensagemDaApi(erro);
        _salvando = false;
      });
    }
  }

  Future<void> _editarEvento([EventoPrograma? evento]) async {
    final salvo = await showDialog<EventoPrograma>(
      context: context,
      builder: (context) => _EventoDialog(programaId: _id!, evento: evento),
    );
    if (salvo == null || !mounted) return;
    setState(() {
      final lista = [for (final e in _eventos) if (e.id != salvo.id) e, salvo]
        ..sort((a, b) => a.dataInicio.compareTo(b.dataInicio));
      _eventos = lista;
    });
  }

  Future<void> _excluirEvento(EventoPrograma evento) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Excluir data importante',
      texto: '"${evento.titulo}" sai da página do programa.',
      rotuloConfirmar: 'Excluir',
      destrutiva: true,
    );
    if (!confirmou) return;
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await cadastrosRepository.excluirEvento(evento.id);
      if (mounted) setState(() => _eventos = [for (final e in _eventos) if (e.id != evento.id) e]);
    } on ApiException catch (erro) {
      mensageiro.showSnackBar(SnackBar(content: Text(erro.message)));
    }
  }

  Widget _datasImportantes() {
    return Container(
      padding: const EdgeInsets.all(GJSpace.s4),
      margin: const EdgeInsets.only(bottom: GJSpace.s4),
      decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Datas importantes', style: GJTypography.h4())),
              if (_id != null)
                GJButton(
                  label: 'Adicionar data',
                  icon: Symbols.add,
                  size: GJButtonSize.sm,
                  variant: GJButtonVariant.secondary,
                  onPressed: () => _editarEvento(),
                ),
            ],
          ),
          const SizedBox(height: GJSpace.s3),
          if (_id == null)
            Text('Salve o programa para cadastrar as datas importantes.', style: GJTypography.bodySm())
          else if (_eventos.isEmpty)
            Text('Nenhuma data cadastrada.', style: GJTypography.bodySm())
          else
            for (final (indice, evento) in _eventos.indexed)
              Container(
                padding: const EdgeInsets.symmetric(vertical: GJSpace.s3),
                decoration: BoxDecoration(
                  border: indice == 0 ? null : Border(top: BorderSide(color: GJColors.border.withOpacity(0.4))),
                ),
                child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(evento.titulo, style: GJTypography.body()),
                        Text(
                          evento.dataFim == null
                              ? dataBrasileira(evento.dataInicio)
                              : '${dataBrasileira(evento.dataInicio)} a ${dataBrasileira(evento.dataFim!)}',
                          style: GJTypography.caption(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar ${evento.titulo}',
                    icon: const Icon(Symbols.edit),
                    onPressed: () => _editarEvento(evento),
                  ),
                  IconButton(
                    tooltip: 'Excluir ${evento.titulo}',
                    icon: const Icon(Symbols.delete),
                    onPressed: () => _excluirEvento(evento),
                  ),
                ],
                ),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const GJSkeleton(height: 400);
    if (_erroCarregar != null) {
      return GJEmptyState(
        titulo: 'Não foi possível carregar o programa',
        texto: _erroCarregar!.message,
        icone: Symbols.wifi_off,
        acaoLabel: 'Tentar novamente',
        onAcao: _carregar,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(rotulo: 'Nome', controller: _nome, erro: _erros['nome'], maxLength: 100),
        CampoTexto(rotulo: 'Sigla', controller: _sigla, erro: _erros['sigla'], maxLength: 20),
        CampoSelecao<TipoPrograma>(
          rotulo: 'Tipo',
          valor: _tipo,
          opcoes: {for (final tipo in TipoPrograma.values) tipo: rotuloTipoPrograma(tipo)},
          onChanged: (valor) => setState(() => _tipo = valor ?? _tipo),
        ),
        CampoTextoLongo(
          rotulo: 'Descrição',
          controller: _descricao,
          erro: _erros['descricao'],
          campoKey: const Key('programa-descricao'),
        ),
        CampoTextoLongo(rotulo: 'Como funciona', controller: _comoFunciona, erro: _erros['comoFunciona']),
        CampoTextoLongo(rotulo: 'Requisitos', controller: _requisitos, erro: _erros['requisitos']),
        CampoTexto(rotulo: 'Link oficial', controller: _linkOficial, erro: _erros['linkOficial'], dica: 'https://'),
        if (_imagemInterna != null)
          Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s2),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: GJRadius.borderMd,
                  child: SizedBox(width: 64, height: 40, child: GJRemoteOrAssetImage(url: _imagemInterna!)),
                ),
                const SizedBox(width: GJSpace.s3),
                Expanded(
                  child: Text(
                    'Usando a ilustração padrão do programa. Para trocar, informe o endereço de outra imagem.',
                    style: GJTypography.bodySm(),
                  ),
                ),
              ],
            ),
          ),
        CampoTexto(rotulo: 'Imagem (endereço)', controller: _imagemUrl, erro: _erros['imagemUrl'], dica: 'https://'),
        _datasImportantes(),
        RodapeFormulario(
          salvando: _salvando,
          onSalvar: _salvar,
          erro: _erroGeral,
          rotuloSalvar: _id == null ? 'Criar programa' : 'Salvar',
        ),
      ],
    );
  }
}

/// Criar ou editar uma data importante: título, descrição, início e fim.
class _EventoDialog extends StatefulWidget {
  const _EventoDialog({required this.programaId, this.evento});

  final int programaId;
  final EventoPrograma? evento;

  @override
  State<_EventoDialog> createState() => _EventoDialogState();
}

class _EventoDialogState extends State<_EventoDialog> {
  late final _titulo = TextEditingController(text: widget.evento?.titulo);
  late final _descricao = TextEditingController(text: widget.evento?.descricao);
  late final _inicio = TextEditingController(
    text: widget.evento == null ? '' : dataBrasileira(widget.evento!.dataInicio),
  );
  late final _fim = TextEditingController(
    text: widget.evento?.dataFim == null ? '' : dataBrasileira(widget.evento!.dataFim!),
  );
  Map<String, String> _erros = const {};
  String? _erroGeral;
  bool _salvando = false;

  @override
  void dispose() {
    for (final c in [_titulo, _descricao, _inicio, _fim]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    final erros = <String, String>{};
    final inicio = dataIsoDe(_inicio.text);
    final fimTexto = _fim.text.trim();
    final fim = fimTexto.isEmpty ? null : dataIsoDe(fimTexto);
    if (_titulo.text.trim().isEmpty) erros['titulo'] = 'Informe o título';
    if (inicio == null) erros['dataInicio'] = 'Use dd/mm/aaaa';
    if (fimTexto.isNotEmpty && fim == null) erros['dataFim'] = 'Use dd/mm/aaaa';
    if (inicio != null && fim != null && fim.compareTo(inicio) < 0) {
      erros['dataFim'] = 'A data de fim deve ser igual ou posterior à de início';
    }
    setState(() {
      _erros = erros;
      _erroGeral = null;
    });
    if (erros.isNotEmpty) return;

    final dados = {'titulo': _titulo.text.trim(), 'descricao': textoOuNulo(_descricao), 'dataInicio': inicio, 'dataFim': fim};
    setState(() => _salvando = true);
    try {
      final salvo = widget.evento == null
          ? await cadastrosRepository.criarEvento(widget.programaId, dados)
          : await cadastrosRepository.atualizarEvento(widget.evento!.id, dados);
      if (mounted) Navigator.of(context).pop(salvo);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erros = errosPorCampo(erro);
        _erroGeral = mensagemDaApi(erro);
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderXl),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(GJSpace.s6),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.evento == null ? 'Nova data importante' : 'Editar data importante', style: GJTypography.h4()),
              const SizedBox(height: GJSpace.s4),
              CampoTexto(rotulo: 'Título', controller: _titulo, erro: _erros['titulo'], maxLength: 100),
              CampoTexto(rotulo: 'Descrição', controller: _descricao, erro: _erros['descricao'], maxLength: 255),
              CampoTexto(rotulo: 'Início', controller: _inicio, erro: _erros['dataInicio'], dica: 'dd/mm/aaaa'),
              CampoTexto(rotulo: 'Fim (opcional)', controller: _fim, erro: _erros['dataFim'], dica: 'dd/mm/aaaa'),
              RodapeFormulario(salvando: _salvando, onSalvar: _salvar, erro: _erroGeral),
            ],
          ),
        ),
      ),
    );
  }
}
