import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/link_launcher.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/utils/programa_estilo.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../../shared/widgets/gj_remote_or_asset_image.dart';
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
  Future<List<Avaliacao>>? _futureAvaliacoes;
  bool _salvo = false;
  final _campusQueryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = universidadesRepository.detalhe(widget.id);
  }

  @override
  void dispose() {
    _campusQueryController.dispose();
    super.dispose();
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalho(universidade, isMobile),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s16, vertical: GJSpace.s12),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _blocoSobre(universidade),
                          const SizedBox(height: GJSpace.s8),
                          _blocoCampus(universidade),
                          const SizedBox(height: GJSpace.s8),
                          _blocoComoEntrar(universidade),
                          const SizedBox(height: GJSpace.s8),
                          _blocoAvaliacoes(universidade),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _blocoSobre(universidade),
                                const SizedBox(height: GJSpace.s8),
                                _blocoCampus(universidade),
                                const SizedBox(height: GJSpace.s8),
                                _blocoComoEntrar(universidade),
                              ],
                            ),
                          ),
                          const SizedBox(width: GJSpace.s8),
                          Expanded(child: _blocoAvaliacoes(universidade)),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cabecalho(UniversidadeDetalhe universidade, bool isMobile) {
    return Container(
      color: GJColors.surfaceLow,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? GJSpace.s4 : GJSpace.s16, vertical: GJSpace.s12),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.start,
        children: [
          Container(
            width: 128,
            height: 128,
            padding: const EdgeInsets.all(GJSpace.s4),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: GJColors.surfaceLowest, borderRadius: GJRadius.borderLg),
            child: universidade.logoUrl != null
                ? GJRemoteOrAssetImage(url: universidade.logoUrl!, fit: BoxFit.contain)
                : Text(
                    universidade.nomeFantasia,
                    style: GJTypography.h3().copyWith(color: GJColors.primary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          SizedBox(width: isMobile ? 0 : GJSpace.s8, height: isMobile ? GJSpace.s4 : 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(universidade.nomeFantasia, style: GJTypography.h1(size: isMobile ? 26 : 32))),
                    IconButton(
                      tooltip: _salvo ? 'Remover dos favoritos' : 'Salvar faculdade',
                      onPressed: () => setState(() => _salvo = !_salvo),
                      icon: Icon(Symbols.bookmark, fill: _salvo ? 1 : 0, color: GJColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: GJSpace.s2),
                Wrap(
                  spacing: GJSpace.s3,
                  runSpacing: GJSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (universidade.enderecoPrincipal != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Symbols.location_on, size: 18, color: GJColors.textSecondary),
                          const SizedBox(width: GJSpace.s1),
                          Text(
                            '${universidade.enderecoPrincipal!.cidade}, ${universidade.enderecoPrincipal!.estado}',
                            style: GJTypography.bodySm(),
                          ),
                        ],
                      ),
                    GJTag(
                      label: universidade.natureza == 'P' ? 'Pública' : 'Privada',
                      tone: GJTagTone.entrada,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            Symbols.star,
                            size: 18,
                            fill: universidade.mediaAvaliacao != null && i <= universidade.mediaAvaliacao!.round() ? 1 : 0,
                            color: universidade.mediaAvaliacao != null ? GJColors.rating : GJColors.border,
                          ),
                        const SizedBox(width: GJSpace.s1),
                        Text(
                          universidade.mediaAvaliacao != null
                              ? '${universidade.mediaAvaliacao!.toStringAsFixed(1)} (${universidade.totalAvaliacoes} avaliações)'
                              : 'Sem avaliações ainda',
                          style: GJTypography.bodySm(),
                        ),
                      ],
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
                        label: 'Acessar página da faculdade',
                        icon: Symbols.open_in_new,
                        onPressed: () => abrirLinkExterno(universidade.linkPagina!),
                      ),
                    if (universidade.linkSimulados != null)
                      GJButton(
                        label: 'Simulados anteriores',
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
        ],
      ),
    );
  }

  Widget _blocoSobre(UniversidadeDetalhe universidade) {
    if (universidade.descricao == null) return const SizedBox.shrink();

    return _cartao(
      titulo: 'Sobre',
      child: Text(universidade.descricao!, style: GJTypography.body()),
    );
  }

  Widget _blocoCampus(UniversidadeDetalhe universidade) {
    if (universidade.campus.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _campusQueryController,
      builder: (context, _) {
        final busca = _campusQueryController.text.trim().toLowerCase();
        final filtrados = busca.isEmpty
            ? universidade.campus
            : universidade.campus
                .where((c) => c.nome.toLowerCase().contains(busca) || (c.cidade ?? '').toLowerCase().contains(busca))
                .toList();

        return _cartao(
          titulo: 'Campus',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GJInput(
                label: '',
                hint: 'Pesquisar campus',
                icon: Symbols.search,
                controller: _campusQueryController,
              ),
              const SizedBox(height: GJSpace.s3),
              if (filtrados.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: GJSpace.s4),
                  child: Text('Nenhum campus encontrado com esse termo.', style: GJTypography.bodySm()),
                )
              else
                for (final campus in filtrados)
                  Padding(
                    padding: const EdgeInsets.only(bottom: GJSpace.s3),
                    child: Container(
                      padding: const EdgeInsets.all(GJSpace.s4),
                      decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderMd),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: GJColors.primaryFixed, borderRadius: GJRadius.borderSm),
                            child: const Icon(Symbols.location_on, color: GJColors.primary),
                          ),
                          const SizedBox(width: GJSpace.s4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(campus.nome, style: GJTypography.label().copyWith(fontSize: 16, color: GJColors.textPrimary)),
                                if (campus.cidade != null)
                                  Text([campus.cidade, campus.estado].whereType<String>().join('/'), style: GJTypography.bodySm()),
                              ],
                            ),
                          ),
                          const SizedBox(width: GJSpace.s3),
                          GJButton(
                            label: 'Ver campus',
                            variant: GJButtonVariant.secondary,
                            size: GJButtonSize.sm,
                            onPressed: () => context.go('/campus/${campus.id}'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _blocoComoEntrar(UniversidadeDetalhe universidade) {
    final grupos = universidade.programasPorTipo.entries.where((entrada) => entrada.value.isNotEmpty);
    if (grupos.isEmpty) return const SizedBox.shrink();

    const titulos = {'ENTRADA': 'Programas de Entrada', 'FINANCIAMENTO': 'Financiamento', 'BOLSA': 'Bolsas'};

    return _cartao(
      titulo: 'Como entrar nesta universidade',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final grupo in grupos)
            Padding(
              padding: const EdgeInsets.only(bottom: GJSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (titulos[grupo.key] ?? grupo.key).toUpperCase(),
                    style: GJTypography.caption().copyWith(fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                  const SizedBox(height: GJSpace.s2),
                  Wrap(
                    spacing: GJSpace.s2,
                    runSpacing: GJSpace.s2,
                    children: [
                      for (final programa in grupo.value)
                        GestureDetector(
                          onTap: () => context.go('/programas/${programa.id}'),
                          child: GJTag(label: programa.sigla ?? programa.nome, tone: tonePrograma(grupo.key)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _blocoAvaliacoes(UniversidadeDetalhe universidade) {
    // Criado só aqui (não em initState): esta função só roda depois que
    // `_future` (o detalhe da universidade) já resolveu com sucesso, então
    // uma universidade inexistente nunca dispara essa segunda chamada.
    _futureAvaliacoes ??= universidadesRepository.avaliacoes(widget.id, page: 1).then((r) => r.data);

    return _cartao(
      titulo: 'Avaliações',
      child: FutureBuilder<List<Avaliacao>>(
        future: _futureAvaliacoes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const GJSkeleton(height: 120);
          }

          final avaliacoes = snapshot.data ?? <Avaliacao>[];
          if (avaliacoes.isEmpty) {
            return const GJEmptyState(
              titulo: 'Nenhuma avaliação ainda',
              texto: 'Seja o primeiro a avaliar essa universidade.',
              icone: Symbols.rate_review,
            );
          }

          final distribuicao = <int, int>{for (var i = 1; i <= 5; i++) i: 0};
          for (final avaliacao in avaliacoes) {
            distribuicao[avaliacao.nota] = (distribuicao[avaliacao.nota] ?? 0) + 1;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        universidade.mediaAvaliacao?.toStringAsFixed(1) ?? '-',
                        style: GJTypography.display(size: 40).copyWith(color: GJColors.primary),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 1; i <= 5; i++)
                            Icon(
                              Symbols.star,
                              size: 16,
                              fill: universidade.mediaAvaliacao != null && i <= universidade.mediaAvaliacao!.round() ? 1 : 0,
                              color: GJColors.rating,
                            ),
                        ],
                      ),
                      Text('${universidade.totalAvaliacoes} avaliações', style: GJTypography.caption()),
                    ],
                  ),
                  const SizedBox(width: GJSpace.s6),
                  Expanded(
                    child: Column(
                      children: [
                        for (var estrela = 5; estrela >= 1; estrela--)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                SizedBox(width: 12, child: Text('$estrela', style: GJTypography.caption())),
                                const SizedBox(width: GJSpace.s2),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: avaliacoes.isEmpty ? 0 : (distribuicao[estrela] ?? 0) / avaliacoes.length,
                                      minHeight: 8,
                                      backgroundColor: GJColors.surface,
                                      color: GJColors.rating,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: GJSpace.s2),
                                SizedBox(
                                  width: 24,
                                  child: Text('${distribuicao[estrela]}', style: GJTypography.caption(), textAlign: TextAlign.right),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GJSpace.s4),
              GJButton(
                label: 'Avaliar universidade',
                expand: true,
                onPressed: () => mostrarModalAvaliar(context, nomeUniversidade: universidade.nomeFantasia),
              ),
              const SizedBox(height: GJSpace.s4),
              const Divider(height: 1, color: GJColors.surfaceHigh),
              const SizedBox(height: GJSpace.s4),
              for (final avaliacao in avaliacoes)
                Padding(
                  padding: const EdgeInsets.only(bottom: GJSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: GJColors.primaryFixed, shape: BoxShape.circle),
                            child: Text(
                              (avaliacao.autor ?? '?').substring(0, 1).toUpperCase(),
                              style: GJTypography.caption(color: GJColors.primary).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: GJSpace.s2),
                          Text(avaliacao.autor ?? 'Usuário removido', style: GJTypography.label().copyWith(color: GJColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: GJSpace.s1),
                      Row(
                        children: [
                          for (var i = 1; i <= 5; i++)
                            Icon(Symbols.star, size: 14, fill: i <= avaliacao.nota ? 1 : 0, color: GJColors.rating),
                        ],
                      ),
                      if (avaliacao.comentario != null) ...[
                        const SizedBox(height: GJSpace.s1),
                        Text(avaliacao.comentario!, style: GJTypography.bodySm()),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _cartao({required String titulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s8),
      decoration: BoxDecoration(color: GJColors.surfaceLowest, borderRadius: GJRadius.borderLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: GJTypography.h2()),
          const SizedBox(height: GJSpace.s4),
          child,
        ],
      ),
    );
  }
}
