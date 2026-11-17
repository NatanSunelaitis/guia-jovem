import 'formatar_data.dart';

/// "agora", "há 5 min", "há 3 h", "há 2 dias"; depois de uma semana, a data.
String tempoRelativo(DateTime data, {DateTime? agora}) {
  final diferenca = (agora ?? DateTime.now()).difference(data);
  if (diferenca.inMinutes < 1) return 'agora';
  if (diferenca.inHours < 1) return 'há ${diferenca.inMinutes} min';
  if (diferenca.inDays < 1) return 'há ${diferenca.inHours} h';
  if (diferenca.inDays == 1) return 'ontem';
  if (diferenca.inDays < 7) return 'há ${diferenca.inDays} dias';
  return formatarData(data);
}
