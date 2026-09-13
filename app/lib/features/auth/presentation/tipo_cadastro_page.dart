import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gj_breakpoints.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_button.dart';

/// T10 Escolha do tipo de cadastro (`/cadastro`, Figura 23). No desktop é um
/// modal centralizado; no mobile, uma folha inferior (bottom sheet).
class TipoCadastroPage extends StatelessWidget {
  const TipoCadastroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = GJBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: const Color.fromRGBO(26, 28, 28, 0.4),
      body: SafeArea(
        child: isMobile
            ? Align(
                alignment: Alignment.bottomCenter,
                // maxHeight: numa tela baixa, as duas opções (estudante e
                // instituição) inteiras não cabem sem rolar; sem limite de
                // altura + scroll aqui, a folha inferior estoura por baixo
                // (RenderFlex overflow) em vez de rolar.
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
                  child: _FolhaMobile(),
                ),
              )
            : Center(child: SingleChildScrollView(child: _ModalDesktop())),
      ),
    );
  }
}

class _ModalDesktop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      margin: const EdgeInsets.symmetric(vertical: GJSpace.s16),
      padding: const EdgeInsets.all(GJSpace.s8),
      decoration: BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: GJRadius.borderXl,
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 30, offset: Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Symbols.close),
              onPressed: () => context.go('/login'),
            ),
          ),
          Text(
            'Qual tipo de cadastro gostaria de fazer?',
            style: GJTypography.h2(size: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GJSpace.s6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _OpcaoCadastro(
                  icone: Symbols.person,
                  titulo: 'Sou estudante',
                  descricao:
                      'Pesquise universidades, salve suas favoritas, avalie faculdades e acompanhe os prazos dos programas de entrada.',
                  rotuloBotao: 'Aluno',
                  variantePrimaria: true,
                  onTap: () => context.go('/cadastro/aluno'),
                ),
              ),
              const SizedBox(width: GJSpace.s6),
              Expanded(
                child: _OpcaoCadastro(
                  icone: Symbols.account_balance,
                  titulo: 'Represento uma instituição',
                  descricao:
                      'Cadastre sua universidade, mantenha cursos e campus atualizados e acompanhe as avaliações dos estudantes.',
                  rotuloBotao: 'Universidade',
                  variantePrimaria: false,
                  onTap: () => context.go('/cadastro/universidade'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FolhaMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(GJSpace.s4, GJSpace.s3, GJSpace.s4, GJSpace.s6),
      decoration: const BoxDecoration(
        color: GJColors.surfaceLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: GJColors.surfaceDim, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: GJSpace.s5),
            Text('Qual tipo de cadastro gostaria de fazer?', style: GJTypography.h2(size: 22), textAlign: TextAlign.center),
            const SizedBox(height: GJSpace.s4),
            _OpcaoCadastro(
              icone: Symbols.person,
              titulo: 'Sou estudante',
              descricao: 'Pesquise universidades, salve suas favoritas, avalie faculdades e acompanhe os prazos.',
              rotuloBotao: 'Aluno',
              variantePrimaria: true,
              onTap: () => context.go('/cadastro/aluno'),
            ),
            const SizedBox(height: GJSpace.s3),
            _OpcaoCadastro(
              icone: Symbols.account_balance,
              titulo: 'Represento uma instituição',
              descricao: 'Cadastre sua universidade, mantenha cursos e campus atualizados e acompanhe as avaliações.',
              rotuloBotao: 'Universidade',
              variantePrimaria: false,
              onTap: () => context.go('/cadastro/universidade'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcaoCadastro extends StatelessWidget {
  const _OpcaoCadastro({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.rotuloBotao,
    required this.variantePrimaria,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final String rotuloBotao;
  final bool variantePrimaria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GJSpace.s6),
      decoration: BoxDecoration(color: GJColors.surfaceLow, borderRadius: GJRadius.borderLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: GJColors.primaryFixed, shape: BoxShape.circle),
            child: Icon(icone, size: 32, color: GJColors.primary),
          ),
          const SizedBox(height: GJSpace.s3),
          Text(titulo, style: GJTypography.h3(size: 20), textAlign: TextAlign.center),
          const SizedBox(height: GJSpace.s2),
          Text(descricao, style: GJTypography.bodySm(), textAlign: TextAlign.center),
          const SizedBox(height: GJSpace.s4),
          GJButton(
            label: rotuloBotao,
            expand: true,
            variant: variantePrimaria ? GJButtonVariant.primary : GJButtonVariant.secondary,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
