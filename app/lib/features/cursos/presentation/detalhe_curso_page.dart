import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_shadows.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../../shared/utils/fotos.dart';
import '../../../shared/utils/plural.dart';
import '../../../shared/utils/programa_estilo.dart';
import '../../../shared/utils/sigla_instituicao.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_lista_paginada.dart';
import '../../../shared/widgets/gj_remote_or_asset_image.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tabs.dart';
import '../../../shared/widgets/gj_tag.dart';
import '../../../shared/widgets/gj_texto_formatado.dart';
import '../../universidades/domain/universidade.dart' show ProgramaTag;
import '../data/cursos_repository.dart';
import '../domain/curso.dart';

/// T06: aceita `id` (detalhe de uma oferta específica) ou `nome` ("em quais
/// universidades este curso está disponível", Figura 15). As duas formas
/// usam a mesma página: resumo no topo, descrição e um card por oferta.
class DetalheCursoPage extends StatefulWidget {
  const DetalheCursoPage.porId({super.key, required this.id}) : nome = null;

  const DetalheCursoPage.porNome({super.key, required this.nome}) : id = null;

  final int? id;
  final String? nome;

  @override
  State<DetalheCursoPage> createState() => _DetalheCursoPageState();
}

typedef _CursoCarregado = ({String nome, String? areaCurso, List<OfertaCurso> ofertas});

class _DetalheCursoPageState extends State<DetalheCursoPage> {
  late Future<_CursoCarregado> _future = _carregar();

  Future<_CursoCarregado> _carregar() async {
    if (widget.id != null) {
      final curso = await cursosRepository.detalhe(widget.id!);
      return (nome: curso.nome, areaCurso: curso.oferta.areaCurso, ofertas: [curso.oferta]);
    }
    final curso = await cursosRepository.porNome(widget.nome!);
    return (nome: curso.nome, areaCurso: curso.areaCurso, ofertas: curso.universidades);
  }

  @override
  Widget build(BuildContext context) {
    return PublicLayout(
      child: FutureBuilder<_CursoCarregado>(
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
                _future = _carregar();
              }),
            );
          }
          final curso = snapshot.data!;
          return _Conteudo(nome: curso.nome, areaCurso: curso.areaCurso, ofertas: curso.ofertas, porNome: widget.id == null);
        },
      ),
    );
  }
}

/// Cards de universidade por página quando o curso tem muitas ofertas.
const _porPagina = 8;

/// Corpo da página: cabeçalho com o resumo, "Sobre o curso" e os cards das
/// universidades, com filtros por grau e modalidade quando eles variam.
class _Conteudo extends StatefulWidget {
  const _Conteudo({required this.nome, required this.areaCurso, required this.ofertas, required this.porNome});

  final String nome;
  final String? areaCurso;
  final List<OfertaCurso> ofertas;
  final bool porNome;

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  String? _grau;
  String? _modalidade;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final ofertas = widget.ofertas;
    final graus = distribuicaoPorUniversidade(ofertas, (o) => o.grau);
    final modalidades = distribuicaoPorUniversidade(ofertas, (o) => o.modalidade);
    final filtradas = [
      for (final o in ofertas)
        if ((_grau == null || o.grau == _grau) && (_modalidade == null || o.modalidade == _modalidade)) o,
    ];

