import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_breakpoints.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_empty_state.dart';
import '../../../shared/widgets/gj_skeleton.dart';
import '../../programas/data/programas_repository.dart';
import '../../programas/domain/programa.dart';
import '../data/cadastro_universidade_state.dart';
import 'widgets/cadastro_universidade_shell.dart';

const _grupos = [
  (tipo: 'ENTRADA', titulo: 'Programas de Entrada'),
  (tipo: 'BOLSA', titulo: 'Bolsas de Estudo'),
  (tipo: 'FINANCIAMENTO', titulo: 'Programas de Financiamento'),
];

/// T14 Cadastro de Universidade, passo 2 de 3: programas aceitos
/// (`/cadastro/universidade/programas`, Figura 29).
class CadastroUniversidadePasso2Page extends StatefulWidget {
  const CadastroUniversidadePasso2Page({super.key});

  @override
  State<CadastroUniversidadePasso2Page> createState() => _CadastroUniversidadePasso2PageState();
}

class _CadastroUniversidadePasso2PageState extends State<CadastroUniversidadePasso2Page> {
  late Future<List<ProgramaResumo>> _future;
  late Set<int> _selecionados;

  @override
  void initState() {
    super.initState();
    _selecionados = {...cadastroUniversidadeState.programasIds};
    _future = programasRepository.listar(const FiltrosProgramas()).then((r) => r.data);
  }

  void _avancar() {
    cadastroUniversidadeState.programasIds = _selecionados;
    context.go('/cadastro/universidade/campus');
  }

  void _voltar() {
    cadastroUniversidadeState.programasIds = _selecionados;
    context.go('/cadastro/universidade/dados');
  }

  @override
  Widget build(BuildContext context) {
    return CadastroUniversidadeShell(
      passoAtual: 2,
      titulo: 'Adicione os programas de entrada aceitos por sua instituição!',
      aoVoltar: _voltar,
      aoAvancar: _avancar,
      rotuloAvancar: 'Próximo',
      child: FutureBuilder<List<ProgramaResumo>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const GJSkeleton(height: 220);
          }
          if (snapshot.hasError) {
            return GJEmptyState(
              titulo: 'Não foi possível carregar os programas',
              texto: snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Tente novamente.',
              icone: Symbols.wifi_off,
              acaoLabel: 'Tentar novamente',
              onAcao: () => setState(() {
                _future = programasRepository.listar(const FiltrosProgramas()).then((r) => r.data);
              }),
            );
          }

          final programas = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final grupo in _grupos) ...[
                _secaoGrupo(grupo.titulo, programas.where((p) => p.tipo == grupo.tipo).toList()),
                const SizedBox(height: GJSpace.s5),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _secaoGrupo(String titulo, List<ProgramaResumo> programas) {
    if (programas.isEmpty) return const SizedBox.shrink();

    final isMobile = GJBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo.toUpperCase(), style: GJTypography.caption().copyWith(fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: GJSpace.s3),
        Wrap(
          spacing: GJSpace.s4,
          runSpacing: GJSpace.s4,
          children: [
            for (final programa in programas)
              SizedBox(
                width: isMobile ? double.infinity : 260,
                child: _CardPrograma(
                  programa: programa,
                  selecionado: _selecionados.contains(programa.id),
                  onTap: () => setState(() {
                    if (_selecionados.contains(programa.id)) {
                      _selecionados.remove(programa.id);
                    } else {
                      _selecionados.add(programa.id);
                    }
                  }),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CardPrograma extends StatelessWidget {
  const _CardPrograma({required this.programa, required this.selecionado, required this.onTap});

  final ProgramaResumo programa;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(GJSpace.s4),
        decoration: BoxDecoration(
          color: selecionado ? GJColors.primaryFixed : GJColors.surfaceLow,
          borderRadius: GJRadius.borderLg,
          border: Border.all(color: selecionado ? GJColors.primary : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selecionado ? GJColors.primary : null,
                borderRadius: BorderRadius.circular(6),
                border: selecionado ? null : Border.all(color: GJColors.border, width: 2),
              ),
              child: selecionado ? const Icon(Symbols.check, size: 18, color: GJColors.primaryOn) : null,
            ),
            const SizedBox(width: GJSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(programa.sigla ?? programa.nome, style: GJTypography.h4()),
                  Text(programa.nome, style: GJTypography.caption(), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
