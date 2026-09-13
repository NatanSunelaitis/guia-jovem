import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

/// Indicador de etapas (seção 3.9), usado nos fluxos de cadastro em passos.
class GJStepper extends StatelessWidget {
  const GJStepper({super.key, required this.labels, required this.currentIndex});

  final List<String> labels;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          _Step(label: labels[i], status: _statusOf(i), numero: i + 1),
          if (i < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: i < currentIndex ? GJColors.primary : GJColors.border,
              ),
            ),
        ],
      ],
    );
  }

  _StepStatus _statusOf(int index) {
    if (index < currentIndex) return _StepStatus.done;
    if (index == currentIndex) return _StepStatus.current;
    return _StepStatus.future;
  }
}

enum _StepStatus { done, current, future }

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.status, required this.numero});

  final String label;
  final _StepStatus status;
  final int numero;

  @override
  Widget build(BuildContext context) {
    final circle = switch (status) {
      _StepStatus.done => Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: GJColors.primary, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Symbols.check, size: 18, color: GJColors.primaryOn),
        ),
      _StepStatus.current => Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: GJColors.primary, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '$numero',
            style: GJTypography.label(color: GJColors.primary).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      _StepStatus.future => Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: GJColors.border, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '$numero',
            style: GJTypography.label(color: GJColors.textDisabled).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
    };

    final labelColor = status == _StepStatus.future ? GJColors.textDisabled : GJColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        const SizedBox(height: GJSpace.s2),
        Text(label, style: GJTypography.caption(color: labelColor).copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
