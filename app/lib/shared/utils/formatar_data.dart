/// Data no formato brasileiro (dd/mm/aaaa), no fuso do dispositivo.
String formatarData(DateTime data) {
  final local = data.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  return '$dia/$mes/${local.year}';
}
