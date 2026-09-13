import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/paginated_result.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_card.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../../shared/widgets/gj_skeleton.dart';
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
  late Future<PaginatedResult<CursoResumo>> _future;

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
      _future = cursosRepository.listar(FiltrosCursos(q: _qController.text, areaCurso: _areaController.text));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return PublicLayout(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s16, vertical: GJSpace.s12),
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
            FutureBuilder<PaginatedResult<CursoResumo>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Wrap(
                    spacing: GJSpace.s4,
                    runSpacing: GJSpace.s4,
                    children: List.generate(6, (_) => const SizedBox(width: 260, child: GJSkeletonCard())),
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

                final cursos = snapshot.data!.data;
                if (cursos.isEmpty) {
                  return const GJEmptyState(titulo: 'Nenhum curso encontrado', texto: 'Tente outro termo de busca.');
                }

                return Wrap(
                  spacing: GJSpace.s4,
                  runSpacing: GJSpace.s4,
                  children: [
                    for (final curso in cursos)
                      SizedBox(
                        width: isMobile ? double.infinity : 260,
                        child: GJCard(
                          onTap: () => context.go('/cursos/${curso.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(curso.nome, style: GJTypography.h4()),
                              const SizedBox(height: GJSpace.s1),
                              Text(curso.universidade.nomeFantasia, style: GJTypography.bodySm()),
                              if (curso.areaCurso != null) Text(curso.areaCurso!, style: GJTypography.caption()),
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
    );
  }
}
