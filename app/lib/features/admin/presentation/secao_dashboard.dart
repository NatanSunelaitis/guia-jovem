import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_bar_chart.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../../shared/widgets/gj_tabs.dart';
import '../data/cadastros_repository.dart';
import '../domain/dashboard.dart';

/// Períodos do seletor do protótipo (T24.1).
enum PeriodoDashboard {
  seteDias('7 dias', dias: 7, agrupar: 'dia'),
  trintaDias('30 dias', dias: 30, agrupar: 'dia'),
  dozeMeses('12 meses', dias: 0, agrupar: 'mes');

  const PeriodoDashboard(this.rotulo, {required this.dias, required this.agrupar});

  final String rotulo;
  final int dias;
  final String agrupar;
}

String _iso(DateTime data) =>
    '${data.year.toString().padLeft(4, '0')}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

/// Intervalo (AAAA-MM-DD) do período até hoje. 12 meses: do primeiro dia do
/// mês, 11 meses atrás, até hoje (12 barras).
({String de, String ate}) intervaloDoPeriodo(PeriodoDashboard periodo, DateTime hoje) {
  final fim = DateTime(hoje.year, hoje.month, hoje.day);
  final inicio = periodo == PeriodoDashboard.dozeMeses
      ? DateTime(fim.year, fim.month - 11, 1)
      : fim.subtract(Duration(days: periodo.dias - 1));
  return (de: _iso(inicio), ate: _iso(fim));
}

/// T24.1 Dashboard (RF16, Quadro 21): totais por perfil, universidades por
/// status, cursos e programas; visitas e logins únicos por período; e os
/// mais acessados. Tela inicial do painel do administrador.
class SecaoDashboard extends StatefulWidget {
  const SecaoDashboard({super.key, this.agora});

  /// Para os testes fixarem "hoje".
  final DateTime Function()? agora;

  @override
  State<SecaoDashboard> createState() => _SecaoDashboardState();
}

class _SecaoDashboardState extends State<SecaoDashboard> {
  PeriodoDashboard _periodo = PeriodoDashboard.trintaDias;
  int _abaRanking = 0;

  late Future<ResumoDashboard> _resumo;
  late Future<(AcessosPeriodo, RankingDashboard)> _doPeriodo;

  @override
  void initState() {
    super.initState();
    _resumo = cadastrosRepository.resumo();
    _doPeriodo = _carregarPeriodo();
  }

  Future<(AcessosPeriodo, RankingDashboard)> _carregarPeriodo() async {
    final intervalo = intervaloDoPeriodo(_periodo, (widget.agora ?? DateTime.now)());
    final resultados = await Future.wait<Object>([
      cadastrosRepository.acessos(de: intervalo.de, ate: intervalo.ate, agrupar: _periodo.agrupar),
      cadastrosRepository.ranking(de: intervalo.de, ate: intervalo.ate),
    ]);
    return (resultados[0] as AcessosPeriodo, resultados[1] as RankingDashboard);
  }

  void _trocarPeriodo(PeriodoDashboard periodo) {
    if (periodo == _periodo) return;
    setState(() {
      _periodo = periodo;
      _doPeriodo = _carregarPeriodo();
    });
  }

  void _recarregarTudo() {
    setState(() {
      _resumo = cadastrosRepository.resumo();
      _doPeriodo = _carregarPeriodo();
    });
  }

  Widget _erro(Object? erro) => GJEmptyState(
        titulo: 'Não foi possível carregar o dashboard',
        texto: erro is ApiException ? erro.message : null,
        icone: Symbols.wifi_off,
        acaoLabel: 'Tentar novamente',
        onAcao: _recarregarTudo,
      );

