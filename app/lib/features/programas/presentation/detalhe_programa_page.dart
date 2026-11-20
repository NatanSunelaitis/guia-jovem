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
import '../../../shared/widgets/gj_remote_or_asset_image.dart';
import '../../../shared/widgets/gj_skeleton.dart';
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

    return GJPageContainer(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(context, isMobile),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _secaoDuasColunas(
                isMobile,
                esquerda: programa.comoFunciona == null
                    ? const SizedBox.shrink()
                    : _cartao(
                        titulo: 'Como Funciona',
                        corFundo: GJColors.surfaceLow,
                        corTexto: GJColors.textPrimary,
                        child: Text(programa.comoFunciona!, style: GJTypography.body()),
                      ),
                direita: programa.requisitos == null
                    ? const SizedBox.shrink()
                    : _cartao(
                        titulo: 'Elegibilidade',
                        corFundo: _cor,
                        corTexto: GJColors.primaryOn,
                        child: Text(
                          programa.requisitos!,
                          style: GJTypography.body().copyWith(color: GJColors.primaryOn.withOpacity(0.92)),
                        ),
                      ),
              ),
              const SizedBox(height: GJSpace.s8),
              _secaoDuasColunas(
                isMobile,
                esquerda: programa.eventos.isEmpty
                    ? const SizedBox.shrink()
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
                                descricao: evento.descricao,
                                concluido: evento.dataInicio.isBefore(DateTime.now()),
                              ),
                          ],
                        ),
                      ),
                direita: _cartao(
                  titulo: 'Próximos Passos',
                  corFundo: GJColors.surfaceLow,
                  corTexto: GJColors.textPrimary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final passo in passos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: GJSpace.s3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(passo.icon, size: 22, color: _cor),
                              const SizedBox(width: GJSpace.s3),
                              Expanded(child: Text(passo.texto, style: GJTypography.body())),
                            ],
                          ),
                        ),
                    ],
                  ),
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
                  width: isMobile ? (MediaQuery.sizeOf(context).width - GJSpace.s8) / 2 : 180,
                  child: _cardUniversidade(context, _dona!),
                )
              else if (programa.universidades.isEmpty)
                const GJEmptyState(titulo: 'Nenhuma universidade cadastrada ainda para este programa')
              else
                Wrap(
                  spacing: GJSpace.s4,
                  runSpacing: GJSpace.s4,
                  children: [
                    for (final universidade in programa.universidades)
                      SizedBox(
                        width: isMobile ? (MediaQuery.sizeOf(context).width - GJSpace.s8) / 2 : 180,
                        child: _cardUniversidade(context, universidade),
                      ),
                  ],
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
        child: GJRemoteOrAssetImage(url: programa.imagemUrl ?? imagemProgramaPadrao),
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

  Widget _secaoDuasColunas(bool isMobile, {required Widget esquerda, required Widget direita}) {
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

  Widget _cardUniversidade(BuildContext context, UniversidadeQueAceita universidade) {
    return GestureDetector(
      onTap: () => context.go('/universidades/${universidade.id}'),
      child: Container(
        padding: const EdgeInsets.all(GJSpace.s4),
        decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderLg),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 72,
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
            // Altura de até três linhas para todos os cards: o nome inteiro
            // cabe e os cards ficam do mesmo tamanho.
            SizedBox(
              height: GJSpace.s16,
              child: Center(
                child: Text(
                  universidade.nomeFantasia,
                  style: GJTypography.label().copyWith(color: GJColors.textPrimary),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
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
