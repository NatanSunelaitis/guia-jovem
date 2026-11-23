import '../../core/theme/gj_illustrations.dart';
import 'programa_estilo.dart';

/// Fotos empacotadas no app (assets/fotos, ver CREDITOS.md), sem depender de
/// internet. Regra para cursos e programas: foto com o nome do curso ou do
/// programa; senão, a foto da área do curso; senão, a ilustração de antes.
///
/// O nome do arquivo é o nome em minúsculas, sem acento e com hífen no lugar
/// do espaço (ver [slugFoto]). As listas abaixo precisam acompanhar os
/// arquivos das pastas; o teste fotos_test confere as duas coisas.
const String pastaFotosCursos = 'assets/fotos/cursos';
const String pastaFotosProgramas = 'assets/fotos/programas';

const Set<String> fotosCursos = {
  'administracao',
  'biomedicina',
  'ciencia-da-computacao',
  'ciencias-biologicas',
  'ciencias-contabeis',
  'enfermagem',
  'engenharia-de-producao',
  'farmacia',
  'geografia',
  'gestao-de-recursos-humanos',
  'medicina-veterinaria',
  'nutricao',
  'pedagogia',
  'psicologia',
};

/// Fotos padrão por área do curso (arquivo `area-<área>.jpg`).
const Set<String> fotosAreas = {'engenharia', 'humanas', 'negocios', 'saude', 'tecnologia'};

const Set<String> fotosProgramas = {
  'bolsa-engenheiras-do-futuro',
  'bolsa-merito-univale',
  'enem',
  'escola-da-familia',
  'fies',
  'fies-social',
  'prouni',
  'provao-paulista',
  'sisu',
  'vestibular',
};

/// Programas cujo nome cadastrado não coincide com o arquivo da foto.
const Map<String, String> _apelidosProgramas = {
  'provao-paulista-seriado': 'provao-paulista',
  'vestibular-fatec': 'vestibular',
};

const _acentos = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

/// "Ciência da Computação" vira "ciencia-da-computacao".
String slugFoto(String texto) {
  final semAcento = texto.toLowerCase().split('').map((c) => _acentos[c] ?? c).join();
  return semAcento.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Foto do curso pelo nome; senão a da área; senão a ilustração da área.
String fotoCurso({required String nome, String? areaCurso}) {
  final slug = slugFoto(nome);
  if (fotosCursos.contains(slug)) return '$pastaFotosCursos/$slug.jpg';
  final area = areaCurso == null ? null : slugFoto(areaCurso);
  if (area != null && fotosAreas.contains(area)) return '$pastaFotosCursos/area-$area.jpg';
  return GJIllustrations.porAreaCurso(areaCurso);
}

/// Imagem de um programa. Uma imagem de rede cadastrada pelo administrador
/// tem prioridade (foi escolhida para aquele programa); depois vem a foto
/// pela sigla ou pelo nome; por fim a imagem local cadastrada (ícone) ou a
/// ilustração genérica.
String fotoPrograma({required String nome, String? sigla, String? imagemUrl}) {
  if (imagemUrl != null && (imagemUrl.startsWith('http://') || imagemUrl.startsWith('https://'))) {
    return imagemUrl;
  }
  for (final candidato in [if (sigla != null) sigla, nome]) {
    final slug = slugFoto(candidato);
    final arquivo = _apelidosProgramas[slug] ?? slug;
    if (fotosProgramas.contains(arquivo)) return '$pastaFotosProgramas/$arquivo.jpg';
  }
  return imagemUrl ?? imagemProgramaPadrao;
}
