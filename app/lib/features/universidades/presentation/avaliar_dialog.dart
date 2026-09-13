import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_button.dart';

/// T03a: modal de avaliação (RF02). O envio ainda não persiste: o POST
/// /universidades/:id/avaliacoes é RF02/Fase 4, que ainda não existe, e
/// não há sessão de usuário na Fase 2 do frontend (ver docs/DECISOES.md).
Future<void> mostrarModalAvaliar(BuildContext context, {required String nomeUniversidade}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AvaliarDialog(nomeUniversidade: nomeUniversidade),
  );
}

class _AvaliarDialog extends StatefulWidget {
  const _AvaliarDialog({required this.nomeUniversidade});

  final String nomeUniversidade;

  @override
  State<_AvaliarDialog> createState() => _AvaliarDialogState();
}

class _AvaliarDialogState extends State<_AvaliarDialog> {
  int _nota = 0;
  final _comentarioController = TextEditingController();

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(GJSpace.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Como foi sua experiência com a ${widget.nomeUniversidade}?', style: GJTypography.h4()),
                  ),
                  GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Icon(Symbols.close)),
                ],
              ),
              const SizedBox(height: GJSpace.s4),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => _nota = i),
                      icon: Icon(
                        Symbols.star,
                        fill: i <= _nota ? 1 : 0,
                        color: i <= _nota ? GJColors.rating : GJColors.border,
                        size: 32,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: GJSpace.s2),
              TextField(
                controller: _comentarioController,
                maxLength: 500,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: GJColors.surfaceLow,
                  border: OutlineInputBorder(borderRadius: GJRadius.borderMd, borderSide: BorderSide.none),
                  hintText: 'Conte para outros estudantes...',
                ),
              ),
              const SizedBox(height: GJSpace.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GJButton(label: 'Cancelar', variant: GJButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: GJSpace.s3),
                  GJButton(
                    label: 'Enviar avaliação',
                    onPressed: _nota == 0
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Avaliações chegam em uma próxima fase do app.')),
                            );
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
