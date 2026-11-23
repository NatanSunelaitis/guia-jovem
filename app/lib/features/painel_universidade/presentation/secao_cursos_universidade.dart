import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_data_table.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../admin/domain/cadastros.dart';
import '../../admin/presentation/secao_cursos.dart';
import '../../admin/presentation/widgets/confirmacao_dialogs.dart';
import '../../admin/presentation/widgets/formulario.dart';
import '../../perfil/presentation/widgets/secao_carregavel.dart';
import '../data/painel_universidade_repository.dart';
import '../domain/painel_universidade.dart';
import 'widgets/faixa_situacao.dart';
import '../../../shared/widgets/gj_aviso.dart';

/// T23.2 Cursos (RF19, RF20): os cursos da universidade com as ofertas por
/// campus, turno e vagas. O formulário do curso é o mesmo do administrador
/// (com a universidade fixa) e já traz as ofertas: "Ofertas" e "Adicionar
/// oferta" abrem o mesmo formulário.
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

  Future<void> _abrirFormulario([CursoGestao? curso, bool novaOferta = false]) async {
    final salvo = await abrirFormulario<CursoAdmin>(
      context,
      titulo: curso == null ? 'Novo curso' : 'Editar curso',
      formulario: FormularioCurso(
        universidadeId: widget.universidadeId,
        curso: curso == null ? null : _paraFormulario(curso),
        novaOferta: novaOferta,
      ),
    );
    if (!mounted) return;
    if (salvo != null) avisarCursoSalvo(ScaffoldMessenger.of(context), salvo, criado: curso == null);
    // Recarrega mesmo sem "salvo": o curso pode ter sido gravado com alguma
    // oferta falhando e o formulário fechado depois.
    _recarregar();
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
      mensageiro.aviso('Curso excluído.');
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
            if (curso.ofertas.isEmpty)
              AvisoSemOferta(
                key: Key('sem-oferta-${curso.id}'),
                onAdicionar: edita ? () => _abrirFormulario(curso, true) : null,
              )
            else
              Text(curso.ofertas.map((o) => o.resumo).join('\n'), style: GJTypography.bodySm()),
            if (edita)
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
          porPagina: 15,
          descreverTotal: (total) => '$total cursos cadastrados',
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
