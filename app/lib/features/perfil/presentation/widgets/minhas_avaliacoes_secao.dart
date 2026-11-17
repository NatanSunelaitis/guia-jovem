import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_radius.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/utils/formatar_data.dart';
import '../../../../shared/widgets/gj_button.dart';
import '../../../../shared/widgets/gj_empty_state.dart';
import '../../../universidades/data/universidades_repository.dart';
import '../../../universidades/domain/avaliacao.dart';
import 'secao_carregavel.dart';

/// Avaliações feitas pelo aluno (RF01), com acesso à universidade, onde
/// ele também edita a avaliação.
class MinhasAvaliacoesSecao extends StatefulWidget {
  const MinhasAvaliacoesSecao({super.key});

  @override
  State<MinhasAvaliacoesSecao> createState() => _MinhasAvaliacoesSecaoState();
}

class _MinhasAvaliacoesSecaoState extends State<MinhasAvaliacoesSecao> {
  late Future<List<AvaliacaoDoAluno>> _future = universidadesRepository.minhasAvaliacoes();

  @override
  Widget build(BuildContext context) {
    return SecaoCarregavel<AvaliacaoDoAluno>(
      future: _future,
      onTentarNovamente: () => setState(() {
        _future = universidadesRepository.minhasAvaliacoes();
      }),
      vazio: GJEmptyState(
        titulo: 'Você ainda não avaliou nenhuma universidade',
        texto: 'Na página de uma universidade, use "Avaliar" para contar sua experiência a outros estudantes.',
        icone: Symbols.rate_review,
        acaoLabel: 'Pesquisar universidades',
        onAcao: () => context.go('/universidades'),
      ),
      construir: (lista) => Column(
        children: [
          for (final avaliacao in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: GJSpace.s3),
              child: Container(
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
                          Text(avaliacao.nomeUniversidade, style: GJTypography.h4()),
                          const SizedBox(height: GJSpace.s1),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 1; i <= 5; i++)
                                Icon(
                                  Symbols.star,
                                  size: GJSpace.s4,
                                  fill: i <= avaliacao.nota ? 1 : 0,
                                  color: i <= avaliacao.nota ? GJColors.rating : GJColors.border,
                                ),
                              const SizedBox(width: GJSpace.s2),
                              Text('Avaliada em ${formatarData(avaliacao.criadoEm)}', style: GJTypography.caption()),
                            ],
                          ),
                          if (avaliacao.comentario != null) ...[
                            const SizedBox(height: GJSpace.s2),
                            Text(avaliacao.comentario!, style: GJTypography.bodySm()),
                          ],
                        ],
                      ),
                    ),
                    GJButton(
                      label: 'Ver universidade',
                      variant: GJButtonVariant.secondary,
                      size: GJButtonSize.sm,
                      onPressed: () => context.go('/universidades/${avaliacao.universidadeId}'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
