import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/link_launcher.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/utils/programa_estilo.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_input.dart';
import '../../../shared/widgets/gj_remote_or_asset_image.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tag.dart';
import '../../../shared/widgets/gj_texto_formatado.dart';
import '../../auth/presentation/exigir_aluno.dart';
import '../../favoritos/data/favoritos_repository.dart';
import '../data/universidades_repository.dart';
import '../domain/avaliacao.dart';
import '../domain/universidade.dart';
import 'avaliar_dialog.dart';
import '../../../shared/utils/plural.dart';
import '../../../shared/widgets/gj_estrelas.dart';
import '../../../shared/utils/sigla_instituicao.dart';

class DetalheUniversidadePage extends StatefulWidget {
  const DetalheUniversidadePage({super.key, required this.id});

  final int id;

  @override
  State<DetalheUniversidadePage> createState() => _DetalheUniversidadePageState();
}

class _DetalheUniversidadePageState extends State<DetalheUniversidadePage> {
  late Future<UniversidadeDetalhe> _future;
  Future<List<Avaliacao>>? _futureAvaliacoes;
  late final Future<List<UniversidadeCampusItem>> _futureCampus = universidadesRepository.campus(widget.id);
  final _campusQueryController = TextEditingController();

  // Vêm do detalhe e mudam sem recarregar a página: salvar/remover e avaliar.
  bool _salvo = false;
  bool _salvando = false;
  MinhaAvaliacao? _minhaAvaliacao;
  double? _media;
  int _total = 0;
  String get _rotaAtual => '/universidades/${widget.id}';

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<UniversidadeDetalhe> _carregar() async {
    final detalhe = await universidadesRepository.detalhe(widget.id);
    _salvo = detalhe.salva;
    _minhaAvaliacao = detalhe.minhaAvaliacao;
    _media = detalhe.mediaAvaliacao;
    _total = detalhe.totalAvaliacoes;
    return detalhe;
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  /// RF01: visitante vai ao login e volta para cá; aluno que já avaliou
  /// abre o modal preenchido para editar.
  Future<void> _avaliar(UniversidadeDetalhe universidade) async {
    if (!exigirAluno(context, voltarPara: _rotaAtual)) return;

    final editando = _minhaAvaliacao != null;
    final gravada = await mostrarModalAvaliar(
      context,
      universidadeId: universidade.id,
      nomeUniversidade: universidade.nomeFantasia,
      avaliacaoAtual: _minhaAvaliacao,
    );
    if (gravada == null || !mounted) return;

    setState(() {
      _minhaAvaliacao = gravada.avaliacao;
      _media = gravada.mediaAvaliacao;
      _total = gravada.totalAvaliacoes;
      _futureAvaliacoes = universidadesRepository.avaliacoes(widget.id, page: 1).then((r) => r.data);
    });
    _avisar(editando ? 'Avaliação atualizada.' : 'Avaliação enviada. Obrigado!');
  }

  Future<void> _alternarSalvo() async {
    if (_salvando || !exigirAluno(context, voltarPara: _rotaAtual)) return;

    final salvar = !_salvo;
    setState(() => _salvando = true);
    try {
      if (salvar) {
        await favoritosRepository.salvarUniversidade(widget.id);
      } else {
        await favoritosRepository.removerUniversidade(widget.id);
      }
      if (!mounted) return;
      setState(() => _salvo = salvar);
      _avisar(salvar ? 'Faculdade salva.' : 'Faculdade removida das salvas.');
    } on ApiException catch (erro) {
      if (mounted) _avisar(erro.message);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
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
              // Bloco (não arrow): setState não aceita callback que devolve Future.
              onAcao: () => setState(() {
                _future = _carregar();
              }),
            );
          }

          final universidade = snapshot.data!;
          final isMobile = MediaQuery.sizeOf(context).width < 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalho(universidade, isMobile),
              GJPageContainer(
                child: Padding(
                padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _blocoSobre(universidade),
                          const SizedBox(height: GJSpace.s8),
                          _blocoContato(universidade),
                          const SizedBox(height: GJSpace.s8),
                          _blocoCampus(universidade),
                          _blocoCursos(),
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
                                _blocoCursos(),
                                const SizedBox(height: GJSpace.s8),
                                _blocoComoEntrar(universidade),
                              ],
                            ),
                          ),
                          const SizedBox(width: GJSpace.s8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _blocoContato(universidade),
                                const SizedBox(height: GJSpace.s8),
                                _blocoAvaliacoes(universidade),
                              ],
                            ),
                          ),
                        ],
                      ),
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
      width: double.infinity,
      color: GJColors.surfaceLow,
      padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
      child: GJPageContainer(
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
                    siglaDaInstituicao(universidade.nomeFantasia),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(universidade.nomeFantasia, style: GJTypography.h1(size: isMobile ? 26 : 32)),
                          if (universidade.razaoSocial != universidade.nomeFantasia)
                            Text(universidade.razaoSocial, style: GJTypography.bodySm()),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: _salvo ? 'Remover das salvas' : 'Salvar faculdade',
                      onPressed: _salvando ? null : _alternarSalvo,
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
                        GJEstrelasMedia(media: _media),
                        const SizedBox(width: GJSpace.s1),
                        Text(
                          _media != null
                              ? '${_media!.toStringAsFixed(1)} (${contagem(_total, 'avaliação', 'avaliações')})'
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
                      label: _minhaAvaliacao != null ? 'Editar avaliação' : 'Avaliar',
                      variant: GJButtonVariant.ghost,
                      icon: Symbols.star,
                      onPressed: () => _avaliar(universidade),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _blocoSobre(UniversidadeDetalhe universidade) {
    if (universidade.descricao == null || universidade.descricao!.trim().isEmpty) return const SizedBox.shrink();

    return _cartao(
      titulo: 'Sobre',
      child: GJTextoFormatado(universidade.descricao),
    );
  }

  /// Contato: telefone da instituição, site e o campus principal (endereço,
  /// telefones e e-mail, que vêm da lista de campi).
  Widget _blocoContato(UniversidadeDetalhe universidade) {
    return FutureBuilder<List<UniversidadeCampusItem>>(
      future: _futureCampus,
      builder: (context, snapshot) {
        final campi = snapshot.data ?? const <UniversidadeCampusItem>[];
        final principal = campi.where((c) => c.principal).firstOrNull ?? campi.firstOrNull;
        final endereco = principal?.endereco ?? universidade.enderecoPrincipal;

        final linhas = <(IconData, String, String, String?)>[
          if (universidade.telefonePrincipal != null)
            (Symbols.call, 'Telefone', universidade.telefonePrincipal!, null),
          if (principal?.telefoneFixo != null && principal!.telefoneFixo != universidade.telefonePrincipal)
            (Symbols.call, 'Telefone do ${principal.nome}', principal.telefoneFixo!, null),
          if (principal?.telefoneCelular != null) (Symbols.smartphone, 'Celular', principal!.telefoneCelular!, null),
          if (principal?.emailCampus != null)
            (Symbols.mail, 'E-mail', principal!.emailCampus!, 'mailto:${principal.emailCampus}'),
          if (universidade.linkPagina != null)
            (Symbols.language, 'Site oficial', universidade.linkPagina!, universidade.linkPagina),
          if (endereco != null)
            (
              Symbols.location_on,
              principal != null ? 'Endereço do ${principal.nome}' : 'Endereço',
              [
                '${endereco.logradouro}, ${endereco.numero}${endereco.complemento != null ? ', ${endereco.complemento}' : ''}',
                endereco.bairro,
                '${endereco.cidade}/${endereco.estado}',
                if (endereco.cep != null) 'CEP ${_cep(endereco.cep!)}',
              ].join(' · '),
              null,
            ),
        ];
        if (linhas.isEmpty) return const SizedBox.shrink();

        return _cartao(
          titulo: 'Contato',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (icone, rotulo, valor, link) in linhas)
                Padding(
                  padding: const EdgeInsets.only(bottom: GJSpace.s3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icone, size: 20, color: GJColors.primary),
                      const SizedBox(width: GJSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rotulo, style: GJTypography.caption()),
                            if (link != null)
                              InkWell(
                                onTap: () => abrirLinkExterno(link),
                                child: Text(
                                  valor,
                                  style: GJTypography.label(color: GJColors.primary)
                                      .copyWith(decoration: TextDecoration.underline, decorationColor: GJColors.primary),
                                ),
                              )
                            else
                              SelectableText(valor, style: GJTypography.label(color: GJColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _cep(String cep) => cep.length == 8 ? '${cep.substring(0, 5)}-${cep.substring(5)}' : cep;

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

  /// Resumo "Cursos oferecidos": cada curso com o campus onde é ofertado
  /// (e o turno), levando ao detalhe do campus. Sem cursos, não aparece.
  Widget _blocoCursos() {
    return FutureBuilder<List<UniversidadeCampusItem>>(
      future: _futureCampus,
      builder: (context, snapshot) {
        final campi = snapshot.data ?? const <UniversidadeCampusItem>[];
        final ofertas = [
          for (final campus in campi)
            for (final curso in campus.cursos) (curso: curso, campus: campus),
        ]..sort((a, b) => a.curso.nome.compareTo(b.curso.nome));
        if (ofertas.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: GJSpace.s8),
          child: _cartao(
            titulo: 'Cursos oferecidos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (indice, oferta) in ofertas.indexed)
                  InkWell(
                    onTap: () => context.go('/campus/${oferta.campus.id}'),
                    borderRadius: GJRadius.borderMd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: GJSpace.s3, horizontal: GJSpace.s2),
                      decoration: BoxDecoration(
                        border: indice == 0 ? null : Border(top: BorderSide(color: GJColors.border.withOpacity(0.4))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(oferta.curso.nome, style: GJTypography.label().copyWith(color: GJColors.textPrimary)),
                                Text(
                                  [
                                    oferta.campus.nome,
                                    if (oferta.curso.turno != null) oferta.curso.turno!,
                                    if (oferta.curso.vagas != null) contagem(oferta.curso.vagas!, 'vaga', 'vagas'),
                                  ].join(' · '),
                                  style: GJTypography.bodySm(),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Symbols.chevron_right, color: GJColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _blocoComoEntrar(UniversidadeDetalhe universidade) {
    // RF11: as bolsas da própria universidade formam um grupo à parte, com o
    // nome completo, separadas das bolsas nacionais aceitas.
    final grupos = <MapEntry<String, List<ProgramaTag>>>[
      for (final entrada in universidade.programasPorTipo.entries) ...[
        MapEntry(entrada.key, [for (final p in entrada.value) if (!p.institucional) p]),
        if (entrada.key == 'BOLSA') MapEntry('INSTITUCIONAL', [for (final p in entrada.value) if (p.institucional) p]),
      ],
    ].where((entrada) => entrada.value.isNotEmpty);
    if (grupos.isEmpty) return const SizedBox.shrink();

    const titulos = {
      'ENTRADA': 'Programas de Entrada',
      'FINANCIAMENTO': 'Financiamento',
      'BOLSA': 'Bolsas',
      'INSTITUCIONAL': 'Bolsas da própria instituição',
    };

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
                  // Programas sem observação ficam lado a lado; os que têm
                  // observação da universidade vêm um por linha, com o texto.
                  Wrap(
                    spacing: GJSpace.s2,
                    runSpacing: GJSpace.s2,
                    children: [
                      for (final programa in grupo.value)
                        if (programa.observacao == null) _tagPrograma(programa, grupo.key),
                    ],
                  ),
                  for (final programa in grupo.value)
                    if (programa.observacao != null)
                      Padding(
                        padding: const EdgeInsets.only(top: GJSpace.s2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _tagPrograma(programa, grupo.key),
                            const SizedBox(width: GJSpace.s3),
                            Expanded(child: Text(programa.observacao!, style: GJTypography.bodySm())),
                          ],
                        ),
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
            return GJEmptyState(
              titulo: 'Nenhuma avaliação ainda',
              texto: 'Seja o primeiro a avaliar essa universidade.',
              icone: Symbols.rate_review,
              acaoLabel: 'Avaliar universidade',
              onAcao: () => _avaliar(universidade),
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
                        _media?.toStringAsFixed(1) ?? '-',
                        style: GJTypography.display(size: 40).copyWith(color: GJColors.primary),
                      ),
                      GJEstrelasMedia(media: _media, tamanho: 16),
                      Text(contagem(_total, 'avaliação', 'avaliações'), style: GJTypography.caption()),
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
                label: _minhaAvaliacao != null ? 'Editar minha avaliação' : 'Avaliar universidade',
                expand: true,
                onPressed: () => _avaliar(universidade),
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

  Widget _tagPrograma(ProgramaTag programa, String grupo) => GestureDetector(
        onTap: () => context.go('/programas/${programa.id}'),
        child: programa.institucional
            ? GJTag(label: programa.nome, tone: tonePrograma('BOLSA'))
            : GJTag(label: programa.sigla ?? programa.nome, tone: tonePrograma(grupo)),
      );

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
