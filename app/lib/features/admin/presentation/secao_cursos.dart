import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_data_table.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../data/admin_repository.dart';
import '../data/cadastros_repository.dart';
import '../domain/cadastros.dart';
import '../domain/universidade_admin.dart';
import 'widgets/confirmacao_dialogs.dart';
import 'widgets/formulario.dart';
import '../../../shared/widgets/gj_aviso.dart';

const _graus = ['Bacharelado', 'Licenciatura', 'Tecnólogo'];
const _modalidades = ['Presencial', 'EAD', 'Semipresencial'];

/// T24.4 Cursos (RF19): cursos de todas as universidades, com busca, criar,
/// editar e excluir. Cada curso é de uma universidade; excluir é bloqueado
/// pela API enquanto ele estiver ofertado em algum campus.
class SecaoCursos extends StatefulWidget {
  const SecaoCursos({super.key});

  @override
  State<SecaoCursos> createState() => _SecaoCursosState();
}

class _SecaoCursosState extends State<SecaoCursos> {
  String _busca = '';
  int _pagina = 1;
  Timer? _atrasoBusca;
  List<CursoAdmin> _itens = const [];
  int _totalPaginas = 1;
  bool _carregando = true;
  ApiException? _erro;
  int _requisicao = 0;

  /// Filtro "nomes parecidos": troca a tabela pelos grupos de grafias próximas.
  bool _parecidos = false;
  Future<List<GrupoNomesParecidos>>? _grupos;

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
      final resultado = await cadastrosRepository.cursos(busca: _busca, page: _pagina);
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

