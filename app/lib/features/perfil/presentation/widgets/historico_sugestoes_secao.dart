import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_radius.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/utils/formatar_data.dart';
import '../../../../shared/widgets/gj_empty_state.dart';
import '../../../../shared/widgets/gj_status_badge.dart';
import '../../../sugestoes/data/sugestoes_repository.dart';
import '../../../sugestoes/domain/sugestao.dart';
import 'secao_carregavel.dart';

/// T18 Histórico de sugestões (Figura 25): título, data, destino, status
/// colorido e a resposta quando houver. O botão "Nova sugestão" (T20) entra
/// junto com a API de sugestões.
class HistoricoSugestoesSecao extends StatefulWidget {
  const HistoricoSugestoesSecao({super.key});

  @override
  State<HistoricoSugestoesSecao> createState() => _HistoricoSugestoesSecaoState();
}

class _HistoricoSugestoesSecaoState extends State<HistoricoSugestoesSecao> {
  late Future<List<Sugestao>> _future = sugestoesRepository.minhas();

  @override
  Widget build(BuildContext context) {
    return SecaoCarregavel<Sugestao>(
      future: _future,
      onTentarNovamente: () => setState(() {
        _future = sugestoesRepository.minhas();
      }),
      vazio: const GJEmptyState(
        titulo: 'Você ainda não enviou sugestões',
        texto: 'Quando enviar uma sugestão para a equipe ou para uma universidade, ela aparece aqui com o status do atendimento.',
        icone: Symbols.forum,
      ),
      construir: (lista) => Column(
        children: [
          for (final sugestao in lista)
            Padding(padding: const EdgeInsets.only(bottom: GJSpace.s3), child: _ItemSugestao(sugestao: sugestao)),
        ],
      ),
    );
  }
}

class _ItemSugestao extends StatelessWidget {
  const _ItemSugestao({required this.sugestao});

  final Sugestao sugestao;

  (String, GJStatusTone) get _status => switch (sugestao.status) {
        StatusSugestao.aprovada => ('Aprovada', GJStatusTone.success),
        StatusSugestao.reprovada => ('Reprovada', GJStatusTone.error),
        StatusSugestao.emAnalise => ('Em análise', GJStatusTone.warning),
      };

  @override
  Widget build(BuildContext context) {
    final (rotulo, tom) = _status;
    final destino = sugestao.universidadeNome ?? 'Equipe Guia Jovem';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s5),
      decoration: BoxDecoration(color: GJColors.surfaceLowest, borderRadius: GJRadius.borderLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GJSpace.s3,
            runSpacing: GJSpace.s2,
            children: [
              Text(sugestao.titulo, style: GJTypography.h4()),
              GJStatusBadge(label: rotulo, tone: tom),
            ],
          ),
          const SizedBox(height: GJSpace.s1),
          Text('${formatarData(sugestao.criadoEm)} · Para: $destino', style: GJTypography.caption()),
          const SizedBox(height: GJSpace.s2),
          Text(sugestao.texto, style: GJTypography.bodySm()),
          if (sugestao.resposta != null) ...[
            const SizedBox(height: GJSpace.s3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(GJSpace.s3),
              decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderMd),
              child: Text('Resposta: ${sugestao.resposta}', style: GJTypography.bodySm()),
            ),
          ],
        ],
      ),
    );
  }
}
