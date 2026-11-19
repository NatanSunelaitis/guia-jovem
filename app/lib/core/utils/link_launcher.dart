import 'package:url_launcher/url_launcher.dart';

/// Abre um link externo em nova aba (RF03: `target=_blank rel=noopener`).
Future<void> abrirLinkExterno(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;

  await launchUrl(uri, webOnlyWindowName: '_blank');
}
