/// Contador com a palavra no singular ou no plural: `contagem(1, 'avaliação',
/// 'avaliações')` dá "1 avaliação"; com 0 ou 2 ou mais, o plural.
String contagem(int quantidade, String singular, String plural) =>
    '$quantidade ${quantidade == 1 ? singular : plural}';
