const bcrypt = require('bcryptjs');

const prisma = require('../src/config/database');

const SENHA_DEMO = 'guiajovem123';

const PROGRAMAS_GLOBAIS = [
  {
    nome: 'Exame Nacional do Ensino Médio',
    sigla: 'ENEM',
    tipo: 'ENTRADA',
    descricao:
      'Prova nacional que avalia o desempenho de quem concluiu ou está concluindo o ensino médio.',
    comoFunciona:
      'O estudante se inscreve pelo site oficial, realiza as provas em dois domingos e usa a nota obtida para concorrer a vagas no SiSU, no ProUni e no FIES, ou para o Certificado de Conclusão do Ensino Médio.',
    requisitos: 'Estar cursando ou ter concluído o ensino médio.',
    linkOficial: 'https://enem.inep.gov.br',
  },
  {
    nome: 'Sistema de Seleção Unificada',
    sigla: 'SiSU',
    tipo: 'ENTRADA',
    descricao: 'Sistema do MEC que seleciona candidatos a vagas em universidades públicas com base na nota do ENEM.',
    comoFunciona:
      'A cada semestre, o candidato escolhe até duas opções de curso e universidade e concorre com sua nota do ENEM às vagas disponíveis.',
    requisitos: 'Ter feito o ENEM do ano de referência e não ter zerado a redação.',
    linkOficial: 'https://sisu.mec.gov.br',
  },
  {
    nome: 'Vestibular Tradicional',
    sigla: 'VESTIBULAR',
    tipo: 'ENTRADA',
    descricao: 'Processo seletivo próprio conduzido pela própria universidade para ingresso em seus cursos.',
    comoFunciona:
      'Cada universidade define seu edital, cronograma e critérios de avaliação, que podem incluir provas próprias, redação e entrevistas.',
    requisitos: 'Ter concluído o ensino médio até a data da matrícula.',
    linkOficial: null,
  },
  {
    nome: 'Programa Universidade para Todos',
    sigla: 'ProUni',
    tipo: 'BOLSA',
    descricao: 'Programa do governo federal que concede bolsas de estudo integrais e parciais em instituições privadas de ensino superior.',
    comoFunciona:
      'A concessão da bolsa é feita com base na nota do ENEM, respeitando critérios de renda familiar por pessoa e outras condições estabelecidas em edital.',
    requisitos: 'Ter feito o ENEM e atender aos critérios de renda familiar per capita do programa.',
    linkOficial: 'https://prouniportal.mec.gov.br',
  },
  {
    nome: 'Fundo de Financiamento Estudantil',
    sigla: 'FIES',
    tipo: 'FINANCIAMENTO',
    descricao: 'Programa do Ministério da Educação que financia a graduação de estudantes em instituições privadas.',
    comoFunciona:
      'O estudante financia parte ou a totalidade da mensalidade do curso e começa a pagar o valor financiado somente após a conclusão ou trancamento do curso, em condições facilitadas.',
    requisitos: 'Ter participado do ENEM e atingido a nota mínima exigida pelo programa, além de atender aos critérios de renda.',
    linkOficial: 'https://fies.mec.gov.br',
  },
  {
    nome: 'Programa Nacional de Assistência Estudantil',
    sigla: 'PNAES',
    tipo: 'BOLSA',
    descricao: 'Programa de assistência estudantil das instituições federais de ensino superior, com bolsas de permanência.',
    comoFunciona:
      'As instituições federais utilizam recursos do programa para oferecer auxílios de moradia, alimentação, transporte e outras bolsas de permanência a estudantes em situação de vulnerabilidade socioeconômica.',
    requisitos: 'Estar regularmente matriculado em instituição federal de ensino superior e comprovar vulnerabilidade socioeconômica.',
    linkOficial: 'https://www.gov.br/mec/pt-br/acesso-a-informacao/acoes-e-programas/programas/pnaes',
  },
];

