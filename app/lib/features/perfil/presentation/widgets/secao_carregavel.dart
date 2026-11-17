import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/gj_spacing.dart';
import '../../../../shared/widgets/gj_empty_state.dart';
import '../../../../shared/widgets/gj_skeleton.dart';

/// Estados comuns das seções do perfil: carregando, erro com "Tentar
/// novamente", vazio e a lista. [construir] recebe a própria lista do
/// future, que a seção pode alterar (ex.: remover um item) e chamar setState.
class SecaoCarregavel<T> extends StatelessWidget {
  const SecaoCarregavel({
    super.key,
    required this.future,
    required this.onTentarNovamente,
    required this.vazio,
    required this.construir,
  });

  final Future<List<T>> future;
  final VoidCallback onTentarNovamente;
  final Widget vazio;
  final Widget Function(List<T> itens) construir;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Column(
            children: [
              for (var i = 0; i < 3; i++)
                const Padding(padding: EdgeInsets.only(bottom: GJSpace.s3), child: GJSkeleton(height: GJSpace.s24)),
            ],
          );
        }

        if (snapshot.hasError) {
          final erro = snapshot.error;
          return GJEmptyState(
            titulo: 'Não foi possível carregar',
            texto: erro is ApiException ? erro.message : 'Tente novamente.',
            icone: Symbols.wifi_off,
            acaoLabel: 'Tentar novamente',
            onAcao: onTentarNovamente,
          );
        }

        final itens = snapshot.data!;
        return itens.isEmpty ? vazio : construir(itens);
      },
    );
  }
}
