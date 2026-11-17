import 'package:flutter/material.dart';

import '../../../core/theme/gj_spacing.dart';
import '../../../core/theme/gj_typography.dart';
import '../../../shared/layouts/gj_page_container.dart';
import '../../../shared/layouts/public_layout.dart';
import '../../auth/data/session_controller.dart';
import 'widgets/dados_perfil_card.dart';

/// T16 Perfil do Aluno (`/perfil`, Figuras 25 e 26): dados e ações da conta.
class PerfilAlunoPage extends StatelessWidget {
  const PerfilAlunoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    return PublicLayout(
      child: GJPageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GJSpace.s12),
          child: ListenableBuilder(
            // O cartão mostra o nome novo assim que "Editar perfil" salva.
            listenable: sessionController,
            builder: (context, _) {
              final usuario = sessionController.usuario;
              if (usuario == null) return const SizedBox.shrink();

              final cartao = DadosPerfilCard(key: ValueKey('perfil-${usuario.id}'), usuario: usuario);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meu perfil', style: GJTypography.h1()),
                  const SizedBox(height: GJSpace.s6),
                  if (isMobile) cartao else SizedBox(width: 360, child: cartao),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