  Future<void> _abrirFormulario([CursoAdmin? curso]) async {
    final salvo = await abrirFormulario<CursoAdmin>(
      context,
      titulo: curso == null ? 'Novo curso' : 'Editar curso',
      formulario: FormularioCurso(curso: curso),
    );
    if (salvo == null) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).aviso(curso == null ? 'Curso criado.' : 'Curso atualizado.');
    if (_parecidos) setState(() => _grupos = cadastrosRepository.nomesParecidos());
    await _carregar();
  }

  Future<void> _excluir(CursoAdmin curso) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Excluir curso',
      texto: '${curso.nome} (${curso.universidadeNome}) deixa de aparecer no site.',
      rotuloConfirmar: 'Excluir',
      destrutiva: true,
    );
    if (!confirmou) return;
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await cadastrosRepository.excluirCurso(curso.id);
      if (!mounted) return;
      mensageiro.aviso('Curso excluído.');
      await _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      if (erro.code == 'CURSO_OFERTADO') {
        await mostrarAcaoBloqueada(context, erro.message);
      } else {
        mensageiro.aviso(erro.message, tipo: GJAvisoTipo.erro);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Cursos', style: GJTypography.h2()),
        const SizedBox(height: GJSpace.s4),
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            key: const Key('filtro-nomes-parecidos'),
            avatar: const Icon(Symbols.spellcheck, size: 18),
            label: const Text('Nomes parecidos'),
            tooltip: 'Agrupar cursos com grafias próximas para padronizar o nome',
            selected: _parecidos,
            onSelected: (marcado) => setState(() {
              _parecidos = marcado;
              if (marcado) _grupos = cadastrosRepository.nomesParecidos();
            }),
          ),
        ),
        const SizedBox(height: GJSpace.s4),
        if (_parecidos)
          _NomesParecidos(
            grupos: _grupos!,
            onEditar: _abrirFormulario,
            onTentarDeNovo: () => setState(() => _grupos = cadastrosRepository.nomesParecidos()),
          )
        else if (_erro != null)
          GJEmptyState(
            titulo: 'Não foi possível carregar',
            texto: _erro!.message,
            icone: Symbols.wifi_off,
            acaoLabel: 'Tentar novamente',
            onAcao: _carregar,
          )
        else
          GJDataTable(
            buscaHint: 'Buscar por nome',
            onBuscaChanged: _buscar,
            acaoPrimariaLabel: 'Novo curso',
            onAcaoPrimaria: () => _abrirFormulario(),
            colunas: const [
              GJDataColumn('Nome', flex: 3),
              GJDataColumn('Universidade', flex: 3),
              GJDataColumn('Área', flex: 2),
              GJDataColumn('Grau', flex: 2),
              GJDataColumn('Campus', flex: 1),
              GJDataColumn('Ações', flex: 2),
            ],
            linhas: _carregando && _itens.isEmpty
                ? [
                    for (var i = 0; i < 3; i++) [for (var c = 0; c < 6; c++) const GJSkeleton(height: GJSpace.s4)],
                  ]
                : [
                    for (final curso in _itens)
                      [
                        Text(curso.nome, style: GJTypography.body(), overflow: TextOverflow.ellipsis),
                        Text(curso.universidadeNome, style: GJTypography.bodySm(), overflow: TextOverflow.ellipsis),
                        Text(curso.areaCurso ?? '-', style: GJTypography.bodySm()),
                        Text(curso.grau ?? '-', style: GJTypography.bodySm()),
                        Text('${curso.totalCampus}', style: GJTypography.bodySm()),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Editar ${curso.nome}',
                              icon: const Icon(Symbols.edit),
                              onPressed: () => _abrirFormulario(curso),
                            ),
                            IconButton(
                              tooltip: 'Excluir ${curso.nome}',
                              icon: const Icon(Symbols.delete),
                              onPressed: () => _excluir(curso),
                            ),
                          ],
                        ),
                      ],
                  ],
            vazio: GJEmptyState(
              titulo: 'Nenhum curso encontrado',
              texto: _busca.isEmpty ? 'Cadastre o primeiro curso em "Novo curso".' : 'Revise o termo pesquisado.',
              icone: Symbols.menu_book,
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

/// Grupos de cursos com grafias próximas (abreviações e pequenas diferenças).
/// O administrador padroniza editando o nome de cada curso; o nome sugerido
/// é a grafia mais usada no grupo.
class _NomesParecidos extends StatelessWidget {
  const _NomesParecidos({required this.grupos, required this.onEditar, required this.onTentarDeNovo});

  final Future<List<GrupoNomesParecidos>> grupos;
  final ValueChanged<CursoAdmin> onEditar;
  final VoidCallback onTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GrupoNomesParecidos>>(
      future: grupos,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const GJSkeleton(height: 120);
        if (snapshot.hasError) {
          return GJEmptyState(
            titulo: 'Não foi possível carregar',
            texto: snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Tente novamente.',
            icone: Symbols.wifi_off,
            acaoLabel: 'Tentar novamente',
            onAcao: onTentarDeNovo,
          );
        }
        final lista = snapshot.data!;
        if (lista.isEmpty) {
          return const GJEmptyState(
            titulo: 'Nenhum nome parecido',
            texto: 'Os cursos de mesmo nome já estão escritos do mesmo jeito.',
            icone: Symbols.check_circle,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'O site já junta nomes que só diferem em maiúsculas, acentos e espaços, mas siglas, abreviações e erros de '
              'digitação viram cursos separados. Edite o nome para deixar todos na mesma grafia.',
              style: GJTypography.bodySm(),
            ),
            const SizedBox(height: GJSpace.s4),
            for (final grupo in lista)
              Container(
                key: Key('grupo-parecidos-${grupo.nomeSugerido}'),
                margin: const EdgeInsets.only(bottom: GJSpace.s4),
                padding: const EdgeInsets.all(GJSpace.s4),
                decoration: BoxDecoration(
                  color: GJColors.surfaceLowest,
                  borderRadius: GJRadius.borderLg,
                  border: Border.all(color: GJColors.surfaceHigh),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'Nome mais usado: ', style: GJTypography.bodySm()),
                          TextSpan(text: grupo.nomeSugerido, style: GJTypography.label(color: GJColors.textPrimary)),
                          TextSpan(text: '  ·  ${grupo.grafias} grafias', style: GJTypography.bodySm()),
                        ],
                      ),
                    ),
                    const SizedBox(height: GJSpace.s2),
                    for (final curso in grupo.cursos)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              curso.nome,
                              style: curso.nome == grupo.nomeSugerido
                                  ? GJTypography.body()
                                  : GJTypography.body().copyWith(color: GJColors.warning, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(flex: 3, child: Text(curso.universidadeNome, style: GJTypography.bodySm())),
                          IconButton(
                            tooltip: 'Editar ${curso.nome} (${curso.universidadeNome})',
                            icon: const Icon(Symbols.edit),
                            onPressed: () => onEditar(curso),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Campo "Nome" do cadastro de curso: enquanto a pessoa digita, sugere os
/// nomes que já existem no sistema, com quantas universidades usam cada um,
/// para os cursos iguais se juntarem na página pública. A sugestão é
/// opcional: qualquer nome pode ser salvo.
class CampoNomeCurso extends StatefulWidget {
  const CampoNomeCurso({super.key, required this.controller, this.erro});

  final TextEditingController controller;
  final String? erro;

  @override
  State<CampoNomeCurso> createState() => _CampoNomeCursoState();
}

class _CampoNomeCursoState extends State<CampoNomeCurso> {
  Timer? _atraso;
  late String _anterior = widget.controller.text;
  String? _escolhido;
  List<SugestaoNomeCurso> _sugestoes = const [];
  int _requisicao = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_aoDigitar);
  }

  @override
  void dispose() {
    _atraso?.cancel();
    widget.controller.removeListener(_aoDigitar);
    super.dispose();
  }

  void _aoDigitar() {
    final texto = widget.controller.text;
    if (texto == _anterior) return; // mudança só do cursor
    _anterior = texto;
    _atraso?.cancel();
    if (texto.trim().length < 2 || texto == _escolhido) {
      _requisicao++;
      if (_sugestoes.isNotEmpty) setState(() => _sugestoes = const []);
      return;
    }
    _atraso = Timer(const Duration(milliseconds: 300), () => _buscar(texto.trim()));
  }

  Future<void> _buscar(String texto) async {
    final requisicao = ++_requisicao;
    try {
      final sugestoes = await cadastrosRepository.sugestoesNomeCurso(texto);
      if (!mounted || requisicao != _requisicao) return;
      setState(() => _sugestoes = [for (final s in sugestoes) if (s.nome != widget.controller.text.trim()) s]);
    } on ApiException {
      // Sem sugestões o cadastro segue normalmente: o nome é digitado à mão.
      if (mounted && requisicao == _requisicao) setState(() => _sugestoes = const []);
    }
  }

  void _escolher(SugestaoNomeCurso sugestao) {
    _escolhido = sugestao.nome;
    widget.controller.value = TextEditingValue(
      text: sugestao.nome,
      selection: TextSelection.collapsed(offset: sugestao.nome.length),
    );
    setState(() => _sugestoes = const []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTexto(rotulo: 'Nome', controller: widget.controller, erro: widget.erro, maxLength: 100),
        if (_sugestoes.isNotEmpty)
          Container(
            key: const Key('sugestoes-nome-curso'),
            margin: const EdgeInsets.only(bottom: GJSpace.s4),
            decoration: BoxDecoration(
              color: GJColors.surfaceLowest,
              borderRadius: GJRadius.borderMd,
              border: Border.all(color: GJColors.surfaceHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(GJSpace.s3, GJSpace.s3, GJSpace.s3, GJSpace.s1),
                  child: Text('Nomes já usados no Guia Jovem (escolher é opcional)', style: GJTypography.caption()),
                ),
                for (final sugestao in _sugestoes)
                  InkWell(
                    key: Key('sugestao-nome-${sugestao.nome}'),
                    onTap: () => _escolher(sugestao),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: GJSpace.s3, vertical: GJSpace.s2),
                      child: Row(
                        children: [
                          const Icon(Symbols.menu_book, size: 18, color: GJColors.textSecondary),
                          const SizedBox(width: GJSpace.s2),
                          Expanded(child: Text(sugestao.nome, style: GJTypography.body())),
                          Text(
                            sugestao.totalUniversidades == 1 ? '1 universidade' : '${sugestao.totalUniversidades} universidades',
                            style: GJTypography.bodySm(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Criar ou editar curso. No novo, escolhe a universidade (que não muda
/// depois: as ofertas em campus dependem dela). No painel da universidade,
/// [universidadeId] fixa a universidade e o seletor não aparece.
class FormularioCurso extends StatefulWidget {
  const FormularioCurso({super.key, this.curso, this.universidadeId});

  final CursoAdmin? curso;
  final int? universidadeId;

  @override
  State<FormularioCurso> createState() => _FormularioCursoState();
}

class _FormularioCursoState extends State<FormularioCurso> {
  late final _nome = TextEditingController(text: widget.curso?.nome);
  late final _area = TextEditingController(text: widget.curso?.areaCurso);
  late final _notaMec = TextEditingController(text: widget.curso?.notaMec);
  late final _duracao = TextEditingController(text: widget.curso?.duracaoSemestres?.toString());
  late final _descricao = TextEditingController(text: widget.curso?.descricao);
  late String? _grau = widget.curso?.grau;
  late String? _modalidade = widget.curso?.modalidade;
  late int? _universidadeId = widget.universidadeId;

  Future<List<UniversidadeAdminItem>>? _universidades;
  Map<String, String> _erros = const {};
  String? _erroGeral;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.curso == null && widget.universidadeId == null) {
      _universidades = adminRepository.universidades(pageSize: 100).then((pagina) => pagina.resultado.data);
    }
  }

  @override
  void dispose() {
    for (final c in [_nome, _area, _notaMec, _duracao, _descricao]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> _validar() {
    final erros = <String, String>{};
    if (_nome.text.trim().isEmpty) erros['nome'] = 'Informe o nome do curso';
    if (widget.curso == null && _universidadeId == null) erros['universidadeId'] = 'Escolha a universidade';
    final duracao = _duracao.text.trim();
    if (duracao.isNotEmpty) {
      final valor = int.tryParse(duracao);
      if (valor == null || valor < 1 || valor > 20) erros['duracaoSemestres'] = 'Use um número de 1 a 20';
    }
    return erros;
  }

  Future<void> _salvar() async {
    final erros = _validar();
    setState(() {
      _erros = erros;
      _erroGeral = null;
    });
    if (erros.isNotEmpty) return;

    final duracao = _duracao.text.trim();
    final dados = <String, dynamic>{
      'nome': _nome.text.trim(),
      'areaCurso': textoOuNulo(_area),
      'notaMec': textoOuNulo(_notaMec),
      'grau': _grau,
      'modalidade': _modalidade,
      'duracaoSemestres': duracao.isEmpty ? null : int.parse(duracao),
      'descricao': textoOuNulo(_descricao),
    };

    setState(() => _salvando = true);
    try {
      final salvo = widget.curso == null
          ? await cadastrosRepository.criarCurso(_universidadeId!, dados)
          : await cadastrosRepository.atualizarCurso(widget.curso!.id, dados);
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

  Widget _seletorUniversidade() {
    return FutureBuilder<List<UniversidadeAdminItem>>(
      future: _universidades,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s4),
            child: Text('Não foi possível carregar as universidades.', style: GJTypography.bodySm()),
          );
        }
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.only(bottom: GJSpace.s4), child: GJSkeleton(height: 48));
        return CampoSelecao<int>(
          key: const Key('curso-universidade'),
          rotulo: 'Universidade',
          valor: _universidadeId,
          erro: _erros['universidadeId'],
          opcoes: {
            for (final u in snapshot.data!) u.id: '${u.nomeFantasia} (${rotuloStatusUniversidade(u.status)})',
          },
          onChanged: (valor) => setState(() => _universidadeId = valor),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final curso = widget.curso;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (curso == null && widget.universidadeId == null)
          _seletorUniversidade()
        else if (curso != null && widget.universidadeId == null)
          Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s4),
            child: Text('Universidade: ${curso.universidadeNome}', style: GJTypography.bodySm()),
          ),
        CampoNomeCurso(controller: _nome, erro: _erros['nome']),
        CampoTexto(rotulo: 'Área', controller: _area, erro: _erros['areaCurso'], dica: 'Ex.: Tecnologia', maxLength: 100),
        CampoSelecao<String>(
          rotulo: 'Grau',
          valor: _graus.contains(_grau) || _grau == null ? _grau : null,
          opcoes: {null: 'Não informado', for (final g in _graus) g: g},
          onChanged: (valor) => setState(() => _grau = valor),
        ),
        CampoSelecao<String>(
          rotulo: 'Modalidade',
          valor: _modalidades.contains(_modalidade) || _modalidade == null ? _modalidade : null,
          opcoes: {null: 'Não informada', for (final m in _modalidades) m: m},
          onChanged: (valor) => setState(() => _modalidade = valor),
        ),
        CampoTexto(
          rotulo: 'Duração (semestres)',
          controller: _duracao,
          erro: _erros['duracaoSemestres'],
          keyboardType: TextInputType.number,
        ),
        CampoTexto(rotulo: 'Nota do MEC', controller: _notaMec, erro: _erros['notaMec'], maxLength: 100),
        CampoTextoLongo(rotulo: 'Descrição', controller: _descricao, erro: _erros['descricao']),
        RodapeFormulario(salvando: _salvando, onSalvar: _salvar, erro: _erroGeral),
      ],
    );
  }
}
