import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_radius.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/utils/formatar_data.dart';
import '../../../../shared/widgets/gj_button.dart';
import '../../../../shared/widgets/gj_empty_state.dart';
import '../../../../shared/widgets/gj_tag.dart';
import '../../../favoritos/data/favoritos_repository.dart';
import '../../../favoritos/domain/pesquisa_salva.dart';
import 'secao_carregavel.dart';
import '../../../../shared/widgets/gj_aviso.dart';

/// Pesquisas salvas (Quadro 7): nome, data e filtros; "Executar" reabre a
/// pesquisa com os filtros gravados e excluir pede confirmação.
class PesquisasSalvasSecao extends StatefulWidget {
  const PesquisasSalvasSecao({super.key});

  @override
  State<PesquisasSalvasSecao> createState() => _PesquisasSalvasSecaoState();
}

class _PesquisasSalvasSecaoState extends State<PesquisasSalvasSecao> {
  late Future<List<PesquisaSalva>> _future = favoritosRepository.listarPesquisas();
  final _excluindo = <int>{};

  Future<void> _excluir(List<PesquisaSalva> lista, PesquisaSalva pesquisa) async {
    final mensageiro = ScaffoldMessenger.of(context);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: GJRadius.borderLg),
        title: const Text('Excluir pesquisa'),
        content: Text('Tem certeza que deseja excluir a pesquisa "${pesquisa.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          GJButton(label: 'Excluir', variant: GJButtonVariant.danger, onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    setState(() => _excluindo.add(pesquisa.id));
    try {
      await favoritosRepository.excluirPesquisa(pesquisa.id);
      if (!mounted) return;
      final todas = await _future;
      if (!mounted) return;
      setState(() => todas.remove(pesquisa));
      mensageiro.aviso('Pesquisa excluída.');
    } on ApiException catch (erro) {
      mensageiro.aviso(erro.message, tipo: GJAvisoTipo.erro);
    } finally {
      if (mounted) setState(() => _excluindo.remove(pesquisa.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecaoCarregavel<PesquisaSalva>(
      future: _future,
      porPagina: 8,
      descreverTotal: (total) => '$total pesquisas salvas',
      onTentarNovamente: () => setState(() {
        _future = favoritosRepository.listarPesquisas();
      }),
      vazio: GJEmptyState(
        titulo: 'Nenhuma pesquisa salva',
        texto: 'Ao pesquisar universidades, use "Salvar pesquisa" para repetir a mesma combinação de filtros depois.',
        icone: Symbols.saved_search,
        acaoLabel: 'Fazer uma pesquisa',
        onAcao: () => context.go('/universidades'),
      ),
      construir: (lista) => Column(
        children: [
          for (final pesquisa in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: GJSpace.s3),
              child: _ItemPesquisa(
                pesquisa: pesquisa,
                excluindo: _excluindo.contains(pesquisa.id),
                onExecutar: () => context.go('/universidades?pesquisaSalva=${pesquisa.id}'),
                onExcluir: () => _excluir(lista, pesquisa),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemPesquisa extends StatelessWidget {
  const _ItemPesquisa({
    required this.pesquisa,
    required this.excluindo,
    required this.onExecutar,
    required this.onExcluir,
  });

  final PesquisaSalva pesquisa;
  final bool excluindo;
  final VoidCallback onExecutar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final filtros = descreverFiltros(pesquisa.parametros);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s5),
      decoration: BoxDecoration(color: GJColors.surfaceLowest, borderRadius: GJRadius.borderLg),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: GJSpace.s4,
        runSpacing: GJSpace.s3,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pesquisa.nome, style: GJTypography.h4()),
                const SizedBox(height: GJSpace.s1),
                Text('Salva em ${formatarData(pesquisa.criadoEm)}', style: GJTypography.caption()),
                const SizedBox(height: GJSpace.s2),
                Wrap(
                  spacing: GJSpace.s1,
                  runSpacing: GJSpace.s1,
                  children: [
                    if (filtros.isEmpty)
                      const GJTag(label: 'Sem filtros', tone: GJTagTone.entrada)
                    else
                      for (final filtro in filtros) GJTag(label: filtro, tone: GJTagTone.entrada),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Excluir pesquisa',
                onPressed: excluindo ? null : onExcluir,
                icon: const Icon(Symbols.delete, color: GJColors.error),
              ),
              const SizedBox(width: GJSpace.s2),
              GJButton(label: 'Executar', icon: Symbols.play_arrow, size: GJButtonSize.sm, onPressed: onExecutar),
            ],
          ),
        ],
      ),
    );
  }
}

/// Os filtros gravados em texto legível, na ordem da barra de pesquisa.
/// Programa e curso vêm só como id; o nome aparece ao executar a pesquisa.
List<String> descreverFiltros(Map<String, dynamic> parametros) {
  String? texto(String chave) {
    final valor = parametros[chave];
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }

  final nota = double.tryParse(texto('notaMinima') ?? '');
  const ordenacoes = {'nome': 'Ordenado por nome', 'media': 'Ordenado por média', 'avaliacoes': 'Ordenado por avaliações'};

  return [
    if (texto('q') != null) 'Universidade: ${texto('q')}',
    if (texto('cidade') != null) 'Cidade: ${texto('cidade')}',
    if (texto('estado') != null) 'Estado: ${texto('estado')}',
    if (texto('natureza') == 'P') 'Públicas',
    if (texto('natureza') == 'V') 'Privadas',
    if (nota != null && nota > 0) 'Nota mínima ${nota.toStringAsFixed(1).replaceAll('.', ',')}',
    if (texto('curso') != null) 'Curso: ${texto('curso')}',
    if (texto('areaCurso') != null) 'Área: ${texto('areaCurso')}',
    if (texto('programaId') != null) 'Programa aceito',
    if (texto('cursoId') != null) 'Curso',
    // "nome" é a ordenação padrão: só aparece quando o aluno escolheu outra.
    if (texto('sort') != null && texto('sort') != 'nome' && ordenacoes.containsKey(texto('sort')))
      ordenacoes[texto('sort')]!,
  ];
}
