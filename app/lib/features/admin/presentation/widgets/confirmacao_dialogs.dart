import 'package:flutter/material.dart';

import '../../../../core/theme/gj_colors.dart';
import '../../../../core/theme/gj_radius.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/widgets/gj_button.dart';
import '../../../../shared/widgets/gj_status_badge.dart';
import '../../domain/universidade_admin.dart';

/// Status da universidade no badge do design system (seção 3.19).
Widget badgeStatusUniversidade(StatusUniversidade status) {
  final tom = switch (status) {
    StatusUniversidade.pendente => GJStatusTone.warning,
    StatusUniversidade.aprovada => GJStatusTone.success,
    StatusUniversidade.reprovada => GJStatusTone.error,
    StatusUniversidade.inativa => GJStatusTone.neutral,
  };
  return GJStatusBadge(label: rotuloStatusUniversidade(status), tone: tom);
}

/// Célula de tabela com tag, badge ou botão: em colunas estreitas (telas
/// menores), encolhe o conteúdo em vez de estourar a linha.
Widget encolherSePreciso(Widget conteudo) =>
    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: conteudo);

/// Confirmação antes de uma ação do administrador. Devolve true se confirmou.
Future<bool> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String rotuloConfirmar,
  bool destrutiva = false,
}) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderLg),
      title: Text(titulo),
      content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Text(texto)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        GJButton(
          label: rotuloConfirmar,
          variant: destrutiva ? GJButtonVariant.danger : GJButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return confirmou == true;
}

/// Aviso de ação bloqueada por regra de negócio (ex.: única conta de
/// administrador ativa), com a mensagem que a API devolveu.
Future<void> mostrarAcaoBloqueada(BuildContext context, String mensagem) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderLg),
      title: const Text('Ação não permitida'),
      content: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Text(mensagem)),
      actions: [
        GJButton(label: 'Entendi', onPressed: () => Navigator.of(context).pop()),
      ],
    ),
  );
}

/// Diálogo "Reprovar cadastro" (T24.3): o motivo é obrigatório e vai para a
/// universidade por notificação e e-mail. Devolve o motivo, ou null se cancelou.
Future<String?> pedirMotivoReprovacao(BuildContext context, {required String nomeUniversidade}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _MotivoReprovacaoDialog(nomeUniversidade: nomeUniversidade),
  );
}

class _MotivoReprovacaoDialog extends StatefulWidget {
  const _MotivoReprovacaoDialog({required this.nomeUniversidade});

  final String nomeUniversidade;

  @override
  State<_MotivoReprovacaoDialog> createState() => _MotivoReprovacaoDialogState();
}

class _MotivoReprovacaoDialogState extends State<_MotivoReprovacaoDialog> {
  final _motivoController = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final motivo = _motivoController.text.trim();
    if (motivo.isEmpty) {
      setState(() => _erro = 'Informe o motivo da reprovação');
      return;
    }
    Navigator.of(context).pop(motivo);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderXl),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(GJSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reprovar cadastro', style: GJTypography.h2(size: 22)),
            const SizedBox(height: GJSpace.s3),
            Text(
              '${widget.nomeUniversidade} recebe o motivo por notificação e por e-mail.',
              style: GJTypography.body(),
            ),
            const SizedBox(height: GJSpace.s4),
            TextField(
              key: const Key('motivo-reprovacao'),
              controller: _motivoController,
              autofocus: true,
              maxLength: 500,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Motivo',
                filled: true,
                fillColor: GJColors.surfaceLow,
                border: OutlineInputBorder(borderRadius: GJRadius.borderMd, borderSide: BorderSide.none),
                errorText: _erro,
              ),
            ),
            const SizedBox(height: GJSpace.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                const SizedBox(width: GJSpace.s3),
                GJButton(label: 'Reprovar', variant: GJButtonVariant.danger, onPressed: _confirmar),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
