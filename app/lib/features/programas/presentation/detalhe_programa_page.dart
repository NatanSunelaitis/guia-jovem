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
import '../../../shared/utils/fotos.dart';
import '../../../shared/utils/programa_estilo.dart';
import '../../../shared/utils/texto_formatado.dart';
import '../../../shared/widgets/gj_button.dart';
import '../../../shared/utils/plural.dart';
import '../../../shared/widgets/gj_aligned_grid.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_lista_paginada.dart';
import '../../../shared/widgets/gj_remote_or_asset_image.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_texto_formatado.dart';
import '../../../shared/widgets/gj_timeline.dart';
import '../data/programas_repository.dart';
import '../domain/programa.dart';
import '../../../shared/utils/sigla_instituicao.dart';

const _meses = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];

// Próximos passos: conteúdo ilustrativo por categoria (a especificação não
// modela esses passos como dado de programa, então não vem da API; ver
// docs/DECISOES.md).
const _proximosPassos = {
  'FINANCIAMENTO': [
    (icon: Symbols.person_add, texto: 'Crie sua conta no Guia Jovem para salvar universidades e receber avisos de prazo.'),
    (icon: Symbols.search, texto: 'Pesquise universidades privadas que aceitam este financiamento na sua cidade.'),
    (icon: Symbols.calculate, texto: 'Simule o valor financiado e a parcela após a conclusão do curso.'),
    (icon: Symbols.event, texto: 'Anote as datas do cronograma e prepare os documentos com antecedência.'),
  ],
  'BOLSA': [
    (icon: Symbols.person_add, texto: 'Crie sua conta no Guia Jovem para salvar universidades e receber avisos de prazo.'),
    (icon: Symbols.search, texto: 'Pesquise universidades que oferecem esta bolsa na sua cidade.'),
    (icon: Symbols.fact_check, texto: 'Confira se você atende aos critérios de renda e desempenho exigidos.'),
    (icon: Symbols.event, texto: 'Anote as datas do cronograma e prepare os documentos com antecedência.'),
  ],
  // Bolsa institucional: passos da própria instituição, sem critérios genéricos.
  'INSTITUCIONAL': [
    (icon: Symbols.person_add, texto: 'Crie sua conta no Guia Jovem para salvar a universidade e receber avisos de prazo.'),
    (icon: Symbols.account_balance, texto: 'Conheça a página da universidade, com os campi e os cursos oferecidos.'),
    (icon: Symbols.event, texto: 'Anote as datas e prepare os documentos pedidos nos requisitos.'),
  ],
  'ENTRADA': [
    (icon: Symbols.person_add, texto: 'Crie sua conta no Guia Jovem para salvar universidades e receber avisos de prazo.'),
    (icon: Symbols.search, texto: 'Pesquise universidades que aceitam este programa na sua cidade.'),
    (icon: Symbols.workspace_premium, texto: 'Confira se você se encaixa em bolsas ou financiamentos com a nota esperada.'),
    (icon: Symbols.event, texto: 'Anote as datas do cronograma e prepare os documentos com antecedência.'),
  ],
};

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
              onAcao: () => setState(() {
                _future = programasRepository.detalhe(widget.id);
              }),
            );
          }

          return _Conteudo(programa: snapshot.data!);
        },
      ),
    );
  }
}

/// Título do cronograma com os anos das datas exibidas: um ano (2027), dois
/// (2026 e 2027) ou um intervalo (2026 a 2028).
String tituloCronograma(List<ProgramaEvento> eventos) {
  final anos = {for (final evento in eventos) evento.dataInicio.year}.toList()..sort();
  if (anos.isEmpty) return 'Cronograma';
  if (anos.length == 1) return 'Cronograma ${anos.first}';
  if (anos.length == 2) return 'Cronograma ${anos.first} e ${anos.last}';
  return 'Cronograma ${anos.first} a ${anos.last}';
}

/// Abertura do programa: o primeiro parágrafo da descrição, em texto puro,
/// mostrado no topo da página.
String? aberturaDoPrograma(String descricao) => primeiroParagrafo(interpretarTextoFormatado(descricao));

