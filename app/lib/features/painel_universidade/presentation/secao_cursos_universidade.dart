import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_data_table.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../admin/domain/cadastros.dart';
import '../../admin/presentation/secao_cursos.dart';
import '../../admin/presentation/widgets/confirmacao_dialogs.dart';
import '../../admin/presentation/widgets/formulario.dart';
import '../../perfil/presentation/widgets/secao_carregavel.dart';
import '../data/painel_universidade_repository.dart';
import '../domain/painel_universidade.dart';
import 'widgets/faixa_situacao.dart';
import '../../../shared/utils/plural.dart';

/// T23.2 Cursos (RF19, RF20): os cursos da universidade com as ofertas por
/// campus, turno e vagas. O formulário do curso é o mesmo do administrador
/// (com a universidade fixa); as ofertas abrem no painel lateral.
class SecaoCursosUniversidade extends StatefulWidget {
  const SecaoCursosUniversidade({super.key, required this.universidadeId, required this.acesso});

  final int universidadeId;
  final AcessoPainel acesso;

  @override
  State<SecaoCursosUniversidade> createState() => _SecaoCursosUniversidadeState();
}

class _SecaoCursosUniversidadeState extends State<SecaoCursosUniversidade> {
  late Future<List<CursoGestao>> _future = _buscar();

  Future<List<CursoGestao>> _buscar() => painelUniversidadeRepository.cursos(widget.universidadeId);

  void _recarregar() => setState(() {
        _future = _buscar();
      });

  CursoAdmin _paraFormulario(CursoGestao curso) => CursoAdmin(
        id: curso.id,
        nome: curso.nome,
        areaCurso: curso.areaCurso,
        notaMec: curso.notaMec,
        modalidade: curso.modalidade,
        grau: curso.grau,
        duracaoSemestres: curso.duracaoSemestres,
        descricao: curso.descricao,
        universidadeId: widget.universidadeId,
        universidadeNome: '',
        totalCampus: curso.ofertas.length,
      );

