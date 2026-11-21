import 'package:app/core/theme/gj_theme.dart';
import 'package:app/features/cursos/domain/curso.dart';
import 'package:app/features/cursos/presentation/detalhe_curso_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/mock_api.dart';

Map<String, dynamic> _oferta({
  int cursoId = 7,
  int universidadeId = 2,
  String nomeFantasia = 'UniVale Sorocaba',
  String natureza = 'V',
  String modalidade = 'Presencial',
  int duracao = 8,
  String? descricao = '## O que você estuda\n\nGestão de **pessoas** e finanças.',
  List<Map<String, dynamic>>? campus,
}) =>
    {
      'cursoId': cursoId,
      'areaCurso': 'Negócios',
      'grau': 'Bacharelado',
      'modalidade': modalidade,
      'duracaoSemestres': duracao,
      'notaMec': '4',
      'descricao': descricao,
      'universidade': {
        'id': universidadeId,
        'nomeFantasia': nomeFantasia,
        'logoUrl': null,
        'natureza': natureza,
        'cidade': 'Sorocaba',
        'estado': 'SP',
      },
      'campus': campus ??
          [
            {'id': 30, 'nome': 'Campus Centro', 'cidade': 'Sorocaba', 'estado': 'SP', 'turno': 'Noturno', 'vagas': 100},
            {'id': 31, 'nome': 'Campus Campolim', 'cidade': 'Sorocaba', 'estado': 'SP', 'turno': 'Matutino', 'vagas': 50},
          ],
      'programas': {
        'ENTRADA': [
          {'id': 1, 'nome': 'Exame Nacional do Ensino Médio', 'sigla': 'ENEM', 'observacao': null, 'institucional': false},
        ],
        'FINANCIAMENTO': [
          {'id': 5, 'nome': 'Fundo de Financiamento Estudantil', 'sigla': 'FIES', 'observacao': 'Até 100% da mensalidade', 'institucional': false},
        ],
        'BOLSA': [
          {'id': 9, 'nome': 'Bolsa Mérito UniVale', 'sigla': 'Mérito', 'observacao': null, 'institucional': true},
        ],
      },
    };

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(WidgetTester tester, Widget pagina) async {
    tester.view.physicalSize = const Size(1366, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: pagina));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('por id: resumo, card da universidade e descrição formatada acima dos cards', (tester) async {
    mockApi({
      '/cursos/5': envelope({
        'id': 5,
        'nome': 'Administração',
        ..._oferta(cursoId: 5),
      }),
    });

    await abrir(tester, const DetalheCursoPage.porId(id: 5));

    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('8 semestres (4 anos)'), findsWidgets);
    expect(find.text('1 universidade em 1 cidade'), findsOneWidget);
    // Uma oferta só: a descrição aparece uma vez, acima do card, formatada.
    expect(find.text('Sobre o curso'), findsOneWidget);
    expect(find.text('O que você estuda', findRichText: true), findsOneWidget);
    expect(find.text('Ver mais'), findsNothing);
    expect(find.text('Universidade que oferece este curso'), findsOneWidget);
    final imagem = tester.widget<Image>(find.byType(Image).first);
    expect((imagem.image as AssetImage).assetName, 'assets/fotos/cursos/administracao.jpg');
  });

  testWidgets('por nome: um card por universidade com tudo da oferta e a descrição recolhida', (tester) async {
    mockApi({
      '/cursos/nome/Pedagogia': envelope({
        'nome': 'Pedagogia',
        'areaCurso': 'Humanas',
        'universidades': [
          _oferta(),
          _oferta(
            cursoId: 8,
            universidadeId: 3,
            nomeFantasia: 'UESP',
            natureza: 'P',
            modalidade: 'EAD',
            duracao: 10,
            descricao: 'Texto **diferente** com a modalidade a distância.',
            campus: [
              {'id': 40, 'nome': 'Campus Itapetininga', 'cidade': 'Itapetininga', 'estado': 'SP', 'turno': 'Noturno', 'vagas': 45},
            ],
          ),
        ],
      }),
    });

    await abrir(tester, const DetalheCursoPage.porNome(nome: 'Pedagogia'));

    expect(find.text('Em quais universidades este curso está disponível'), findsOneWidget);
    // Resumo do topo.
    expect(find.text('Bacharelado'), findsWidgets);
    expect(find.text('Presencial e EAD'), findsOneWidget);
    expect(find.text('8 a 10 semestres'), findsOneWidget);
    expect(find.text('2 universidades em 2 cidades'), findsOneWidget);

    // Card: sigla, nome, cidade, natureza, dados do curso, campi e programas.
    expect(find.text('UniVale'), findsOneWidget);
    expect(find.text('UniVale Sorocaba'), findsOneWidget);
    expect(find.text('Privada'), findsOneWidget);
    expect(find.text('Pública'), findsOneWidget);
    expect(find.text('Campus Centro'), findsOneWidget);
    expect(find.text('Sorocaba/SP · Noturno · 100 vagas'), findsOneWidget);
    expect(find.text('Itapetininga/SP · Noturno · 45 vagas'), findsOneWidget);
    expect(find.text('ENEM'), findsNWidgets(2));
    expect(find.text('FIES'), findsNWidgets(2));
    expect(find.text('Bolsa Mérito UniVale'), findsNWidgets(2));
    expect(find.textContaining('Nota do MEC: 4', findRichText: true), findsNWidgets(2));

    // Descrições diferentes: dentro de cada card, recolhidas.
    expect(find.text('Sobre o curso'), findsNothing);
    expect(find.text('Ver mais'), findsNWidgets(2));
    expect(find.text('Texto diferente com a modalidade a distância.'), findsOneWidget);
    await tester.tap(find.text('Ver mais').last);
    await tester.pump();
    expect(find.text('Ver menos'), findsOneWidget);
    expect(find.text('Texto diferente com a modalidade a distância.', findRichText: true), findsOneWidget);
  });

  testWidgets('por nome: descrições iguais aparecem uma vez só, acima dos cards', (tester) async {
    mockApi({
      '/cursos/nome/Farmácia': envelope({
        'nome': 'Farmácia',
        'areaCurso': 'Saúde',
        'universidades': [_oferta(), _oferta(cursoId: 8, universidadeId: 3, nomeFantasia: 'UESP')],
      }),
    });

    await abrir(tester, const DetalheCursoPage.porNome(nome: 'Farmácia'));

    expect(find.text('Sobre o curso'), findsOneWidget);
    expect(find.text('O que você estuda', findRichText: true), findsOneWidget);
    expect(find.text('Ver mais'), findsNothing);
    final imagem = tester.widget<Image>(find.byType(Image).first);
    expect((imagem.image as AssetImage).assetName, 'assets/fotos/cursos/farmacia.jpg');
  });

  testWidgets('no celular a página monta sem estourar a largura', (tester) async {
    mockApi({
      '/cursos/nome/Pedagogia': envelope({
        'nome': 'Pedagogia',
        'areaCurso': 'Humanas',
        'universidades': [_oferta(), _oferta(cursoId: 8, universidadeId: 3, nomeFantasia: 'Faculdade Votorantim de Tecnologia', descricao: 'Outra.')],
      }),
    });
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(theme: GJTheme.light, home: const DetalheCursoPage.porNome(nome: 'Pedagogia')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('FVT'), findsOneWidget);
  });

  group('resumo do curso', () {
    OfertaCurso oferta({int? duracao, String? descricao, String cidade = 'Sorocaba'}) => OfertaCurso.fromJson({
          ..._oferta(descricao: descricao),
          'duracaoSemestres': duracao,
          'campus': [
            {'id': 1, 'nome': 'C', 'cidade': cidade, 'estado': 'SP', 'turno': null, 'vagas': null},
          ],
        });

    test('duração única, com anos e meio, e faixa', () {
      expect(duracaoDasOfertas([oferta(duracao: 8)]), '8 semestres (4 anos)');
      expect(duracaoDasOfertas([oferta(duracao: 5)]), '5 semestres (2 anos e meio)');
      expect(duracaoDasOfertas([oferta(duracao: 4), oferta(duracao: 10)]), '4 a 10 semestres');
      expect(duracaoDasOfertas([oferta()]), isNull);
    });

    test('cidades distintas e valores com "e"', () {
      expect(cidadesDasOfertas([oferta(), oferta(), oferta(cidade: 'Tatuí')]), {'Sorocaba/SP', 'Tatuí/SP'});
      expect(valoresDistintos(['Bacharelado', 'Licenciatura', 'Bacharelado', 'Tecnólogo']), 'Bacharelado, Licenciatura e Tecnólogo');
    });

    test('descrição comum só quando todas são iguais e não vazias', () {
      expect(descricaoComum([oferta(descricao: 'A'), oferta(descricao: 'A')]), 'A');
      expect(descricaoComum([oferta(descricao: 'A'), oferta(descricao: 'B')]), isNull);
      expect(descricaoComum([oferta(descricao: null), oferta(descricao: null)]), isNull);
    });
  });
}