const CURSOS = [
  { nome: 'Administração', areaCurso: 'Negócios', grau: 'Bacharelado' },
  { nome: 'Biomedicina', areaCurso: 'Saúde', grau: 'Bacharelado' },
  { nome: 'Medicina Veterinária', areaCurso: 'Saúde', grau: 'Bacharelado' },
  { nome: 'Nutrição', areaCurso: 'Saúde', grau: 'Bacharelado' },
  { nome: 'Pedagogia', areaCurso: 'Humanas', grau: 'Licenciatura' },
  { nome: 'Gestão de Recursos Humanos', areaCurso: 'Negócios', grau: 'Tecnólogo' },
  { nome: 'Farmácia', areaCurso: 'Saúde', grau: 'Bacharelado' },
  { nome: 'Ciências Contábeis', areaCurso: 'Negócios', grau: 'Bacharelado' },
];

const UNIVERSIDADES = [
  {
    nomeFantasia: 'Fatec Sorocaba',
    razaoSocial: 'Faculdade de Tecnologia de Sorocaba',
    cnpj: '11111111000101',
    email: 'contato@fatecsorocaba.edu.br',
    natureza: 'P',
    descricao: 'Faculdade de Tecnologia pública estadual, mantida pelo Centro Paula Souza.',
    linkPagina: 'https://fatecsorocaba.edu.br',
    campus: [
      {
        nome: 'Fatec Sorocaba',
        principal: true,
        endereco: { logradouro: 'Avenida Engenheiro Carlos Reinaldo Mendes', numero: '2929', bairro: 'Alto da Boa Vista', cidade: 'Sorocaba', estado: 'SP', cep: '18013380' },
      },
      {
        nome: 'Fatec Itu',
        principal: false,
        endereco: { logradouro: 'Avenida Pereira da Silva', numero: '1500', bairro: 'Jardim Piemonte', cidade: 'Itu', estado: 'SP', cep: '13309280' },
      },
    ],
    cursos: ['Administração', 'Gestão de Recursos Humanos', 'Ciências Contábeis', 'Pedagogia'],
  },
  {
    nomeFantasia: 'USP',
    razaoSocial: 'Universidade de São Paulo',
    cnpj: '22222222000102',
    email: 'contato@usp.br',
    natureza: 'P',
    descricao: 'Maior universidade pública do Brasil, referência em ensino, pesquisa e extensão.',
    linkPagina: 'https://www5.usp.br',
    campus: [
      {
        nome: 'USP São Paulo',
        principal: true,
        endereco: { logradouro: 'Rua da Reitoria', numero: '374', bairro: 'Butantã', cidade: 'São Paulo', estado: 'SP', cep: '05508220' },
      },
      {
        nome: 'USP São Carlos',
        principal: false,
        endereco: { logradouro: 'Avenida Trabalhador São-carlense', numero: '400', bairro: 'Centro', cidade: 'São Carlos', estado: 'SP', cep: '13566590' },
      },
    ],
    cursos: ['Medicina Veterinária', 'Biomedicina', 'Farmácia', 'Nutrição'],
  },
  {
    nomeFantasia: 'UNESP',
    razaoSocial: 'Universidade Estadual Paulista Júlio de Mesquita Filho',
    cnpj: '33333333000103',
    email: 'contato@unesp.br',
    natureza: 'P',
    descricao: 'Universidade pública estadual com campus distribuídos por todo o estado de São Paulo.',
    linkPagina: 'https://www.unesp.br',
    campus: [
      {
        nome: 'UNESP Bauru',
        principal: true,
        endereco: { logradouro: 'Avenida Engenheiro Luiz Edmundo Carrijo Coube', numero: '14-01', bairro: 'Vargem Limpa', cidade: 'Bauru', estado: 'SP', cep: '17033360' },
      },
      {
        nome: 'UNESP Araraquara',
        principal: false,
        endereco: { logradouro: 'Rodovia Araraquara-Jaú', numero: '01', bairro: 'Machados', cidade: 'Araraquara', estado: 'SP', cep: '14800903' },
      },
    ],
    cursos: ['Farmácia', 'Nutrição', 'Pedagogia', 'Administração'],
  },
];

