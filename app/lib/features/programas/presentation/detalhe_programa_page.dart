import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/link_launcher.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_card.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tag.dart';
import '../../../shared/widgets/gj_timeline.dart';
import '../data/programas_repository.dart';
import '../domain/programa.dart';

const _meses = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

class DetalheProgramaPage extends StatefulWidget {
  const DetalheProgramaPage({super.key, required this.id});

  final int id;

  @override
  State<DetalheProgramaPage> createState() => _DetalheProgramaPageState();
}

class _DetalheProgramaPageState extends State<DetalheProgramaPage> {
  late Future<ProgramaDetalhe> _future;

  @override
  void initState() {
    super.initState();
    _future = programasRepository.detalhe(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: FutureBuilder<ProgramaDetalhe>(
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
              onAcao: () => setState(() => _future = programasRepository.detalhe(widget.id)),
            );
          }

          return _Conteudo(programa: snapshot.data!);
        },
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.programa});

  final ProgramaDetalhe programa;

  bool get _financiamento => programa.tipo == 'FINANCIAMENTO';

  Color get _cor => switch (programa.tipo) {
        'FINANCIAMENTO' => GJColors.tertiary,
        'BOLSA' => GJColors.secondary,
        _ => GJColors.primary,
      };

  GJTagTone get _tone => switch (programa.tipo) {
        'FINANCIAMENTO' => GJTagTone.financiamento,
        'BOLSA' => GJTagTone.bolsa,
        _ => GJTagTone.entrada,
      };

  String get _rotuloTipo => switch (programa.tipo) {
        'FINANCIAMENTO' => 'Financiamento Estudantil',
        'BOLSA' => 'Bolsa de Estudo',
        _ => 'Programa de Entrada',
      };

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s16, vertical: GJSpace.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GJTag(label: _rotuloTipo, tone: _tone),
          const SizedBox(height: GJSpace.s3),
          Text(programa.nome, style: GJTypography.display(size: isMobile ? 32 : 48).copyWith(color: _cor)),
          const SizedBox(height: GJSpace.s4),
          Text(programa.descricao, style: GJTypography.bodyLg()),
          const SizedBox(height: GJSpace.s4),
          Wrap(
            spacing: GJSpace.s3,
            runSpacing: GJSpace.s2,
            children: [
              if (programa.linkOficial != null)
                GJButton(
                  label: 'Ver site oficial',
                  icon: Symbols.open_in_new,
                  variant: _financiamento ? GJButtonVariant.financiamento : GJButtonVariant.primary,
                  onPressed: () => abrirLinkExterno(programa.linkOficial!),
                ),
              GJButton(
                label: 'Pesquisar universidades',
                icon: Symbols.search,
                variant: GJButtonVariant.secondary,
                onPressed: () => context.go('/universidades', extra: {'programaId': '${programa.id}'}),
              ),
            ],
          ),
          const SizedBox(height: GJSpace.s16),
          if (programa.comoFunciona != null) ...[
            Text('Como Funciona', style: GJTypography.h2()),
            const SizedBox(height: GJSpace.s3),
            Text(programa.comoFunciona!, style: GJTypography.body()),
            const SizedBox(height: GJSpace.s12),
          ],
          if (programa.requisitos != null) ...[
            Text('Elegibilidade / Requisitos', style: GJTypography.h2()),
            const SizedBox(height: GJSpace.s3),
            Text(programa.requisitos!, style: GJTypography.body()),
            const SizedBox(height: GJSpace.s12),
          ],
          if (programa.eventos.isNotEmpty) ...[
            Text('Datas Importantes', style: GJTypography.h2()),
            const SizedBox(height: GJSpace.s4),
            GJTimeline(
              itens: [
                for (final evento in programa.eventos)
                  GJTimelineItem(
                    mes: _meses[evento.dataInicio.month - 1],
                    dia: evento.dataInicio.day.toString().padLeft(2, '0'),
                    titulo: evento.titulo,
                    descricao: evento.descricao,
                    concluido: evento.dataInicio.isBefore(DateTime.now()),
                  ),
              ],
            ),
            const SizedBox(height: GJSpace.s12),
          ],
          Text('Universidades que aceitam', style: GJTypography.h2()),
          const SizedBox(height: GJSpace.s4),
          if (programa.universidades.isEmpty)
            const GJEmptyState(titulo: 'Nenhuma universidade cadastrada ainda para este programa')
          else
            Wrap(
              spacing: GJSpace.s4,
              runSpacing: GJSpace.s4,
              children: [
                for (final universidade in programa.universidades)
                  SizedBox(
                    width: isMobile ? double.infinity : 220,
                    child: GJCard(
                      onTap: () => context.go('/universidades/${universidade.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(universidade.nomeFantasia, style: GJTypography.label().copyWith(fontSize: 16)),
                          if (universidade.observacao != null) ...[
                            const SizedBox(height: GJSpace.s1),
                            Text(universidade.observacao!, style: GJTypography.caption()),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
