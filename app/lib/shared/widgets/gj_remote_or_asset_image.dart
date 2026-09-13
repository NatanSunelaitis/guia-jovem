import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Resolve uma URL vinda da API (`logoUrl`, `imagemUrl`) tanto para um asset
/// local do app (caminho relativo, ex.: `assets/img/logos/fatec.svg`, usado
/// pelo seed local sem depender de internet) quanto para uma URL de rede de
/// verdade (`http(s)://...`), quando a universidade tiver feito upload
/// próprio no futuro. Decide também entre SVG e raster pela extensão.
class GJRemoteOrAssetImage extends StatelessWidget {
  const GJRemoteOrAssetImage({super.key, required this.url, this.fit = BoxFit.cover, this.alignment = Alignment.center});

  final String url;
  final BoxFit fit;
  final Alignment alignment;

  bool get _isAsset => !url.startsWith('http://') && !url.startsWith('https://');
  bool get _isSvg => url.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      return _isAsset
          ? SvgPicture.asset(url, fit: fit, alignment: alignment)
          : SvgPicture.network(url, fit: fit, alignment: alignment);
    }
    return _isAsset
        ? Image.asset(url, fit: fit, alignment: alignment)
        : Image.network(url, fit: fit, alignment: alignment);
  }
}