    return GJPageContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CabecalhoCurso(
              imagem: fotoCurso(nome: widget.nome, areaCurso: widget.areaCurso),
              children: [
                if (widget.areaCurso != null) ...[
                  Text(widget.areaCurso!.toUpperCase(), style: GJTypography.eyebrow()),
                  const SizedBox(height: GJSpace.s2),
                ],
                Text(widget.nome, style: GJTypography.display(size: isMobile ? 32 : 44)),
                if (widget.porNome) ...[
                  const SizedBox(height: GJSpace.s2),
                  Text(
                    'Em quais universidades este curso está disponível',
                    style: GJTypography.body().copyWith(color: GJColors.textSecondary),
                  ),
                ],
                const SizedBox(height: GJSpace.s5),
                _ResumoCurso(areaCurso: widget.areaCurso, ofertas: ofertas),
              ],
            ),
            const SizedBox(height: GJSpace.s8),
            _SobreOCurso(ofertas: ofertas),
            const SizedBox(height: GJSpace.s8),
            Text(
              ofertas.length == 1 ? 'Universidade que oferece este curso' : 'Universidades que oferecem este curso',
              style: GJTypography.h2(),
            ),
            const SizedBox(height: GJSpace.s4),
            if (graus.length > 1) ...[
              const _AvisoGraus(),
              const SizedBox(height: GJSpace.s4),
              _FiltroCards(
                rotulo: 'Grau',
                chave: 'grau',
                todos: 'Todos os graus',
                opcoes: graus,
                selecionado: _grau,
                onMudar: (valor) => setState(() => _grau = valor),
              ),
            ],
            if (modalidades.length > 1)
              _FiltroCards(
                rotulo: 'Modalidade',
                chave: 'modalidade',
                todos: 'Todas as modalidades',
                opcoes: modalidades,
                selecionado: _modalidade,
                onMudar: (valor) => setState(() => _modalidade = valor),
              ),
            if (ofertas.isEmpty)
              const GJEmptyState(titulo: 'Nenhuma universidade oferece este curso no momento')
            else if (filtradas.isEmpty)
              const GJEmptyState(titulo: 'Nenhuma universidade com esses filtros', texto: 'Escolha outro grau ou outra modalidade.')
            else if (filtradas.length <= _porPagina)
              for (final oferta in filtradas)
                Padding(padding: const EdgeInsets.only(bottom: GJSpace.s4), child: _CardOferta(oferta: oferta))
            else
              // Muitas universidades: 8 cards por página, com busca. O resumo
              // do topo continua considerando todas as ofertas.
              GJListaPaginada<OfertaCurso>(
                key: ValueKey('ofertas-${_grau ?? ''}-${_modalidade ?? ''}'),
                carregar: ({required pagina, busca, filtro}) => paginarLocal(
                  filtradas,
                  pagina: pagina,
                  porPagina: _porPagina,
                  busca: busca,
                  texto: (oferta) => [oferta.universidade.nomeFantasia, oferta.universidade.cidade, for (final c in oferta.campus) c.cidade].join(' '),
                ),
                dicaBusca: 'Buscar universidade ou cidade',
                descreverTotal: (total) => contagem(total, 'universidade', 'universidades'),
                textoVazio: 'Nenhuma universidade encontrada com essa busca',
                construirItens: (context, pagina) => Column(
                  children: [
                    for (final oferta in pagina)
                      Padding(padding: const EdgeInsets.only(bottom: GJSpace.s4), child: _CardOferta(oferta: oferta)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Aviso curto quando o mesmo curso é oferecido em mais de um grau.
class _AvisoGraus extends StatelessWidget {
  const _AvisoGraus();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('aviso-graus'),
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s4),
      decoration: BoxDecoration(color: GJColors.primaryFixed, borderRadius: GJRadius.borderLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Symbols.info, size: 20, color: GJColors.primary),
          const SizedBox(width: GJSpace.s3),
          Expanded(
            child: Text(
              'Este curso é oferecido em formatos diferentes. O grau muda o diploma, a duração e onde você pode atuar: '
              'confira o de cada universidade.',
              style: GJTypography.bodySm().copyWith(color: GJColors.primaryContainerOn),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filtro sobre os cards (grau ou modalidade), com quantas universidades
/// oferecem cada opção.
class _FiltroCards extends StatelessWidget {
  const _FiltroCards({
    required this.rotulo,
    required this.chave,
    required this.todos,
    required this.opcoes,
    required this.selecionado,
    required this.onMudar,
  });

  final String rotulo;
  final String chave;
  final String todos;
  final List<(String, int)> opcoes;
  final String? selecionado;
  final ValueChanged<String?> onMudar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GJSpace.s4),
      child: Wrap(
        spacing: GJSpace.s2,
        runSpacing: GJSpace.s2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: GJSpace.s24, child: Text(rotulo, style: GJTypography.label(color: GJColors.textPrimary))),
          ChoiceChip(
            key: Key('filtro-$chave-todos'),
            label: Text(todos),
            selected: selecionado == null,
            onSelected: (_) => onMudar(null),
          ),
          for (final (valor, total) in opcoes)
            ChoiceChip(
              key: Key('filtro-$chave-$valor'),
              label: Text('$valor ($total)'),
              selected: selecionado == valor,
              onSelected: (marcado) => onMudar(marcado ? valor : null),
            ),
        ],
      ),
    );
  }
}

/// "Sobre o curso": sempre no mesmo lugar, acima dos cards. Uma descrição
/// (ou todas iguais) aparece inteira; descrições diferentes ficam em abas
/// com a sigla de cada universidade que descreveu o curso.
class _SobreOCurso extends StatefulWidget {
  const _SobreOCurso({required this.ofertas});

  final List<OfertaCurso> ofertas;

  @override
  State<_SobreOCurso> createState() => _SobreOCursoState();
}

class _SobreOCursoState extends State<_SobreOCurso> {
  int _aba = 0;

  /// Sigla da aba; a mesma universidade com duas ofertas leva a modalidade.
  List<String> _rotulos(List<OfertaCurso> ofertas) {
    final siglas = [for (final o in ofertas) siglaDaInstituicao(o.universidade.nomeFantasia)];
    return [
      for (var i = 0; i < ofertas.length; i++)
        siglas.where((s) => s == siglas[i]).length > 1 && ofertas[i].modalidade != null
            ? '${siglas[i]} (${ofertas[i].modalidade})'
            : siglas[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final comDescricao = ofertasComDescricao(widget.ofertas);
    final unica = descricaoComum(widget.ofertas);
    final Widget conteudo;

    if (comDescricao.isEmpty) {
      conteudo = Text(
        'As universidades ainda não descreveram este curso. Veja abaixo onde ele é oferecido.',
        key: const Key('sobre-sem-descricao'),
        style: GJTypography.body().copyWith(color: GJColors.textSecondary),
      );
    } else if (unica != null) {
      conteudo = GJTextoFormatado(unica);
    } else {
      final aba = _aba.clamp(0, comDescricao.length - 1);
      final selecionada = comDescricao[aba];
      conteudo = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Descrição informada por cada instituição', style: GJTypography.bodySm()),
          const SizedBox(height: GJSpace.s3),
          GJTabs(
            key: const Key('abas-descricao'),
            tabs: [for (final rotulo in _rotulos(comDescricao)) GJTabItem(label: rotulo)],
            selectedIndex: aba,
            onChanged: (indice) => setState(() => _aba = indice),
          ),
          const SizedBox(height: GJSpace.s4),
          Text(selecionada.universidade.nomeFantasia, style: GJTypography.label(color: GJColors.textPrimary)),
          const SizedBox(height: GJSpace.s2),
          GJTextoFormatado(selecionada.descricao!, key: ValueKey('descricao-${selecionada.cursoId}')),
        ],
      );
    }

    return Container(
      key: const Key('sobre-o-curso'),
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s8),
      decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sobre o curso', style: GJTypography.h2(size: 24)),
          const SizedBox(height: GJSpace.s4),
          conteudo,
        ],
      ),
    );
  }
}