/// Seções da descrição (cada subtítulo `##` vira um card), sem o primeiro
/// parágrafo, que já aparece no topo. Seções que ficam vazias saem.
List<SecaoFormatada> secoesDoPrograma(String descricao) {
  final blocos = [...interpretarTextoFormatado(descricao)];
  final primeiro = blocos.indexWhere((b) => b is ParagrafoFormatado);
  if (primeiro != -1) blocos.removeAt(primeiro);
  return separarSecoes(blocos);
}

String _dataCurta(DateTime data) => '${data.day.toString().padLeft(2, '0')} ${_meses[data.month - 1]} ${data.year}';

/// Descrição do evento na linha do tempo, com a data de fim quando há período.
String? descricaoDoEvento(ProgramaEvento evento) {
  final fim = evento.dataFim;
  final ate = fim != null && fim.isAfter(evento.dataInicio) ? 'Até ${_dataCurta(fim)}' : null;
  final partes = [if (evento.descricao != null && evento.descricao!.isNotEmpty) evento.descricao!, if (ate != null) ate];
  return partes.isEmpty ? null : partes.join(' · ');
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.programa});

  final ProgramaDetalhe programa;

  bool get _financiamento => programa.tipo == 'FINANCIAMENTO';

  /// Bolsa institucional: tem uma universidade dona em vez de uma lista de quem aceita.
  UniversidadeQueAceita? get _dona => programa.universidade;

  Color get _cor => corPrograma(programa.tipo);

  String get _rotuloTipo => rotuloTipoPrograma(programa.tipo);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final passos = _proximosPassos[_dona != null ? 'INSTITUCIONAL' : programa.tipo] ?? _proximosPassos['ENTRADA']!;
    final secoes = secoesDoPrograma(programa.descricao);

    return GJPageContainer(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(context, isMobile),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (secoes.isNotEmpty) ...[
                _secoesDescricao(secoes, isMobile),
                const SizedBox(height: GJSpace.s8),
              ],
              if (programa.comoFunciona != null || programa.requisitos != null) ...[
              _secaoDuasColunas(
                isMobile,
                esquerda: programa.comoFunciona == null
                    ? null
                    : _cartao(
                        titulo: 'Como Funciona',
                        corFundo: GJColors.surfaceLow,
                        corTexto: GJColors.textPrimary,
                        child: GJTextoFormatado(programa.comoFunciona),
                      ),
                direita: programa.requisitos == null
                    ? null
                    : _cartao(
                        titulo: 'Elegibilidade',
                        corFundo: _cor,
                        corTexto: GJColors.primaryOn,
                        child: GJTextoFormatado(programa.requisitos, cor: GJColors.primaryOn),
                      ),
              ),
              const SizedBox(height: GJSpace.s8),
              ],
              // Sem datas importantes, os próximos passos ocupam a largura
              // toda (em duas colunas no desktop), sem um bloco vazio ao lado.
              _secaoDuasColunas(
                isMobile,
                esquerda: programa.eventos.isEmpty
                    ? null
                    : _cartao(
                        titulo: tituloCronograma(programa.eventos),
                        corFundo: GJColors.surfaceLowest,
                        corTexto: GJColors.textPrimary,
                        elevado: true,
                        child: GJTimeline(
                          cor: _cor,
                          itens: [
                            for (final evento in programa.eventos)
                              GJTimelineItem(
                                mes: _meses[evento.dataInicio.month - 1],
                                dia: evento.dataInicio.day.toString().padLeft(2, '0'),
                                ano: '${evento.dataInicio.year}',
                                titulo: evento.titulo,
                                descricao: descricaoDoEvento(evento),
                                concluido: evento.dataInicio.isBefore(DateTime.now()),
                              ),
                          ],
                        ),
                      ),
                direita: _cartao(
                  titulo: 'Próximos Passos',
                  corFundo: GJColors.surfaceLow,
                  corTexto: GJColors.textPrimary,
                  child: _passos(passos, duasColunas: programa.eventos.isEmpty && !isMobile),
                ),
              ),
              const SizedBox(height: GJSpace.s8),
              Text(
                _dona != null ? 'Universidade que oferece esta bolsa' : 'Universidades que aceitam este programa',
                style: GJTypography.h2(size: 24),
              ),
              const SizedBox(height: GJSpace.s4),
              if (_dona != null)
                SizedBox(
                  width: isMobile ? (MediaQuery.sizeOf(context).width - GJSpace.s8) / 2 : 220,
                  child: _cardUniversidade(context, _dona!),
                )
              else if (programa.totalUniversidades == 0)
                const GJEmptyState(titulo: 'Nenhuma universidade cadastrada ainda para este programa')
              else
                // Paginada pela API (8 por página), com busca por nome ou cidade.
                GJListaPaginada<UniversidadeQueAceita>(
                  carregar: ({required pagina, busca, filtro}) =>
                      programasRepository.universidades(programa.id, pagina: pagina, busca: busca),
                  dicaBusca: 'Buscar universidade por nome ou cidade',
                  descreverTotal: (total) => contagem(total, 'universidade aceita este programa', 'universidades aceitam este programa'),
                  textoVazio: 'Nenhuma universidade encontrada com essa busca',
                  construirItens: (context, universidades) => GJAlignedGrid(
                    itemWidth: isMobile ? 150 : 220,
                    spacing: GJSpace.s4,
                    runSpacing: GJSpace.s4,
                    children: [for (final universidade in universidades) _cardUniversidade(context, universidade)],
                  ),
                ),
              const SizedBox(height: GJSpace.s8),
              _cta(context),
              const SizedBox(height: GJSpace.s12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, bool isMobile) {
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: GJSpace.s4, vertical: GJSpace.s1),
          decoration: BoxDecoration(color: _cor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
          child: Text(_rotuloTipo.toUpperCase(), style: GJTypography.eyebrow(color: _cor)),
        ),
        const SizedBox(height: GJSpace.s4),
        Text(programa.nome, style: GJTypography.display(size: isMobile ? 32 : 48).copyWith(color: _cor)),
        const SizedBox(height: GJSpace.s4),
        if (aberturaDoPrograma(programa.descricao) case final abertura?) ...[
          Text(abertura, style: GJTypography.bodyLg()),
          const SizedBox(height: GJSpace.s4),
        ],
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
            if (_dona != null)
              GJButton(
                label: 'Ver universidade',
                icon: Symbols.account_balance,
                variant: GJButtonVariant.secondary,
                color: _cor,
                onPressed: () => context.go('/universidades/${_dona!.id}'),
              )
            else
              GJButton(
                label: 'Pesquisar universidades',
                icon: Symbols.search,
                variant: GJButtonVariant.secondary,
                color: _cor,
                onPressed: () => context.go('/universidades', extra: {'programaId': '${programa.id}'}),
              ),
          ],
        ),
      ],
    );

    final imagem = ClipRRect(
      borderRadius: GJRadius.borderXl,
      child: AspectRatio(
        aspectRatio: isMobile ? 16 / 9 : 16 / 10,
        child: GJRemoteOrAssetImage(
          url: fotoPrograma(nome: programa.nome, sigla: programa.sigla, imagemUrl: programa.imagemUrl),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, GJSpace.s12, 0, GJSpace.s8),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [imagem, const SizedBox(height: GJSpace.s6), texto],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 3, child: texto),
                const SizedBox(width: GJSpace.s8),
                Expanded(flex: 2, child: imagem),
              ],
            ),
    );
  }

  Widget _passos(List<({IconData icon, String texto})> passos, {required bool duasColunas}) {
    Widget passo(({IconData icon, String texto}) p) => Padding(
          padding: const EdgeInsets.only(bottom: GJSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(p.icon, size: 22, color: _cor),
              const SizedBox(width: GJSpace.s3),
              Expanded(child: Text(p.texto, style: GJTypography.body())),
            ],
          ),
        );

    if (!duasColunas) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final p in passos) passo(p)]);
    }
    final metade = (passos.length / 2).ceil();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: [for (final p in passos.take(metade)) passo(p)])),
        const SizedBox(width: GJSpace.s8),
        Expanded(child: Column(children: [for (final p in passos.skip(metade)) passo(p)])),
      ],
    );
  }

  /// Duas colunas lado a lado no desktop. Quando só um lado tem conteúdo,
  /// ele ocupa a largura toda, sem deixar a outra coluna vazia.
  Widget _secaoDuasColunas(bool isMobile, {Widget? esquerda, Widget? direita}) {
    if (esquerda == null || direita == null) return esquerda ?? direita ?? const SizedBox.shrink();
    if (isMobile) {
      return Column(children: [esquerda, const SizedBox(height: GJSpace.s6), direita]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: esquerda),
        const SizedBox(width: GJSpace.s8),
        Expanded(child: direita),
      ],
    );
  }

  Widget _cartao({
    required String titulo,
    required Widget child,
    required Color corFundo,
    required Color corTexto,
    bool elevado = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s8),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: GJRadius.borderXl,
        boxShadow: elevado ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: GJTypography.h2(size: 24).copyWith(color: corTexto)),
          const SizedBox(height: GJSpace.s5),
          child,
        ],
      ),
    );
  }

  /// Seções da descrição em cards, em duas colunas no desktop (alternando,
  /// para equilibrar as alturas) e uma no celular.
  Widget _secoesDescricao(List<SecaoFormatada> secoes, bool isMobile) {
    Widget card(SecaoFormatada secao) => Padding(
          padding: const EdgeInsets.only(bottom: GJSpace.s6),
          child: _cartao(
            titulo: secao.titulo ?? (_dona != null ? 'Sobre a bolsa' : 'Sobre o programa'),
            corFundo: GJColors.surfaceLowest,
            corTexto: GJColors.textPrimary,
            elevado: true,
            child: GJTextoFormatado.blocos(secao.blocos),
          ),
        );

    if (isMobile || secoes.length == 1) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final secao in secoes) card(secao)]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: [for (final (i, secao) in secoes.indexed) if (i.isEven) card(secao)])),
        const SizedBox(width: GJSpace.s8),
        Expanded(child: Column(children: [for (final (i, secao) in secoes.indexed) if (i.isOdd) card(secao)])),
      ],
    );
  }

  /// Card de altura uniforme: logo, nome em até duas linhas, cidade e a
  /// observação da universidade sobre o programa num espaço fixo (vazio
  /// quando não há), para a grade não ficar desalinhada.
  Widget _cardUniversidade(BuildContext context, UniversidadeQueAceita universidade) {
    final observacao = universidade.observacao;
    return Material(
      color: GJColors.surfaceLow,
      borderRadius: GJRadius.borderLg,
      child: InkWell(
        key: Key('universidade-programa-${universidade.id}'),
        borderRadius: GJRadius.borderLg,
        onTap: () => context.go('/universidades/${universidade.id}'),
        child: Padding(
          padding: const EdgeInsets.all(GJSpace.s4),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: GJSpace.s16,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: GJColors.surfaceLowest, borderRadius: GJRadius.borderMd),
                child: universidade.logoUrl != null
                    ? Padding(
                        padding: const EdgeInsets.all(GJSpace.s2),
                        child: GJRemoteOrAssetImage(url: universidade.logoUrl!, fit: BoxFit.contain),
                      )
                    : Text(
                        siglaDaInstituicao(universidade.nomeFantasia),
                        style: GJTypography.label().copyWith(color: GJColors.primary, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(height: GJSpace.s3),
              SizedBox(
                height: GJSpace.s12 - GJSpace.s1,
                child: Center(
                  child: Text(
                    universidade.nomeFantasia,
                    style: GJTypography.label().copyWith(color: GJColors.textPrimary),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(
                height: GJSpace.s5,
                child: Text(
                  universidade.cidade == null ? '' : '${universidade.cidade}/${universidade.estado}',
                  style: GJTypography.caption(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: GJSpace.s1),
              SizedBox(
                height: GJSpace.s8 + GJSpace.s1,
                child: observacao == null
                    ? null
                    : Tooltip(
                        message: observacao,
                        child: Text(
                          observacao,
                          style: GJTypography.caption(color: GJColors.primaryDark),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cta(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s8),
      decoration: BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: GJRadius.borderXl,
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pronto para começar seu futuro?', style: GJTypography.h2(size: 28)),
                const SizedBox(height: GJSpace.s2),
                Text(
                  _dona != null
                      ? 'Veja os campi e os cursos da ${_dona!.nomeFantasia}.'
                      : 'Veja quais universidades aceitam este programa na sua cidade.',
                  style: GJTypography.body(),
                ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? 0 : GJSpace.s8, height: isMobile ? GJSpace.s4 : 0),
          GJButton(
            label: _dona != null ? 'Ver universidade' : 'Pesquisar universidades',
            variant: _financiamento ? GJButtonVariant.financiamento : GJButtonVariant.primary,
            expand: isMobile,
            onPressed: () => _dona != null
                ? context.go('/universidades/${_dona!.id}')
                : context.go('/universidades', extra: {'programaId': '${programa.id}'}),
          ),
        ],
      ),
    );
  }
}
