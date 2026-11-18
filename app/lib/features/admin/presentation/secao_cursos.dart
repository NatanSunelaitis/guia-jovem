import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(curso == null ? 'Curso criado.' : 'Curso atualizado.')));
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
      mensageiro.showSnackBar(const SnackBar(content: Text('Curso excluído.')));
      await _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      if (erro.code == 'CURSO_OFERTADO') {
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
        Text('Cursos', style: GJTypography.h2()),
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
        CampoTexto(rotulo: 'Nome', controller: _nome, erro: _erros['nome'], maxLength: 100),
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
