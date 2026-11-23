const {
  agruparPorNome,
  grafiaMaisUsada,
  gruposDeNomesParecidos,
  maisFrequente,
  nomesParecidos,
  normalizarNome,
} = require('./nomesCurso');

describe('normalizarNome', () => {
  it('ignora maiúsculas, acentos e espaços repetidos', () => {
    expect(normalizarNome('  Análise e  Desenvolvimento de SISTEMAS ')).toBe('analise e desenvolvimento de sistemas');
    expect(normalizarNome('Educação Física')).toBe(normalizarNome('educacao fisica'));
  });
});

describe('maisFrequente e grafiaMaisUsada', () => {
  it('escolhe o valor mais frequente e, no empate, o primeiro cadastrado', () => {
    expect(maisFrequente(['Saúde', null, 'Humanas', 'Humanas'])).toBe('Humanas');
    expect(maisFrequente(['Tecnologia', 'Computação'])).toBe('Tecnologia');
    expect(maisFrequente([null, ''])).toBeNull();
  });

  it('a grafia exibida não leva os espaços sobrando', () => {
    expect(grafiaMaisUsada(['Pedagogia  ', 'pedagogia', 'Pedagogia'])).toBe('Pedagogia');
  });
});

describe('agruparPorNome', () => {
  it('junta as grafias equivalentes e conta graus, cursos e universidades', () => {
    const [grupo, outro] = agruparPorNome([
      { id: 1, nome: 'Educação Física', grau: 'Licenciatura', areaCurso: 'Saúde', universidadeId: 1 },
      { id: 2, nome: 'educacao fisica', grau: 'Bacharelado', areaCurso: 'Saúde', universidadeId: 2 },
      { id: 3, nome: 'Educação  Física', grau: 'Bacharelado', areaCurso: 'Esporte', universidadeId: 2 },
      { id: 4, nome: 'Pedagogia', grau: 'Licenciatura', areaCurso: 'Humanas', universidadeId: 1 },
    ]);

    expect(grupo).toMatchObject({
      nome: 'Educação Física',
      areaCurso: 'Saúde',
      graus: ['Bacharelado', 'Licenciatura'],
      totalOfertas: 3,
      totalUniversidades: 2,
    });
    expect(outro).toMatchObject({ nome: 'Pedagogia', totalOfertas: 1 });
  });
});

describe('nomesParecidos', () => {
  it.each([
    ['ADS', 'Análise e Desenvolvimento de Sistemas'],
    ['Eng. Civil', 'Engenharia Civil'],
    ['Adm.', 'Administração'],
    ['Engenharia Produção', 'Engenharia de Produção'],
    ['Enfermagen', 'Enfermagem'],
    ['Analise e Desenvolvimento de Sistemas', 'Análise e Desenvolvimento de Sistemas'],
  ])('%s e %s são parecidos', (a, b) => {
    expect(nomesParecidos(a, b)).toBe(true);
  });

  it.each([
    ['Engenharia Elétrica', 'Engenharia Eletrônica'],
    ['Engenharia Civil', 'Engenharia Mecânica'],
    ['Física', 'Química'],
    ['Direito', 'Design'],
  ])('%s e %s são cursos diferentes', (a, b) => {
    expect(nomesParecidos(a, b)).toBe(false);
  });
});

describe('gruposDeNomesParecidos', () => {
  it('agrupa só as grafias diferentes, com o nome sugerido mais usado', () => {
    const cursos = [
      { id: 1, nome: 'Engenharia Civil' },
      { id: 2, nome: 'Engenharia Civil' },
      { id: 3, nome: 'Eng. Civil' },
      { id: 4, nome: 'Pedagogia' },
      { id: 5, nome: 'Pedagogia' },
      { id: 6, nome: 'ADS' },
      { id: 7, nome: 'Análise e Desenvolvimento de Sistemas' },
    ];

    const grupos = gruposDeNomesParecidos(cursos);

    expect(grupos).toHaveLength(2);
    expect(grupos[0]).toMatchObject({ nomeSugerido: 'ADS', grafias: 2 });
    expect(grupos[1].nomeSugerido).toBe('Engenharia Civil');
    expect(grupos[1].cursos.map((c) => c.id)).toEqual([1, 2, 3]);
  });
});
