import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/tempo_relativo.dart';
import '../../../shared/widgets/gj_notification_bell.dart';
import '../../auth/data/session_controller.dart';
import '../../auth/domain/usuario_sessao.dart';
import '../data/notificacoes_repository.dart';
import '../domain/notificacao.dart';

/// Rota que a notificação abre, ou null se não há tela para ela ainda.
String? destinoDaNotificacao(Notificacao notificacao, TipoUsuario? tipoUsuario) {
  final id = notificacao.referenciaId;
  if (id == null) return null;
  return switch (notificacao.referenciaTipo) {
    'sugestao' => '/sugestoes/$id',
    // RF23: o administrador abre o cadastro para a análise; a universidade
    // vê a situação (aprovada, reprovada com o motivo, inativa) no painel.
    'universidade' when tipoUsuario == TipoUsuario.admin => '/admin/universidades/$id',
    'universidade' when tipoUsuario == TipoUsuario.universidade => '/painel-universidade',
    _ => null,
  };
}

/// Sino do header para qualquer usuário logado (RF14, T27). Busca as
/// notificações recentes ao montar: o header é remontado a cada troca de
/// tela, o que mantém o contador atualizado sem consultar a API em loop.
class NotificacoesBell extends StatefulWidget {
  const NotificacoesBell({super.key});

  @override
  State<NotificacoesBell> createState() => _NotificacoesBellState();
}

class _NotificacoesBellState extends State<NotificacoesBell> {
  List<Notificacao> _itens = const [];
  int _naoLidas = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final pagina = await notificacoesRepository.recentes();
      if (!mounted) return;
      setState(() {
        _itens = pagina.itens;
        _naoLidas = pagina.naoLidas;
      });
    } catch (_) {
      // Sem notificações (API fora do ar ou sessão caindo): o sino fica sem
      // contador, e a próxima tela tenta de novo.
    }
  }

  Future<void> _abrir(int indice) async {
    final notificacao = _itens[indice];
    final destino = destinoDaNotificacao(notificacao, sessionController.usuario?.tipoUsuario);

    if (!notificacao.lida) {
      setState(() {
        _itens = [for (final item in _itens) item.id == notificacao.id ? item.comoLida() : item];
        _naoLidas = _naoLidas > 0 ? _naoLidas - 1 : 0;
      });
      try {
        await notificacoesRepository.marcarLida(notificacao.id);
      } catch (_) {
        // Continua lida na tela; o próximo carregamento traz o estado real.
      }
    }

    if (destino != null && mounted) context.go(destino);
  }

  Future<void> _marcarTodas() async {
    setState(() {
      _itens = [for (final item in _itens) item.comoLida()];
      _naoLidas = 0;
    });
    try {
      await notificacoesRepository.marcarTodasLidas();
    } catch (_) {
      await _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GJNotificationBell(
      naoLidas: _naoLidas,
      notificacoes: [
        for (final item in _itens)
          GJNotificationItem(
            titulo: item.titulo,
            mensagem: item.mensagem,
            tempoRelativo: tempoRelativo(item.criadoEm),
            lida: item.lida,
          ),
      ],
      onTapNotificacao: _abrir,
      onMarcarTodasComoLidas: _naoLidas > 0 ? _marcarTodas : null,
    );
  }
}
