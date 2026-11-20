import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_card.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../data/campus_repository.dart';
import '../domain/campus.dart';
import '../../../shared/utils/plural.dart';

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
                    '${campus.endereco.cep != null ? ' - CEP ${campus.endereco.cep}' : ''}',
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
                  if (campus.cursos.isEmpty)
                    const GJEmptyState(titulo: 'Nenhum curso cadastrado', icone: Symbols.menu_book)
                  else
                    Wrap(
                      spacing: GJSpace.s4,
                      runSpacing: GJSpace.s4,
                      children: [
                        for (final curso in campus.cursos)
                          SizedBox(
                            width: 280,
                            child: GJCard(
                              onTap: () => context.go('/cursos/${curso.id}'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(curso.nome, style: GJTypography.h4()),
                                  const SizedBox(height: GJSpace.s1),
                                  if (curso.turno != null)
                                    Text('Turno: ${curso.turno}', style: GJTypography.bodySm()),
                                  if (curso.vagas != null)
                                    Text(contagem(curso.vagas!, 'vaga', 'vagas'), style: GJTypography.bodySm(color: GJColors.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                      ],
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
