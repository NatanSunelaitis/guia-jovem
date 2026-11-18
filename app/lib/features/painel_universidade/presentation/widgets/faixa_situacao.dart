import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_radius.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/utils/formatar_data.dart';
import '../../../../shared/widgets/gj_button.dart';
import '../../../admin/domain/universidade_admin.dart';
import '../../../admin/presentation/widgets/confirmacao_dialogs.dart';

/// Faixa de situação no topo do painel (T23.1b): pendente, aprovada (com o
/// link para a página pública), reprovada (com o motivo e "Reenviar para
/// análise") ou inativa.
class FaixaSituacao extends StatelessWidget {
  const FaixaSituacao({super.key, required this.cadastro, required this.onReenviar, this.reenviando = false});

  final UniversidadeCadastro cadastro;

  /// Chamado depois da confirmação do reenvio.
  final Future<void> Function() onReenviar;
  final bool reenviando;

  ({IconData icone, Color cor, Color fundo, String titulo, String texto}) _situacao() {
    final nome = cadastro.nomeFantasia;
    return switch (cadastro.status) {
      StatusUniversidade.pendente => (
          icone: Symbols.hourglass_top,
          cor: GJColors.warning,
          fundo: GJColors.warningContainer,
          titulo: 'Cadastro em análise',
          texto: 'A equipe Guia Jovem está analisando o cadastro de $nome, enviado em '
              '${formatarData(cadastro.criadoEm)}. A análise leva até 15 dias. Enquanto isso, a página da '
              'universidade não aparece no site, mas você já pode completar os dados, os campi, os cursos, os '
              'programas aceitos e as bolsas.',
        ),
      StatusUniversidade.reprovada => (
          icone: Symbols.cancel,
          cor: GJColors.errorOnContainer,
          fundo: GJColors.errorContainer,
          titulo: 'Cadastro reprovado',
          texto: 'O cadastro de $nome não foi aprovado e a página não aparece no site. Corrija os dados da '
              'instituição e dos campi e reenvie o cadastro para análise. Cursos, ofertas, programas e bolsas '
              'ficam bloqueados até a aprovação.',
        ),
      StatusUniversidade.inativa => (
          icone: Symbols.visibility_off,
          cor: GJColors.textSecondary,
          fundo: GJColors.surface,
          titulo: 'Universidade inativa',
          texto: '$nome está inativa e fora do site. Os dados ficam disponíveis só para leitura. Em caso de '
              'dúvida, entre em contato com a equipe Guia Jovem.',
        ),
      StatusUniversidade.aprovada => (
          icone: Symbols.verified,
          cor: GJColors.success,
          fundo: GJColors.successContainer,
          titulo: 'Página publicada',
          texto: '$nome está aprovada e aparece na pesquisa do Guia Jovem'
              '${cadastro.aprovadoEm == null ? '' : ' desde ${formatarData(cadastro.aprovadoEm!)}'}. '
              'As alterações feitas aqui valem na hora.',
        ),
    };
  }

  Future<void> _confirmarReenvio(BuildContext context) async {
    final confirmou = await confirmarAcao(
      context,
      titulo: 'Reenviar para análise',
      texto: 'O cadastro de ${cadastro.nomeFantasia} volta para a fila de análise da equipe Guia Jovem, que recebe '
          'uma notificação. Confira se os dados da instituição e dos campi já estão corrigidos.',
      rotuloConfirmar: 'Reenviar',
    );
    if (confirmou) await onReenviar();
  }

  @override
  Widget build(BuildContext context) {
    final situacao = _situacao();
    return Container(
      key: const Key('faixa-situacao'),
      width: double.infinity,
      padding: const EdgeInsets.all(GJSpace.s6),
      decoration: BoxDecoration(color: situacao.fundo, borderRadius: GJRadius.borderLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(situacao.icone, color: situacao.cor, size: 28),
          const SizedBox(width: GJSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: GJSpace.s3,
                  runSpacing: GJSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(situacao.titulo, style: GJTypography.h4()),
                    badgeStatusUniversidade(cadastro.status),
                  ],
                ),
                const SizedBox(height: GJSpace.s2),
                Text(situacao.texto, style: GJTypography.body()),
                if (cadastro.status == StatusUniversidade.reprovada) ...[
                  const SizedBox(height: GJSpace.s3),
                  Text('Motivo informado pela equipe', style: GJTypography.label()),
                  const SizedBox(height: GJSpace.s1),
                  SelectableText(
                    cadastro.motivoReprovacao ?? 'Motivo não informado.',
                    style: GJTypography.body().copyWith(color: GJColors.errorOnContainer),
                  ),
                  const SizedBox(height: GJSpace.s4),
                  GJButton(
                    label: 'Reenviar para análise',
                    icon: Symbols.send,
                    size: GJButtonSize.sm,
                    loading: reenviando,
                    onPressed: reenviando ? null : () => _confirmarReenvio(context),
                  ),
                ],
                if (cadastro.status == StatusUniversidade.aprovada) ...[
                  const SizedBox(height: GJSpace.s4),
                  GJButton(
                    label: 'Ver página pública',
                    icon: Symbols.open_in_new,
                    variant: GJButtonVariant.secondary,
                    size: GJButtonSize.sm,
                    onPressed: () => context.go('/universidades/${cadastro.id}'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso das seções em modo leitura (reprovada ou inativa).
class AvisoSomenteLeitura extends StatelessWidget {
  const AvisoSomenteLeitura(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('aviso-somente-leitura'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: GJSpace.s4),
      padding: const EdgeInsets.all(GJSpace.s4),
      decoration: BoxDecoration(color: GJColors.surface, borderRadius: GJRadius.borderMd),
      child: Row(
        children: [
          const Icon(Symbols.lock, color: GJColors.textSecondary),
          const SizedBox(width: GJSpace.s3),
          Expanded(child: Text(texto, style: GJTypography.bodySm())),
        ],
      ),
    );
  }
}

/// Título e subtítulo de uma seção do painel.
class CabecalhoSecao extends StatelessWidget {
  const CabecalhoSecao({super.key, required this.titulo, this.subtitulo, this.acao});

  final String titulo;
  final String? subtitulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GJSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: GJTypography.h2()),
                if (subtitulo != null) ...[
                  const SizedBox(height: GJSpace.s2),
                  Text(subtitulo!, style: GJTypography.body()),
                ],
              ],
            ),
          ),
          if (acao != null) ...[const SizedBox(width: GJSpace.s4), acao!],
        ],
      ),
    );
  }
}