  Future<void> _abrirFormulario([CursoGestao? curso]) async {
    final salvo = await abrirFormulario<CursoAdmin>(
      context,
      titulo: curso == null ? 'Novo curso' : 'Editar curso',
      formulario: FormularioCurso(
        universidadeId: widget.universidadeId,
        curso: curso == null ? null : _paraFormulario(curso),
      ),
    );
    if (salvo == null) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(curso == null ? 'Curso criado. Agora cadastre as ofertas por campus.' : 'Curso atualizado.'),
    ));
    _recarregar();
  }

  Future<void> _abrirOfertas(CursoGestao curso) async {
    await abrirFormulario<void>(
      context,
      titulo: 'Ofertas de ${curso.nome}',
      formulario: GerenciarOfertas(universidadeId: widget.universidadeId, curso: curso),
    );
    if (mounted) _recarregar();
  }

  Future<void> _excluir(CursoGestao curso) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Excluir curso',
      texto: '${curso.nome} deixa de aparecer na página da universidade.',
      rotuloConfirmar: 'Excluir',
      destrutiva: true,
    );
    if (!confirmou) return;
    if (!mounted) return;
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await painelUniversidadeRepository.excluirCurso(curso.id);
      if (!mounted) return;
      mensageiro.showSnackBar(const SnackBar(content: Text('Curso excluído.')));
      _recarregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      await mostrarAcaoBloqueada(context, erro.message);
    }
  }

  Widget _tabela(List<CursoGestao> cursos) {
    final edita = widget.acesso.editaDominio;
    return GJDataTable(
      acaoPrimariaLabel: edita ? 'Novo curso' : null,
      onAcaoPrimaria: edita ? () => _abrirFormulario() : null,
      colunas: [
        const GJDataColumn('Nome', flex: 3),
        const GJDataColumn('Área', flex: 2),
        const GJDataColumn('Grau', flex: 2),
        const GJDataColumn('Modalidade', flex: 2),
        const GJDataColumn('Ofertas (campus, turno, vagas)', flex: 4),
        if (edita) const GJDataColumn('Ações', flex: 2),
      ],
      linhas: [
        for (final curso in cursos)
          [
            Text(curso.nome, style: GJTypography.body(), overflow: TextOverflow.ellipsis),
            Text(curso.areaCurso ?? '-', style: GJTypography.bodySm()),
            Text(curso.grau ?? '-', style: GJTypography.bodySm()),
            Text(curso.modalidade ?? '-', style: GJTypography.bodySm()),
            Text(
              curso.ofertas.isEmpty ? 'Sem ofertas' : curso.ofertas.map((o) => o.resumo).join('\n'),
              style: GJTypography.bodySm(),
            ),
            if (edita)
              Row(
                children: [
                  IconButton(
                    tooltip: 'Editar ${curso.nome}',
                    icon: const Icon(Symbols.edit),
                    onPressed: () => _abrirFormulario(curso),
                  ),
                  IconButton(
                    tooltip: 'Ofertas de ${curso.nome}',
                    icon: const Icon(Symbols.location_on),
                    onPressed: () => _abrirOfertas(curso),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final aviso = widget.acesso.avisoLeitura(cadastro: false);
    final edita = widget.acesso.editaDominio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CabecalhoSecao(titulo: 'Cursos', subtitulo: 'Cursos oferecidos e onde cada um é ofertado.'),
        if (aviso != null) AvisoSomenteLeitura(aviso),
        SecaoCarregavel<CursoGestao>(
          future: _future,
          onTentarNovamente: _recarregar,
          vazio: GJEmptyState(
            titulo: 'Nenhum curso cadastrado',
            texto: 'Cadastre os cursos oferecidos para que os estudantes encontrem sua instituição nas pesquisas.',
            icone: Symbols.menu_book,
            acaoLabel: edita ? 'Cadastrar primeiro curso' : null,
            onAcao: edita ? () => _abrirFormulario() : null,
          ),
          construir: _tabela,
        ),
      ],
    );
  }
}

/// Ofertas do curso por campus (RF20): lista com editar e remover, e o
/// formulário para ofertar em outro campus da universidade.
class GerenciarOfertas extends StatefulWidget {
  const GerenciarOfertas({super.key, required this.universidadeId, required this.curso});

  final int universidadeId;
  final CursoGestao curso;

  @override
  State<GerenciarOfertas> createState() => _GerenciarOfertasState();
}

class _GerenciarOfertasState extends State<GerenciarOfertas> {
  late List<OfertaCurso> _ofertas = widget.curso.ofertas;
  late final Future<List<CampusGestao>> _campi = painelUniversidadeRepository.campus(widget.universidadeId);
  final _vagas = TextEditingController();
  int? _campusId;
  String _turno = turnosOferta.first;

  /// Oferta em edição (troca turno e vagas; o campus não muda).
  OfertaCurso? _editando;
  String? _erro;
  bool _salvando = false;

  @override
  void dispose() {
    _vagas.dispose();
    super.dispose();
  }

  Future<void> _atualizarLista() async {
    final cursos = await painelUniversidadeRepository.cursos(widget.universidadeId);
    final curso = cursos.where((c) => c.id == widget.curso.id);
    if (mounted) setState(() => _ofertas = curso.isEmpty ? const [] : curso.first.ofertas);
  }

  void _editar(OfertaCurso oferta) {
    setState(() {
      _editando = oferta;
      _campusId = oferta.campusId;
      _turno = turnosOferta.contains(oferta.turno) ? oferta.turno! : turnosOferta.first;
      _vagas.text = oferta.vagas?.toString() ?? '';
      _erro = null;
    });
  }

  void _limpar() {
    setState(() {
      _editando = null;
      _campusId = null;
      _turno = turnosOferta.first;
      _vagas.clear();
      _erro = null;
    });
  }

  Future<void> _salvar() async {
    final textoVagas = _vagas.text.trim();
    final vagas = textoVagas.isEmpty ? null : int.tryParse(textoVagas);
    if (_campusId == null) {
      setState(() => _erro = 'Escolha o campus');
      return;
    }
    if (textoVagas.isNotEmpty && (vagas == null || vagas < 0)) {
      setState(() => _erro = 'Informe as vagas com um número');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      if (_editando == null) {
        await painelUniversidadeRepository.criarOferta(widget.curso.id, campusId: _campusId!, turno: _turno, vagas: vagas);
      } else {
        await painelUniversidadeRepository.atualizarOferta(widget.curso.id, _campusId!, turno: _turno, vagas: vagas);
      }
      await _atualizarLista();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editando == null ? 'Oferta cadastrada.' : 'Oferta atualizada.')),
      );
      _limpar();
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = mensagemDaApi(erro));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _remover(OfertaCurso oferta) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Remover oferta',
      texto: '${widget.curso.nome} deixa de ser ofertado em ${oferta.campusNome}.',
      rotuloConfirmar: 'Remover',
      destrutiva: true,
    );
    if (!confirmou) return;
    try {
      await painelUniversidadeRepository.excluirOferta(widget.curso.id, oferta.campusId);
      await _atualizarLista();
      if (_editando?.campusId == oferta.campusId) _limpar();
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = erro.message);
    }
  }

  Widget _formulario(List<CampusGestao> campi) {
    final ofertados = {for (final o in _ofertas) o.campusId};
    final disponiveis = [for (final c in campi) if (_editando != null ? c.id == _editando!.campusId : !ofertados.contains(c.id)) c];
    if (_editando == null && disponiveis.isEmpty) {
      return Text('O curso já é ofertado em todos os campi.', style: GJTypography.bodySm());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_editando == null ? 'Nova oferta' : 'Editar oferta', style: GJTypography.h4()),
        const SizedBox(height: GJSpace.s3),
        CampoSelecao<int>(
          key: const Key('oferta-campus'),
          rotulo: 'Campus',
          valor: _campusId,
          enabled: _editando == null,
          opcoes: {for (final c in disponiveis) c.id: c.nome},
          onChanged: (valor) => setState(() => _campusId = valor),
        ),
        CampoSelecao<String>(
          key: const Key('oferta-turno'),
          rotulo: 'Turno',
          valor: _turno,
          opcoes: {for (final t in turnosOferta) t: t},
          onChanged: (valor) => setState(() => _turno = valor ?? _turno),
        ),
        CampoTexto(rotulo: 'Vagas', controller: _vagas, keyboardType: TextInputType.number),
        if (_erro != null) ...[
          Text(_erro!, style: GJTypography.label(color: GJColors.error)),
          const SizedBox(height: GJSpace.s3),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_editando != null) TextButton(onPressed: _limpar, child: const Text('Cancelar edição')),
            const SizedBox(width: GJSpace.s3),
            GJButton(
              label: _editando == null ? 'Adicionar oferta' : 'Salvar oferta',
              loading: _salvando,
              onPressed: _salvando ? null : _salvar,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_ofertas.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s4),
            child: Text('Este curso ainda não é ofertado em nenhum campus.', style: GJTypography.bodySm()),
          ),
        for (final oferta in _ofertas)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Symbols.location_on),
            title: Text(oferta.campusNome),
            subtitle: Text([oferta.turno ?? 'Turno não informado', if (oferta.vagas != null) contagem(oferta.vagas!, 'vaga', 'vagas')].join(' · ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(tooltip: 'Editar oferta em ${oferta.campusNome}', icon: const Icon(Symbols.edit), onPressed: () => _editar(oferta)),
                IconButton(
                  tooltip: 'Remover oferta em ${oferta.campusNome}',
                  icon: const Icon(Symbols.delete),
                  onPressed: () => _remover(oferta),
                ),
              ],
            ),
          ),
        const Divider(height: GJSpace.s8),
        FutureBuilder<List<CampusGestao>>(
          future: _campi,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Não foi possível carregar os campi.', style: GJTypography.bodySm());
            if (!snapshot.hasData) return const GJSkeleton(height: GJSpace.s12);
            return _formulario(snapshot.data!);
          },
        ),
        const SizedBox(height: GJSpace.s6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        ),
      ],
    );
  }
}
