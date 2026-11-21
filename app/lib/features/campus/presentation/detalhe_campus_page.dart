import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_shadows.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_lista_paginada.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../data/campus_repository.dart';
import '../domain/campus.dart';
import '../../../shared/utils/plural.dart';
import '../../../shared/utils/mascaras.dart';

class DetalheCampusPage extends StatefulWidget {
  const DetalheCampusPage({super.key, required this.id});

  final int id;

  @override
  State<DetalheCampusPage> createState() => _DetalheCampusPageState();
}

class _DetalheCampusPageState extends State<DetalheCampusPage> {
  late Future<CampusDetalhe> _future;

  @override
  void initState() {
    super.initState();
    _future = campusRepository.detalhe(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: FutureBuilder<CampusDetalhe>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(padding: EdgeInsets.all(GJSpace.s16), child: GJSkeletonCard());
          }

          if (snapshot.hasError) {
            return GJEmptyState(
              titulo: 'Não foi possível carregar',
              texto: snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Tente novamente.',
              icone: Symbols.wifi_off,
              acaoLabel: 'Tentar novamente',
              onAcao: () => setState(() {
                _future = campusRepository.detalhe(widget.id);
              }),
            );
          }

          final campus = snapshot.data!;

          return GJPageContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/universidades/${campus.universidade.id}'),
                    icon: const Icon(Symbols.arrow_back, size: 18),
                    label: Text(campus.universidade.nomeFantasia),
                  ),
                  const SizedBox(height: GJSpace.s2),
                  Text(campus.nome, style: GJTypography.h1()),
                  const SizedBox(height: GJSpace.s4),
                  Text(
                    '${campus.endereco.logradouro}, ${campus.endereco.numero}'
                    '${campus.endereco.complemento != null ? ' - ${campus.endereco.complemento}' : ''}\n'
                    '${campus.endereco.bairro}, ${campus.endereco.cidade}/${campus.endereco.estado}'
                    '${campus.endereco.cep != null ? ' - CEP ${formatarCep(campus.endereco.cep)}' : ''}',
                    style: GJTypography.body(),
                  ),
                  const SizedBox(height: GJSpace.s3),
                  Wrap(
                    spacing: GJSpace.s5,
                    runSpacing: GJSpace.s2,
                    children: [
                      if (campus.telefoneFixo != null) _contato(Symbols.call, campus.telefoneFixo!),
                      if (campus.telefoneCelular != null) _contato(Symbols.smartphone, campus.telefoneCelular!),
                      if (campus.emailCampus != null) _contato(Symbols.mail, campus.emailCampus!),
                    ],
                  ),
                  const SizedBox(height: GJSpace.s8),
                  Text('Lista de cursos oferecidos neste campus', style: GJTypography.h2()),
                  const SizedBox(height: GJSpace.s4),
                  if (campus.totalCursos == 0)
                    const GJEmptyState(titulo: 'Nenhum curso cadastrado', icone: Symbols.menu_book)
                  else
                    GJListaPaginada<CampusCursoDetalhe>(
                      carregar: ({required pagina, busca, filtro}) =>
                          campusRepository.cursos(campus.id, pagina: pagina, busca: busca, area: filtro),
                      dicaBusca: 'Buscar curso pelo nome',
                      rotuloFiltro: 'Área',
                      opcoesFiltro: campus.areasCursos,
                      descreverTotal: (total) => contagem(total, 'curso encontrado', 'cursos encontrados'),
                      textoVazio: 'Nenhum curso encontrado com esses filtros',
                      construirItens: (context, cursos) => _ListaCursos(cursos: cursos),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _contato(IconData icone, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 18, color: GJColors.textSecondary),
        const SizedBox(width: GJSpace.s1),
        Text(texto, style: GJTypography.bodySm()),
      ],
    );
  }
}

/// Cursos do campus em linhas de altura igual: nome, área, grau e
/// modalidade, turno e vagas. Cada linha leva à página do curso.
class _ListaCursos extends StatelessWidget {
  const _ListaCursos({required this.cursos});

  final List<CampusCursoDetalhe> cursos;

  @override
  Widget build(BuildContext context) {
    final celular = MediaQuery.sizeOf(context).width < 600;
    return Container(
      decoration: BoxDecoration(color: GJColors.surfaceLowest, borderRadius: GJRadius.borderLg, border: GJShadows.borderSubtle),
      child: Column(
        children: [
          for (final (indice, curso) in cursos.indexed)
            InkWell(
              key: Key('curso-campus-${curso.id}'),
              onTap: () => context.go('/cursos/${curso.id}'),
              child: Container(
                height: celular ? GJSpace.s24 : GJSpace.s16 + GJSpace.s2,
                padding: const EdgeInsets.symmetric(horizontal: GJSpace.s5),
                decoration: BoxDecoration(
                  border: indice == 0 ? null : const Border(top: BorderSide(color: GJColors.surfaceHigh)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(curso.nome, style: GJTypography.label(color: GJColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            [curso.areaCurso, curso.grau, curso.modalidade].whereType<String>().join(' · '),
                            style: GJTypography.bodySm(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (celular)
                            Text(
                              [curso.turno, if (curso.vagas != null) contagem(curso.vagas!, 'vaga', 'vagas')].whereType<String>().join(' · '),
                              style: GJTypography.bodySm(),
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                    if (!celular) ...[
                      Expanded(flex: 2, child: Text(curso.turno ?? '-', style: GJTypography.bodySm())),
                      Expanded(
                        flex: 2,
                        child: Text(curso.vagas == null ? '-' : contagem(curso.vagas!, 'vaga', 'vagas'), style: GJTypography.bodySm()),
                      ),
                    ],
                    const Icon(Symbols.chevron_right, color: GJColors.textSecondary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
