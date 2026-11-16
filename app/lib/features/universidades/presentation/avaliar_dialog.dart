import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/gj_colors.dart';
import '../../../core/theme/gj_radius.dart';
import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/widgets/gj_button.dart';
import '../data/universidades_repository.dart';
import '../domain/avaliacao.dart';

/// T03a: modal de avaliação (RF02). Sem [avaliacaoAtual], cria a avaliação
/// do aluno; com ela, abre preenchido e edita. Retorna a avaliação gravada
/// (com a média recalculada) ou null se o aluno fechou sem enviar.
Future<AvaliacaoGravada?> mostrarModalAvaliar(
  BuildContext context, {
  required int universidadeId,
  required String nomeUniversidade,
  MinhaAvaliacao? avaliacaoAtual,
}) {
  return showDialog<AvaliacaoGravada>(
    context: context,
    builder: (context) => _AvaliarDialog(
      universidadeId: universidadeId,
      nomeUniversidade: nomeUniversidade,
      avaliacaoAtual: avaliacaoAtual,
    ),
  );
}

class _AvaliarDialog extends StatefulWidget {
  const _AvaliarDialog({required this.universidadeId, required this.nomeUniversidade, this.avaliacaoAtual});

  final int universidadeId;
  final String nomeUniversidade;
  final MinhaAvaliacao? avaliacaoAtual;

  @override
  State<_AvaliarDialog> createState() => _AvaliarDialogState();
}

class _AvaliarDialogState extends State<_AvaliarDialog> {
  late int _nota = widget.avaliacaoAtual?.nota ?? 0;
  late final _comentarioController = TextEditingController(text: widget.avaliacaoAtual?.comentario ?? '');
  bool _enviando = false;
  String? _erro;

  bool get _editando => widget.avaliacaoAtual != null;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });

    final comentario = _comentarioController.text.trim();
    try {
      final gravada = _editando
          ? await universidadesRepository.editarAvaliacao(
              widget.avaliacaoAtual!.id,
              nota: _nota,
              comentario: comentario.isEmpty ? null : comentario,
            )
          : await universidadesRepository.avaliar(
              widget.universidadeId,
              nota: _nota,
              comentario: comentario.isEmpty ? null : comentario,
            );
      if (!mounted) return;
      Navigator.of(context).pop(gravada);
    } on ApiException catch (erro) {
      if (mounted) setState(() => _erro = erro.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
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
                    child: Text(
                      _editando
                          ? 'Editar sua avaliação da ${widget.nomeUniversidade}'
                          : 'Como foi sua experiência com a ${widget.nomeUniversidade}?',
                      style: GJTypography.h4(),
                    ),
                  ),
                  GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Icon(Symbols.close)),
                ],
              ),
              const SizedBox(height: GJSpace.s4),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      tooltip: '$i ${i == 1 ? 'estrela' : 'estrelas'}',
                      onPressed: _enviando ? null : () => setState(() => _nota = i),
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
                enabled: !_enviando,
                maxLength: 500,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: GJColors.surfaceLow,
                  border: OutlineInputBorder(borderRadius: GJRadius.borderMd, borderSide: BorderSide.none),
                  hintText: 'Conte para outros estudantes...',
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: GJSpace.s2),
                Text(_erro!, style: GJTypography.label(color: GJColors.error)),
              ],
              const SizedBox(height: GJSpace.s2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GJButton(label: 'Cancelar', variant: GJButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: GJSpace.s3),
                  GJButton(
                    label: _editando ? 'Salvar alterações' : 'Enviar avaliação',
                    onPressed: _nota == 0 || _enviando ? null : _enviar,
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
