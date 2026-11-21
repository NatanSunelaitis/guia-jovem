import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/gj_spacing.dart';
import '../../../../shared/widgets/gj_button.dart';
import '../../../../shared/widgets/gj_empty_state.dart';
import '../../../sugestoes/data/sugestoes_repository.dart';
import '../../../sugestoes/domain/sugestao.dart';
import '../../../sugestoes/presentation/nova_sugestao_dialog.dart';
import '../../../sugestoes/presentation/widgets/sugestao_card.dart';
import 'secao_carregavel.dart';
import '../../../../shared/widgets/gj_aviso.dart';

/// T18 Histórico de sugestões (Figura 25): título, data, destino, status
/// colorido e a resposta com a data da avaliação. "Nova sugestão" abre T20.
class HistoricoSugestoesSecao extends StatefulWidget {
  const HistoricoSugestoesSecao({super.key});

  @override
  State<HistoricoSugestoesSecao> createState() => _HistoricoSugestoesSecaoState();
}

class _HistoricoSugestoesSecaoState extends State<HistoricoSugestoesSecao> {
  late Future<List<Sugestao>> _future = sugestoesRepository.minhas();

  void _recarregar() {
    setState(() {
      _future = sugestoesRepository.minhas();
    });
  }

  Future<void> _novaSugestao() async {
    final mensageiro = ScaffoldMessenger.of(context);
    final enviada = await mostrarDialogoNovaSugestao(context);
    if (enviada == null || !mounted) return;

    mensageiro.aviso('Sugestão enviada para ${enviada.destino}. Você será avisado quando houver resposta.');
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: GJButton(label: 'Nova sugestão', icon: Symbols.add, size: GJButtonSize.sm, onPressed: _novaSugestao),
        ),
        const SizedBox(height: GJSpace.s4),
        SecaoCarregavel<Sugestao>(
          future: _future,
          onTentarNovamente: _recarregar,
          vazio: GJEmptyState(
            titulo: 'Você ainda não enviou sugestões',
            texto:
                'Quando enviar uma sugestão para a equipe ou para uma universidade, ela aparece aqui com o status do atendimento.',
            icone: Symbols.forum,
            acaoLabel: 'Enviar uma sugestão',
            onAcao: _novaSugestao,
          ),
          construir: (lista) => Column(
            children: [
              for (final sugestao in lista)
                Padding(
                  padding: const EdgeInsets.only(bottom: GJSpace.s3),
                  child: SugestaoCard(
                    sugestao: sugestao,
                    onTap: () => context.go('/sugestoes/${sugestao.id}'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
