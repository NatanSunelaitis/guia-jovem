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
import '../data/cadastros_repository.dart';
import '../domain/cadastros.dart';
import 'widgets/confirmacao_dialogs.dart';
import 'formulario_curso.dart';
import 'widgets/formulario.dart';

export 'formulario_curso.dart';
import '../../../shared/widgets/gj_aviso.dart';

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

  Future<void> _abrirFormulario([CursoAdmin? curso, bool novaOferta = false]) async {
    final salvo = await abrirFormulario<CursoAdmin>(
      context,
      titulo: curso == null ? 'Novo curso' : 'Editar curso',
      formulario: FormularioCurso(curso: curso, novaOferta: novaOferta),
    );
    if (!mounted) return;
    if (salvo != null) avisarCursoSalvo(ScaffoldMessenger.of(context), salvo, criado: curso == null);
    // Recarrega mesmo sem "salvo": o curso pode ter sido gravado com alguma
    // oferta falhando e o formulário fechado depois.
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
              GJDataColumn('Ofertas', flex: 2),
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
                        if (curso.totalCampus == 0)
                          AvisoSemOferta(key: Key('sem-oferta-${curso.id}'), onAdicionar: () => _abrirFormulario(curso, true))
                        else
                          Text(curso.totalCampus == 1 ? '1 campus' : '${curso.totalCampus} campi', style: GJTypography.bodySm()),
                        Row(
                          children: [
                            AcaoTabela(
                              key: Key('acao-editar-${curso.id}'),
                              icone: Symbols.edit,
                              rotulo: 'Editar',
                              item: curso.nome,
                              onPressed: () => _abrirFormulario(curso),
                            ),
                            AcaoTabela(
                              key: Key('acao-ofertas-${curso.id}'),
                              icone: Symbols.location_on,
                              rotulo: 'Ofertas',
                              item: curso.nome,
                              onPressed: () => _abrirFormulario(curso),
                            ),
                            AcaoTabela(
                              key: Key('acao-excluir-${curso.id}'),
                              icone: Symbols.delete,
                              rotulo: 'Excluir',
                              item: curso.nome,
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
