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
import '../data/universidades_repository.dart';
import '../domain/avaliacao.dart';
import '../domain/universidade.dart';
import 'avaliar_dialog.dart';

class DetalheUniversidadePage extends StatefulWidget {
  const DetalheUniversidadePage({super.key, required this.id});

  final int id;

  @override
  State<DetalheUniversidadePage> createState() => _DetalheUniversidadePageState();
}

class _DetalheUniversidadePageState extends State<DetalheUniversidadePage> {
  late Future<UniversidadeDetalhe> _future;
  bool _salvo = false;

  @override
  void initState() {
    super.initState();
    _future = universidadesRepository.detalhe(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      rotaAtiva: PublicRota.universidades,
      child: FutureBuilder<UniversidadeDetalhe>(
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
              onAcao: () => setState(() => _future = universidadesRepository.detalhe(widget.id)),
            );
          }

          final universidade = snapshot.data!;
          final isMobile = MediaQuery.sizeOf(context).width < 600;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s16, vertical: GJSpace.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cabecalho(universidade),
                const SizedBox(height: GJSpace.s8),
                _blocoCampus(universidade),
                const SizedBox(height: GJSpace.s8),
                _blocoComoEntrar(universidade),
                const SizedBox(height: GJSpace.s8),
                _blocoAvaliacoes(universidade),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cabecalho(UniversidadeDetalhe universidade) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(universidade.nomeFantasia, style: GJTypography.h1()),
              const SizedBox(height: GJSpace.s2),
              if (universidade.descricao != null)
                Text(universidade.descricao!, style: GJTypography.body(), maxLines: 4, overflow: TextOverflow.ellipsis),
              const SizedBox(height: GJSpace.s3),
              Row(
                children: [
                  const Icon(Symbols.star, size: 20, color: GJColors.rating, fill: 1),
                  const SizedBox(width: GJSpace.s1),
                  Text(
                    universidade.mediaAvaliacao != null
                        ? '${universidade.mediaAvaliacao!.toStringAsFixed(1)} (${universidade.totalAvaliacoes} avaliações)'
                        : 'Sem avaliações ainda',
                    style: GJTypography.body(),
                  ),
                ],
              ),
              const SizedBox(height: GJSpace.s4),
              Wrap(
                spacing: GJSpace.s3,
                runSpacing: GJSpace.s2,
                children: [
                  if (universidade.linkPagina != null)
                    GJButton(
                      label: 'Acessar Página da Faculdade',
                      icon: Symbols.open_in_new,
                      onPressed: () => abrirLinkExterno(universidade.linkPagina!),
                    ),
                  if (universidade.linkSimulados != null)
                    GJButton(
                      label: 'Simulados Anteriores',
                      icon: Symbols.quiz,
                      variant: GJButtonVariant.secondary,
                      onPressed: () => abrirLinkExterno(universidade.linkSimulados!),
                    ),
                  GJButton(
                    label: 'Avaliar',
                    variant: GJButtonVariant.ghost,
                    icon: Symbols.star,
                    onPressed: () => mostrarModalAvaliar(context, nomeUniversidade: universidade.nomeFantasia),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: _salvo ? 'Remover dos favoritos' : 'Salvar faculdade',
          onPressed: () => setState(() => _salvo = !_salvo),
          icon: Icon(Symbols.bookmark, fill: _salvo ? 1 : 0, color: GJColors.primary),
        ),
      ],
    );
  }

  Widget _blocoCampus(UniversidadeDetalhe universidade) {
    if (universidade.campus.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Campus', style: GJTypography.h2()),
        const SizedBox(height: GJSpace.s4),
        Wrap(
          spacing: GJSpace.s4,
          runSpacing: GJSpace.s4,
          children: [
            for (final campus in universidade.campus)
              SizedBox(
                width: 280,
                child: GJCard(
                  onTap: () => context.go('/campus/${campus.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(campus.nome, style: GJTypography.h4()),
                      const SizedBox(height: GJSpace.s1),
                      Text([campus.cidade, campus.estado].where((v) => v != null).join('/'), style: GJTypography.bodySm()),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _blocoComoEntrar(UniversidadeDetalhe universidade) {
    final grupos = universidade.programasPorTipo.entries.where((entrada) => entrada.value.isNotEmpty);
    if (grupos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Como entrar na universidade', style: GJTypography.h2()),
        const SizedBox(height: GJSpace.s4),
        for (final grupo in grupos)
          Padding(
            padding: const EdgeInsets.only(bottom: GJSpace.s4),
            child: Wrap(
              spacing: GJSpace.s2,
              runSpacing: GJSpace.s2,
              children: [
                for (final programa in grupo.value)
                  GestureDetector(
                    onTap: () => context.go('/programas/${programa.id}'),
                    child: GJTag(label: programa.sigla ?? programa.nome, tone: _tonePorTipo(grupo.key)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _blocoAvaliacoes(UniversidadeDetalhe universidade) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Avaliações', style: GJTypography.h2()),
        const SizedBox(height: GJSpace.s4),
        FutureBuilder(
          future: universidadesRepository.avaliacoes(widget.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const GJSkeleton(height: 80);
            }
            final avaliacoes = snapshot.data?.data ?? <Avaliacao>[];
            if (avaliacoes.isEmpty) {
              return const GJEmptyState(
                titulo: 'Nenhuma avaliação ainda',
                texto: 'Seja o primeiro a avaliar essa universidade.',
                icone: Symbols.rate_review,
              );
            }
            return Column(
              children: [
                for (final avaliacao in avaliacoes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: GJSpace.s3),
                    child: GJCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (var i = 1; i <= 5; i++)
                                Icon(Symbols.star, size: 16, fill: i <= avaliacao.nota ? 1 : 0, color: GJColors.rating),
                              const SizedBox(width: GJSpace.s2),
                              Text(avaliacao.autor ?? 'Usuário removido', style: GJTypography.label()),
                            ],
                          ),
                          if (avaliacao.comentario != null) ...[
                            const SizedBox(height: GJSpace.s2),
                            Text(avaliacao.comentario!, style: GJTypography.bodySm()),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

GJTagTone _tonePorTipo(String tipo) => switch (tipo) {
      'FINANCIAMENTO' => GJTagTone.financiamento,
      'BOLSA' => GJTagTone.bolsa,
      _ => GJTagTone.entrada,
    };
