import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/gj_radius.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../core/theme/gj_typography.dart';
import '../../../../shared/widgets/gj_button.dart';
import '../../../../shared/widgets/gj_input.dart';
import '../../data/session_controller.dart';

/// T22 Excluir Conta (diálogo, Figura 36): confirmação digitando "EXCLUIR".
/// [aviso] explica o efeito para o perfil (ex.: a universidade fica inativa).
Future<void> mostrarDialogoExcluirConta(BuildContext context, {String? aviso}) {
  return showDialog<void>(context: context, builder: (context) => _ExcluirContaDialog(aviso: aviso));
}

class _ExcluirContaDialog extends StatefulWidget {
  const _ExcluirContaDialog({this.aviso});

  final String? aviso;

  @override
  State<_ExcluirContaDialog> createState() => _ExcluirContaDialogState();
}

class _ExcluirContaDialogState extends State<_ExcluirContaDialog> {
  final _confirmacaoController = TextEditingController();
  String? _erro;
  bool _excluindo = false;

  @override
  void dispose() {
    _confirmacaoController.dispose();
    super.dispose();
  }

  bool get _confirmacaoValida => _confirmacaoController.text.trim().toUpperCase() == 'EXCLUIR';

  Future<void> _excluir() async {
    if (!_confirmacaoValida) {
      setState(() => _erro = 'Digite EXCLUIR para confirmar');
      return;
    }
    setState(() {
      _erro = null;
      _excluindo = true;
    });
    try {
      await sessionController.excluirConta();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (erro) {
      setState(() => _erro = erro.message);
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderXl),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(GJSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirmação', style: GJTypography.h2(size: 22)),
            const SizedBox(height: GJSpace.s3),
            Text(
              'Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita.',
              style: GJTypography.body(),
            ),
            if (widget.aviso != null) ...[
              const SizedBox(height: GJSpace.s2),
              Text(widget.aviso!, style: GJTypography.bodySm()),
            ],
            const SizedBox(height: GJSpace.s4),
            GJInput(
              label: 'Digite EXCLUIR para confirmar',
              controller: _confirmacaoController,
              errorText: _erro,
            ),
            const SizedBox(height: GJSpace.s5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                const SizedBox(width: GJSpace.s3),
                GJButton(
                  label: 'Excluir',
                  variant: GJButtonVariant.danger,
                  loading: _excluindo,
                  onPressed: _excluindo ? null : _excluir,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// RF08: confirmação antes de encerrar a sessão.
Future<void> mostrarDialogoDesligar(BuildContext context) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderLg),
      title: const Text('Sair da conta'),
      content: const Text('Tem certeza que deseja sair da sua conta?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        GJButton(label: 'Sair', variant: GJButtonVariant.danger, onPressed: () => Navigator.of(context).pop(true)),
      ],
    ),
  );

  if (confirmou == true) {
    await sessionController.logout();
  }
}