/// Resumo no topo: área, graus, modalidades, duração, nota do MEC e onde o
/// curso é dado. Valores que variam entre as universidades aparecem como
/// faixa ou lista, com a distribuição por grau e por modalidade.
class _ResumoCurso extends StatelessWidget {
  const _ResumoCurso({required this.areaCurso, required this.ofertas});

  final String? areaCurso;
  final List<OfertaCurso> ofertas;

  @override
  Widget build(BuildContext context) {
    final graus = distribuicaoPorUniversidade(ofertas, (o) => o.grau);
    final modalidades = distribuicaoPorUniversidade(ofertas, (o) => o.modalidade);
    final duracao = duracaoDasOfertas(ofertas);
    final notaMec = notaMecDasOfertas(ofertas);
    final universidades = {for (final o in ofertas) o.universidade.id}.length;
    final cidades = cidadesDasOfertas(ofertas).length;

    final fatos = <(IconData, String, String, String?)>[
      if (areaCurso != null) (Symbols.category, 'Área', areaCurso!, null),
      if (graus.isNotEmpty)
        (
          Symbols.school,
          graus.length > 1 ? 'Graus' : 'Grau',
          valoresDistintos(graus.map((g) => g.$1))!,
          textoDistribuicao(graus),
        ),
      if (modalidades.isNotEmpty)
        (
          Symbols.devices,
          modalidades.length > 1 ? 'Modalidades' : 'Modalidade',
          valoresDistintos(modalidades.map((m) => m.$1))!,
          textoDistribuicao(modalidades),
        ),
      if (duracao != null) (Symbols.schedule, 'Duração', duracao, null),
      if (notaMec != null) (Symbols.verified, 'Nota do MEC', notaMec, null),
      (
        Symbols.location_on,
        'Onde é oferecido',
        '${contagem(universidades, 'universidade', 'universidades')} em ${contagem(cidades, 'cidade', 'cidades')}',
        null,
      ),
    ];

    return Wrap(
      spacing: GJSpace.s3,
      runSpacing: GJSpace.s3,
      children: [
        for (final (icone, rotulo, valor, detalhe) in fatos)
          Container(
            key: Key('resumo-$rotulo'),
            padding: const EdgeInsets.symmetric(horizontal: GJSpace.s4, vertical: GJSpace.s3),
            decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderLg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 20, color: GJColors.primary),
                const SizedBox(width: GJSpace.s2),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(rotulo, style: GJTypography.caption()),
                      Text(valor, style: GJTypography.label(color: GJColors.textPrimary)),
                      if (detalhe != null) Text(detalhe, style: GJTypography.caption()),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Card de uma universidade que oferece o curso. Tocar no card leva ao
/// detalhe do primeiro campus da oferta; cada campus leva ao dele.
class _CardOferta extends StatelessWidget {
  const _CardOferta({required this.oferta});

  final OfertaCurso oferta;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    final universidade = oferta.universidade;
    final destino = oferta.campus.isNotEmpty ? '/campus/${oferta.campus.first.id}' : '/universidades/${universidade.id}';

    final identificacao = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // O grau em destaque: o mesmo curso pode ser bacharelado numa
        // universidade e licenciatura ou tecnólogo em outra.
        if (oferta.grau != null) ...[
          Container(
            key: Key('grau-oferta-${oferta.cursoId}'),
            padding: const EdgeInsets.symmetric(horizontal: GJSpace.s3, vertical: GJSpace.s1),
            decoration: BoxDecoration(color: GJColors.primary, borderRadius: GJRadius.borderSm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Symbols.school, size: 16, color: GJColors.primaryOn),
                const SizedBox(width: GJSpace.s1),
                Text(oferta.grau!, style: GJTypography.label(color: GJColors.primaryOn)),
              ],
            ),
          ),
          const SizedBox(height: GJSpace.s3),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: GJSpace.s16,
              height: GJSpace.s16,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(GJSpace.s1),
              decoration: BoxDecoration(color: GJColors.primaryFixed, borderRadius: GJRadius.borderMd),
              child: universidade.logoUrl != null
                  ? GJRemoteOrAssetImage(url: universidade.logoUrl!, fit: BoxFit.contain)
                  : Text(
                      siglaDaInstituicao(universidade.nomeFantasia),
                      style: GJTypography.label(color: GJColors.primaryDark).copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            const SizedBox(width: GJSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(universidade.nomeFantasia, style: GJTypography.h4()),
                  const SizedBox(height: GJSpace.s1),
                  Wrap(
                    spacing: GJSpace.s2,
                    runSpacing: GJSpace.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (universidade.cidade != null)
                        Text('${universidade.cidade}/${universidade.estado}', style: GJTypography.bodySm()),
                      if (universidade.natureza != null)
                        GJTag(
                          label: universidade.natureza == 'P' ? 'Pública' : 'Privada',
                          tone: universidade.natureza == 'P' ? GJTagTone.success : GJTagTone.neutral,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: GJSpace.s4),
        Wrap(
          spacing: GJSpace.s5,
          runSpacing: GJSpace.s2,
          children: [
            if (oferta.modalidade != null) _dado(Symbols.devices, 'Modalidade', oferta.modalidade!),
            if (oferta.duracaoSemestres != null)
              _dado(Symbols.schedule, 'Duração', duracaoDasOfertas([oferta])!),
            _dado(Symbols.verified, 'Nota do MEC', oferta.notaMec ?? 'Não informada'),
          ],
        ),
      ],
    );

    final campi = _secao(
      'Campi, turnos e vagas',
      oferta.campus.isEmpty
          ? Text('Nenhum campus com turma aberta no momento.', style: GJTypography.bodySm())
          : Column(
              children: [
                for (final campus in oferta.campus)
                  InkWell(
                    onTap: () => context.go('/campus/${campus.id}'),
                    borderRadius: GJRadius.borderSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: GJSpace.s2),
                      child: Row(
                        children: [
                          const Icon(Symbols.apartment, size: 18, color: GJColors.textSecondary),
                          const SizedBox(width: GJSpace.s2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(campus.nome, style: GJTypography.label(color: GJColors.textPrimary)),
                                Text(
                                  [
                                    '${campus.cidade}/${campus.estado}',
                                    if (campus.turno != null) campus.turno!,
                                    if (campus.vagas != null) contagem(campus.vagas!, 'vaga', 'vagas'),
                                  ].join(' · '),
                                  style: GJTypography.bodySm(),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Symbols.chevron_right, size: 20, color: GJColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );

    final programas = _secao('Como entrar e pagar', _Programas(programas: oferta.programas));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: GJRadius.borderXl,
        border: GJShadows.borderSubtle,
        boxShadow: GJShadows.sm,
      ),
      child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: Key('oferta-${oferta.cursoId}'),
        borderRadius: GJRadius.borderXl,
        onTap: () => context.go(destino),
        child: Padding(
          padding: const EdgeInsets.all(GJSpace.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMobile) ...[
                identificacao,
                const SizedBox(height: GJSpace.s5),
                campi,
                const SizedBox(height: GJSpace.s5),
                programas,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: identificacao),
                    const SizedBox(width: GJSpace.s6),
                    Expanded(flex: 4, child: campi),
                    const SizedBox(width: GJSpace.s6),
                    Expanded(flex: 4, child: programas),
                  ],
                ),
              const SizedBox(height: GJSpace.s4),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: GJSpace.s2,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/universidades/${universidade.id}'),
                    icon: const Icon(Symbols.account_balance, size: 18),
                    label: const Text('Ver universidade'),
                  ),
                  if (oferta.campus.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => context.go(destino),
                      icon: const Icon(Symbols.arrow_forward, size: 18),
                      label: const Text('Ver campus'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _dado(IconData icone, String rotulo, String valor) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 18, color: GJColors.primary),
          const SizedBox(width: GJSpace.s1),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$rotulo: ', style: GJTypography.bodySm()),
                  TextSpan(text: valor, style: GJTypography.label(color: GJColors.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _secao(String titulo, Widget conteudo) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo.toUpperCase(), style: GJTypography.caption().copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: GJSpace.s2),
          conteudo,
        ],
      );
}

/// Programas de entrada, financiamentos e bolsas que a universidade aceita
/// (as bolsas institucionais com o nome completo). A observação da
/// universidade sobre o programa aparece ao passar o mouse.
class _Programas extends StatelessWidget {
  const _Programas({required this.programas});

  final List<ProgramaTag> programas;

  static const _grupos = {
    'ENTRADA': 'Entrada',
    'FINANCIAMENTO': 'Financiamento',
    'BOLSA': 'Bolsas',
  };

  @override
  Widget build(BuildContext context) {
    if (programas.isEmpty) {
      return Text('A universidade ainda não informou os programas aceitos.', style: GJTypography.bodySm());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final grupo in _grupos.entries)
          if (programas.any((p) => p.tipo == grupo.key))
            Padding(
              padding: const EdgeInsets.only(bottom: GJSpace.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(grupo.value, style: GJTypography.caption()),
                  const SizedBox(height: GJSpace.s1),
                  Wrap(
                    spacing: GJSpace.s1,
                    runSpacing: GJSpace.s1,
                    children: [
                      for (final programa in programas.where((p) => p.tipo == grupo.key))
                        Tooltip(
                          message: programa.observacao ?? programa.nome,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => context.go('/programas/${programa.id}'),
                            child: GJTag(
                              label: programa.institucional ? programa.nome : (programa.sigla ?? programa.nome),
                              tone: tonePrograma(programa.tipo),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Cabeçalho do T06: texto à esquerda e a foto do curso (ou da área) à
/// direita, no mesmo arranjo do cabeçalho de programa. No celular, a foto
/// vem antes do texto.
class _CabecalhoCurso extends StatelessWidget {
  const _CabecalhoCurso({required this.imagem, required this.children});

  final String imagem;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final texto = Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    final foto = ClipRRect(
      borderRadius: GJRadius.borderXl,
      child: AspectRatio(aspectRatio: 16 / 10, child: GJRemoteOrAssetImage(url: imagem)),
    );

    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [foto, const SizedBox(height: GJSpace.s6), texto]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: texto),
        const SizedBox(width: GJSpace.s8),
        Expanded(flex: 2, child: foto),
      ],
    );
  }
}
