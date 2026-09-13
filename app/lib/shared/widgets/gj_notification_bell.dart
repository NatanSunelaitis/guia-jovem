import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/gj_colors.dart';
import '../../core/theme/gj_radius.dart';
import '../../core/theme/gj_spacing.dart';
import '../../core/theme/gj_typography.dart';

class GJNotificationItem {
  const GJNotificationItem({
    required this.titulo,
    required this.mensagem,
    required this.tempoRelativo,
    this.lida = false,
  });

  final String titulo;
  final String mensagem;
  final String tempoRelativo;
  final bool lida;
}

/// Sino de notificações do header (seção 3.17).
class GJNotificationBell extends StatelessWidget {
  const GJNotificationBell({
    super.key,
    required this.notificacoes,
    this.naoLidas = 0,
    this.onMarcarTodasComoLidas,
    this.onTapNotificacao,
  });

  final List<GJNotificationItem> notificacoes;
  final int naoLidas;
  final VoidCallback? onMarcarTodasComoLidas;
  final ValueChanged<int>? onTapNotificacao;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Notificações',
      offset: const Offset(0, 48),
      color: GJColors.surfaceLowest,
      shape: RoundedRectangleBorder(borderRadius: GJRadius.borderLg),
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 360),
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: GJSpace.s5, vertical: GJSpace.s4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Notificações', style: GJTypography.h4()),
                  ),
                ),
                const Divider(height: 1, color: GJColors.surfaceHigh),
                if (notificacoes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(GJSpace.s6),
                    child: Text('Nenhuma notificação por aqui.', style: GJTypography.bodySm()),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: notificacoes.length,
                      itemBuilder: (context, index) {
                        final notificacao = notificacoes[index];
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            onTapNotificacao?.call(index);
                          },
                          child: Container(
                            color: notificacao.lida ? Colors.transparent : GJColors.background,
                            padding: const EdgeInsets.symmetric(horizontal: GJSpace.s5, vertical: GJSpace.s3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: SizedBox(
                                    width: 8,
                                    height: 8,
                                    child: notificacao.lida
                                        ? null
                                        : const DecoratedBox(
                                            decoration: BoxDecoration(color: GJColors.primary, shape: BoxShape.circle),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: GJSpace.s3),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notificacao.titulo,
                                        style: GJTypography.bodySm(color: GJColors.textPrimary)
                                            .copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(notificacao.mensagem, style: GJTypography.bodySm()),
                                      const SizedBox(height: GJSpace.s1),
                                      Text(notificacao.tempoRelativo, style: GJTypography.caption()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (onMarcarTodasComoLidas != null) ...[
                  const Divider(height: 1, color: GJColors.surfaceHigh),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      onMarcarTodasComoLidas?.call();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: GJSpace.s3),
                      child: Center(
                        child: Text(
                          'Marcar todas como lidas',
                          style: GJTypography.label(color: GJColors.primary).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Symbols.notifications, color: GJColors.textSecondary),
            if (naoLidas > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: GJColors.error, shape: BoxShape.circle),
                  child: Text(
                    naoLidas > 9 ? '9+' : '$naoLidas',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
