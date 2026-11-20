import 'dart:io';

import 'package:app/core/theme/gj_illustrations.dart';
import 'package:app/shared/utils/fotos.dart';
import 'package:app/shared/utils/programa_estilo.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> _jpgs(String pasta) => Directory(pasta)
    .listSync()
    .whereType<File>()
    .map((f) => f.uri.pathSegments.last)
    .where((nome) => nome.endsWith('.jpg'))
    .map((nome) => nome.substring(0, nome.length - 4))
    .toSet();

void main() {
  test('slugFoto tira acentos, caixa e espaços', () {
    expect(slugFoto('Ciência da Computação'), 'ciencia-da-computacao');
    expect(slugFoto('Gestão de Recursos Humanos'), 'gestao-de-recursos-humanos');
    expect(slugFoto('  Fies Social '), 'fies-social');
    expect(slugFoto('SiSU'), 'sisu');
  });

  group('fotoCurso', () {
    test('usa a foto com o nome do curso', () {
      expect(fotoCurso(nome: 'Nutrição', areaCurso: 'Saúde'), 'assets/fotos/cursos/nutricao.jpg');
    });

    test('sem foto própria, usa a foto da área', () {
      expect(fotoCurso(nome: 'Engenharia Civil', areaCurso: 'Engenharia'), 'assets/fotos/cursos/area-engenharia.jpg');
      expect(fotoCurso(nome: 'Logística', areaCurso: 'Negócios'), 'assets/fotos/cursos/area-negocios.jpg');
    });

    test('sem foto da área, mantém a ilustração', () {
      expect(fotoCurso(nome: 'Astronomia', areaCurso: 'Ciências Exatas'), GJIllustrations.porAreaCurso('Ciências Exatas'));
      expect(fotoCurso(nome: 'Astronomia'), GJIllustrations.porAreaCurso(null));
    });
  });

  group('fotoPrograma', () {
    test('acha a foto pela sigla ou pelo nome', () {
      expect(fotoPrograma(nome: 'Sistema de Seleção Unificada', sigla: 'SiSU'), 'assets/fotos/programas/sisu.jpg');
      expect(fotoPrograma(nome: 'Bolsa Mérito UniVale', sigla: 'Mérito'), 'assets/fotos/programas/bolsa-merito-univale.jpg');
      expect(fotoPrograma(nome: 'Provão Paulista Seriado', sigla: 'Provão'), 'assets/fotos/programas/provao-paulista.jpg');
    });

    test('a foto vence o ícone local, mas não uma imagem de rede cadastrada', () {
      expect(fotoPrograma(nome: 'ENEM', sigla: 'ENEM', imagemUrl: 'assets/img/programas/enem.svg'), 'assets/fotos/programas/enem.jpg');
      expect(
        fotoPrograma(nome: 'ENEM', sigla: 'ENEM', imagemUrl: 'https://exemplo.com/enem.png'),
        'https://exemplo.com/enem.png',
      );
    });

    test('sem foto, mantém a imagem cadastrada ou a genérica', () {
      expect(fotoPrograma(nome: 'Bolsa Nova', imagemUrl: 'assets/img/programas/pnaes.svg'), 'assets/img/programas/pnaes.svg');
      expect(fotoPrograma(nome: 'Bolsa Nova'), imagemProgramaPadrao);
    });
  });

  test('as listas do código acompanham os arquivos das pastas', () {
    final cursos = _jpgs(pastaFotosCursos);
    expect(cursos.where((n) => !n.startsWith('area-')).toSet(), fotosCursos);
    expect(cursos.where((n) => n.startsWith('area-')).map((n) => n.substring(5)).toSet(), fotosAreas);
    expect(_jpgs(pastaFotosProgramas), fotosProgramas);
  });

  test('toda foto tem crédito no CREDITOS.md', () {
    final creditos = File('assets/fotos/CREDITOS.md').readAsStringSync();
    for (final nome in [..._jpgs(pastaFotosCursos), ..._jpgs(pastaFotosProgramas)]) {
      expect(creditos, contains('| $nome.jpg |'), reason: '$nome.jpg sem linha no CREDITOS.md');
    }
  });

  test('todo curso e programa da demonstração ganha uma foto', () {
    final dados = File('../api/prisma/demo/dados.js').readAsStringSync();

    final cursos = RegExp(r"\{ nome: '([^']+)', areaCurso: '([^']+)'").allMatches(dados).toList();
    expect(cursos, isNotEmpty);
    for (final c in cursos) {
      expect(fotoCurso(nome: c[1]!, areaCurso: c[2]), endsWith('.jpg'), reason: c[1]);
    }

    final programas = RegExp(r"sigla: '([^']+)',\s+nome: '([^']+)'").allMatches(dados).toList();
    final bolsas = RegExp(r"nome: '(Bolsa [^']+)',\s+sigla: (?:'([^']+)'|null)").allMatches(dados).toList();
    expect(programas.length, 8);
    expect(bolsas.length, 2);
    for (final p in programas) {
      expect(fotoPrograma(nome: p[2]!, sigla: p[1]), endsWith('.jpg'), reason: p[2]);
    }
    for (final b in bolsas) {
      expect(fotoPrograma(nome: b[1]!, sigla: b[2]), endsWith('.jpg'), reason: b[1]);
    }
  });
}
