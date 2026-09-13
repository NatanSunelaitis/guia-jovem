/// Ilustrações neutras usadas quando não há um dado vindo da API (curso não
/// tem campo de imagem próprio na especificação). Escolhidas por área do
/// curso, com uma área padrão para o que não estiver mapeado.
abstract final class GJIllustrations {
  static const String areaSaude = 'assets/img/areas/saude.svg';
  static const String areaNegocios = 'assets/img/areas/negocios.svg';
  static const String areaHumanas = 'assets/img/areas/humanas.svg';

  static String porAreaCurso(String? areaCurso) => switch (areaCurso) {
        'Saúde' => areaSaude,
        'Humanas' => areaHumanas,
        _ => areaNegocios,
      };
}
