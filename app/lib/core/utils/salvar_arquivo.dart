import '../network/api_client.dart';
import 'salvar_arquivo_stub.dart' if (dart.library.html) 'salvar_arquivo_web.dart' as plataforma;

/// Entrega ao usuário um arquivo baixado da API (relatório da pesquisa,
/// RF02). No navegador, monta o arquivo em memória e dispara o download por
/// um link na própria página: não abre aba nova, então bloqueador de pop-up
/// não interfere, e a tela sabe se deu certo para avisar o usuário.
typedef SalvarArquivo = Future<void> Function(ArquivoBaixado arquivo);

/// Implementação usada pelo app; os testes trocam por uma falsa.
SalvarArquivo salvarArquivo = plataforma.salvarArquivo;
