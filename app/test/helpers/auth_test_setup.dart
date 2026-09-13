import 'package:app/features/auth/data/cadastro_universidade_state.dart';
import 'package:app/features/auth/data/session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chamar no `setUp` de todo teste que toque sessão/auth: zera o
/// shared_preferences falso (token_storage), o `sessionController` global
/// (visitante, bootstrap já concluído) e o estado em memória do wizard de
/// cadastro de universidade — os três são singletons globais reaproveitados
/// entre testes do mesmo arquivo.
Future<void> configurarAmbienteDeTeste() async {
  SharedPreferences.setMockInitialValues({});
  sessionController.redefinirParaTestes(usuario: null, carregando: false);
  cadastroUniversidadeState.reiniciar();
}