async function seedAdmin() {
  const env = require('../src/config/env');

  const senhaHash = await bcrypt.hash(env.ADMIN_SENHA, 12);

  return prisma.usuario.upsert({
    where: { email: env.ADMIN_EMAIL },
    update: {},
    create: {
      nome: env.ADMIN_NOME,
      email: env.ADMIN_EMAIL,
      senhaHash,
      tipoUsuario: 'D',
    },
  });
}

async function seedProgramasGlobais(adminId) {
  const programas = {};

  for (const dados of PROGRAMAS_GLOBAIS) {
    const existente = await prisma.programa.findFirst({ where: { sigla: dados.sigla } });
    const programa =
      existente ??
      (await prisma.programa.create({
        data: { ...dados, usuarioId: adminId },
      }));

    programas[dados.sigla] = programa;
  }

  return programas;
}

async function seedCursosGlobais() {
  const cursosPorNome = {};

  for (const dados of CURSOS) {
    cursosPorNome[dados.nome] = dados;
  }

  return cursosPorNome;
}

async function seedUniversidades(adminId, cursosBase) {
  for (const dadosUniversidade of UNIVERSIDADES) {
    const senhaHash = await bcrypt.hash(SENHA_DEMO, 12);

    const usuarioUniversidade = await prisma.usuario.upsert({
      where: { email: dadosUniversidade.email },
      update: {},
      create: {
        nome: dadosUniversidade.nomeFantasia,
        email: dadosUniversidade.email,
        senhaHash,
        tipoUsuario: 'U',
      },
    });

    const universidade = await prisma.universidade.upsert({
      where: { cnpj: dadosUniversidade.cnpj },
      update: {},
      create: {
        usuarioId: usuarioUniversidade.id,
        nomeFantasia: dadosUniversidade.nomeFantasia,
        razaoSocial: dadosUniversidade.razaoSocial,
        cnpj: dadosUniversidade.cnpj,
        descricao: dadosUniversidade.descricao,
        linkPagina: dadosUniversidade.linkPagina,
        natureza: dadosUniversidade.natureza,
        status: 'A',
        aprovadoEm: new Date(),
        aprovadoPor: adminId,
      },
    });

    const campusCriados = [];
    for (const dadosCampus of dadosUniversidade.campus) {
      const endereco = await prisma.endereco.create({ data: dadosCampus.endereco });
      const campus = await prisma.campus.create({
        data: {
          universidadeId: universidade.id,
          enderecoId: endereco.id,
          nome: dadosCampus.nome,
          principal: dadosCampus.principal,
        },
      });
      campusCriados.push(campus);
    }

    for (const nomeCurso of dadosUniversidade.cursos) {
      const base = cursosBase[nomeCurso];
      const curso = await prisma.curso.create({
        data: {
          universidadeId: universidade.id,
          nome: base.nome,
          areaCurso: base.areaCurso,
          grau: base.grau,
          modalidade: 'Presencial',
        },
      });

      await prisma.campusCurso.create({
        data: {
          campusId: campusCriados[0].id,
          cursoId: curso.id,
          turno: 'Integral',
        },
      });
    }
  }
}

async function main() {
  const jaExisteSeed = await prisma.universidade.count();
  if (jaExisteSeed > 0) {
    console.log('Seed já aplicado anteriormente, nada a fazer.');
    return;
  }

  const admin = await seedAdmin();
  await seedProgramasGlobais(admin.id);
  const cursosBase = await seedCursosGlobais();
  await seedUniversidades(admin.id, cursosBase);

  console.log('Seed aplicado com sucesso.');
}

main()
  .catch((erro) => {
    console.error(erro);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
