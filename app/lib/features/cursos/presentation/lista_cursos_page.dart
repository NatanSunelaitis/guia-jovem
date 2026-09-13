import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_illustrations.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_card.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tag.dart';
import '../data/cursos_repository.dart';
import '../domain/curso.dart';

class ListaCursosPage extends StatefulWidget {
  const ListaCursosPage({super.key});

  @override
  State<ListaCursosPage> createState() => _ListaCursosPageState();
}

class _ListaCursosPageState extends State<ListaCursosPage> {
  final _qController = TextEditingController();
  final _areaController = TextEditingController();
  late Future<List<CursoDestaque>> _future;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _qController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _buscar() {
    setState(() {
      _future = cursosRepository.destaques(limite: 100, q: _qController.text, areaCurso: _areaController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return PublicLayout(
      child: GJPageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Qual curso deseja estudar?', style: GJTypography.h1()),
              const SizedBox(height: GJSpace.s6),
              Row(
                children: [
                  Expanded(
                    child: GJInput(label: 'Curso', hint: 'Pesquisar curso', icon: Symbols.menu_book, controller: _qController, onChanged: (_) => _buscar()),
                  ),
                  const SizedBox(width: GJSpace.s4),
                  Expanded(
                    child: GJInput(label: 'Área', hint: 'Área do curso', controller: _areaController, onChanged: (_) => _buscar()),
                  ),
                ],
              ),
              const SizedBox(height: GJSpace.s6),
              FutureBuilder<List<CursoDestaque>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Wrap(
                      spacing: GJSpace.s4,
                      runSpacing: GJSpace.s4,
                      children: List.generate(8, (_) => const SizedBox(width: 240, child: GJSkeletonCard())),
                    );
                  }
                  if (snapshot.hasError) {
                    return GJEmptyState(
                      titulo: 'Não foi possível carregar',
                      texto: snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Tente novamente.',
                      icone: Symbols.wifi_off,
                      acaoLabel: 'Tentar novamente',
                      onAcao: _buscar,
                    );
                  }

                  final cursos = snapshot.data!;
                  if (cursos.isEmpty) {
                    return const GJEmptyState(titulo: 'Nenhum curso encontrado', texto: 'Tente outro termo de busca.');
                  }

                  return Wrap(
                    spacing: GJSpace.s4,
                    runSpacing: GJSpace.s4,
                    children: [
                      for (final curso in cursos)
                        SizedBox(
                          width: isMobile ? (MediaQuery.sizeOf(context).width - GJSpace.s8) : 240,
                          child: GJCard.curso(
                            nome: curso.nome,
                            ilustracao: GJIllustrations.porAreaCurso(curso.areaCurso),
                            onTap: () => context.go('/cursos/nome/${Uri.encodeComponent(curso.nome)}'),
                            rodape: Wrap(
                              spacing: GJSpace.s2,
                              runSpacing: GJSpace.s1,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (curso.areaCurso != null) GJTag(label: curso.areaCurso!, tone: GJTagTone.entrada),
                                Text(
                                  curso.totalOfertas == 1 ? '1 universidade' : '${curso.totalOfertas} universidades',
                                  style: GJTypography.bodySm(),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}