  Widget _cartao({
    required IconData icone,
    required String rotulo,
    required int valor,
    required String nota,
    Color cor = GJColors.primary,
    VoidCallback? onTap,
  }) {
    final conteudo = Container(
      width: 220,
      padding: const EdgeInsets.all(GJSpace.s5),
      decoration: BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: GJRadius.borderLg,
        border: Border.all(color: GJColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 20),
              const SizedBox(width: GJSpace.s2),
              Expanded(child: Text(rotulo, style: GJTypography.label(), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: GJSpace.s3),
          Text('$valor', style: GJTypography.h2().copyWith(color: cor)),
          const SizedBox(height: GJSpace.s1),
          Text(nota, style: GJTypography.caption()),
        ],
      ),
    );
    if (onTap == null) return conteudo;
    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: onTap, child: conteudo));
  }

  Widget _cartoesResumo() {
    return FutureBuilder<ResumoDashboard>(
      future: _resumo,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _erro(snapshot.error);
        if (!snapshot.hasData) {
          return Wrap(
            spacing: GJSpace.s4,
            runSpacing: GJSpace.s4,
            children: [for (var i = 0; i < 5; i++) const SizedBox(width: 220, child: GJSkeleton(height: 120))],
          );
        }
        final r = snapshot.data!;
        return Wrap(
          spacing: GJSpace.s4,
          runSpacing: GJSpace.s4,
          children: [
            _cartao(
              icone: Symbols.group,
              rotulo: 'Usuários',
              valor: r.usuarios,
              nota: '${r.alunos} alunos, ${r.contasUniversidade} universidades, ${r.administradores} administradores',
            ),
            _cartao(
              icone: Symbols.verified,
              rotulo: 'Universidades aprovadas',
              valor: r.universidadesAprovadas,
              nota: '${r.universidadesReprovadas} reprovadas, ${r.universidadesInativas} inativas',
              cor: GJColors.success,
            ),
            _cartao(
              icone: Symbols.pending,
              rotulo: 'Pendentes',
              valor: r.universidadesPendentes,
              nota: 'aguardando análise',
              cor: GJColors.warning,
              onTap: () => context.go('/admin/universidades'),
            ),
            _cartao(icone: Symbols.menu_book, rotulo: 'Cursos', valor: r.cursos, nota: 'cadastrados e ativos'),
            _cartao(
              icone: Symbols.school,
              rotulo: 'Programas',
              valor: r.programas,
              nota: '${r.programasEntrada} entrada, ${r.programasFinanciamento} financiamento, ${r.programasBolsa} bolsa',
            ),
          ],
        );
      },
    );
  }

  Widget _painel({required String titulo, required Widget child, Widget? acao}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s6),
      decoration: BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: GJRadius.borderLg,
        border: Border.all(color: GJColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text(titulo, style: GJTypography.h4())), if (acao != null) acao]),
          const SizedBox(height: GJSpace.s4),
          child,
        ],
      ),
    );
  }

  Widget _seletorPeriodo() {
    return Wrap(
      spacing: GJSpace.s2,
      children: [
        for (final periodo in PeriodoDashboard.values)
          ChoiceChip(
            label: Text(periodo.rotulo),
            selected: periodo == _periodo,
            onSelected: (_) => _trocarPeriodo(periodo),
          ),
      ],
    );
  }

  Widget _ranking(RankingDashboard ranking) {
    final listas = [ranking.universidades, ranking.programas, ranking.cursos];
    final itens = listas[_abaRanking];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GJTabs(
          tabs: const [GJTabItem(label: 'Universidades'), GJTabItem(label: 'Programas'), GJTabItem(label: 'Cursos')],
          selectedIndex: _abaRanking,
          onChanged: (indice) => setState(() => _abaRanking = indice),
        ),
        const SizedBox(height: GJSpace.s3),
        if (itens.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: GJSpace.s4),
            child: Text('Nenhum acesso no período.', style: GJTypography.bodySm()),
          )
        else
          for (var i = 0; i < itens.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: GJSpace.s2),
              child: Row(
                children: [
                  SizedBox(width: GJSpace.s8, child: Text('${i + 1}', style: GJTypography.label(color: GJColors.primary))),
                  Expanded(child: Text(itens[i].nome, style: GJTypography.body(), overflow: TextOverflow.ellipsis)),
                  Text('${itens[i].visitas} visitas', style: GJTypography.bodySm()),
                ],
              ),
            ),
      ],
    );
  }

  Widget _doPeriodoCarregado() {
    return FutureBuilder<(AcessosPeriodo, RankingDashboard)>(
      future: _doPeriodo,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _erro(snapshot.error);
        if (snapshot.connectionState != ConnectionState.done) {
          return const GJSkeleton(height: 360);
        }
        final (acessos, ranking) = snapshot.data!;
        final unidade = _periodo.agrupar == 'mes' ? 'mês' : 'dia';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: GJSpace.s4,
              runSpacing: GJSpace.s4,
              children: [
                _cartao(
                  icone: Symbols.visibility,
                  rotulo: 'Visitas no período',
                  valor: acessos.totalVisitas,
                  nota: 'páginas abertas nos últimos ${_periodo.rotulo}',
                ),
                _cartao(
                  icone: Symbols.login,
                  rotulo: 'Logins únicos',
                  valor: acessos.loginsUnicos,
                  nota: 'contas que entraram nos últimos ${_periodo.rotulo}',
                ),
              ],
            ),
            const SizedBox(height: GJSpace.s6),
            _painel(
              titulo: 'Visitas por $unidade',
              child: GJBarChart(
                barras: [for (final p in acessos.serie) GJBarra(rotulo: p.rotulo, valor: p.visitas)],
              ),
            ),
            const SizedBox(height: GJSpace.s6),
            _painel(
              titulo: 'Logins únicos por $unidade',
              child: GJBarChart(
                cor: GJColors.secondary,
                descricaoValor: 'contas',
                barras: [for (final p in acessos.serie) GJBarra(rotulo: p.rotulo, valor: p.loginsUnicos)],
              ),
            ),
            const SizedBox(height: GJSpace.s6),
            _painel(titulo: 'Mais visitados', child: _ranking(ranking)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Dashboard', style: GJTypography.h2()),
        const SizedBox(height: GJSpace.s4),
        _cartoesResumo(),
        const SizedBox(height: GJSpace.s8),
        Wrap(
          spacing: GJSpace.s4,
          runSpacing: GJSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [Text('Período', style: GJTypography.label()), _seletorPeriodo()],
        ),
        const SizedBox(height: GJSpace.s4),
        _doPeriodoCarregado(),
      ],
    );
  }
}
