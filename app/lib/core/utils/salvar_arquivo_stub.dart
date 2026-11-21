import '../network/api_client.dart';

/// Fora do navegador (testes, Android e iOS) ainda não há onde salvar.
Future<void> salvarArquivo(ArquivoBaixado arquivo) async {
  throw UnsupportedError('Salvar arquivos só está disponível no navegador.');
}
