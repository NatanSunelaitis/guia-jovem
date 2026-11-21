// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../network/api_client.dart';

/// Download pela própria página: Blob + link com o atributo download.
Future<void> salvarArquivo(ArquivoBaixado arquivo) async {
  final blob = html.Blob([arquivo.bytes], arquivo.tipo);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final link = html.AnchorElement(href: url)
    ..download = arquivo.nome
    ..style.display = 'none';
  html.document.body!.append(link);
  link.click();
  link.remove();
  // O navegador já copiou o conteúdo; libera a memória depois.
  Future<void>.delayed(const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}
