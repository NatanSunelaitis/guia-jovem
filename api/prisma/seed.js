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
    imagemUrl: 'assets/img/programas/enem.svg',
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
    imagemUrl: 'assets/img/programas/sisu.svg',
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
    imagemUrl: 'assets/img/programas/vestibular.svg',
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
    imagemUrl: 'assets/img/programas/prouni.svg',
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
    imagemUrl: 'assets/img/programas/fies.svg',
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
    imagemUrl: 'assets/img/programas/pnaes.svg',
  },
];

// RF25/T08: cronograma 2026 exibido na linha do tempo do detalhe do programa.
const EVENTOS_POR_SIGLA = {
  ENEM: [
    { titulo: 'Início das inscrições', descricao: 'Página do Participante', dataInicio: '2026-05-12' },
    { titulo: 'Fim das inscrições', descricao: 'Pagamento da taxa até 23 de maio', dataInicio: '2026-05-23' },
    { titulo: 'Primeiro dia de prova', descricao: 'Linguagens, Humanas e Redação', dataInicio: '2026-11-08' },
    { titulo: 'Segundo dia de prova', descricao: 'Matemática e Natureza', dataInicio: '2026-11-15' },
  ],
  SiSU: [
    { titulo: 'Abertura das inscrições', descricao: 'Primeira edição de 2026', dataInicio: '2026-01-08' },
    { titulo: 'Resultado da chamada única', descricao: 'Divulgação no portal do SiSU', dataInicio: '2026-01-16' },
  ],
  ProUni: [
    { titulo: 'Abertura das inscrições', descricao: 'Primeiro semestre de 2026', dataInicio: '2026-01-16' },
    { titulo: 'Resultado da primeira chamada', descricao: 'Divulgação no portal do ProUni', dataInicio: '2026-01-22' },
  ],
  FIES: [
    { titulo: 'Abertura das inscrições', descricao: 'Primeiro semestre de 2026', dataInicio: '2026-02-10' },
    { titulo: 'Encerramento', descricao: 'Resultado em 18 de fevereiro', dataInicio: '2026-02-14' },
    { titulo: 'Entrega de documentos', descricao: 'Na instituição de ensino escolhida', dataInicio: '2026-03-05' },
  ],
};

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
    logoUrl: 'assets/img/logos/fatec.svg',
    programas: ['ENEM', 'SiSU', 'VESTIBULAR'],
    avaliacoes: [
      { nome: 'Marina Souza', nota: 5, comentario: 'Os professores têm vivência de mercado e os laboratórios são bem equipados. Consegui estágio em Gestão de Recursos Humanos já no terceiro semestre.' },
      { nome: 'Lucas Amaral', nota: 4, comentario: 'Ensino de qualidade e gratuito. A biblioteca poderia ficar aberta até mais tarde nos dias de prova.' },
      { nome: 'Ana Paula Ribeiro', nota: 5, comentario: 'A secretaria responde rápido e o processo de matrícula é simples. Recomendo para quem quer um curso de tecnologia com foco prático.' },
    ],
    campus: [
      {
        nome: 'Fatec Sorocaba',
        principal: true,
        telefoneFixo: '(15) 3223-1450',
        telefoneCelular: '(15) 99711-2233',
        emailCampus: 'sorocaba@fatec.sp.gov.br',
        endereco: { logradouro: 'Avenida Engenheiro Carlos Reinaldo Mendes', numero: '2929', bairro: 'Alto da Boa Vista', cidade: 'Sorocaba', estado: 'SP', cep: '18013380' },
      },
      {
        nome: 'Fatec Itu',
        principal: false,
        telefoneFixo: '(11) 4023-5678',
        telefoneCelular: null,
        emailCampus: 'itu@fatec.sp.gov.br',
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
    logoUrl: 'assets/img/logos/usp.svg',
    programas: ['ENEM', 'SiSU', 'FIES'],
    avaliacoes: [
      { nome: 'Beatriz Lima', nota: 5, comentario: 'A estrutura de laboratórios e bibliotecas é impressionante. Tive muitas oportunidades de iniciação científica logo no primeiro ano.' },
      { nome: 'Rafael Nogueira', nota: 5, comentario: 'O nome da USP abre portas no mercado de trabalho. As provas são exigentes, mas o suporte de monitoria é constante.' },
      { nome: 'Camila Duarte', nota: 5, comentario: 'Ambiente muito plural e professores renomados na área. Só senti falta de mais vagas de moradia estudantil perto do campus.' },
    ],
    campus: [
      {
        nome: 'USP São Paulo',
        principal: true,
        telefoneFixo: '(11) 3091-3111',
        telefoneCelular: '(11) 98811-4455',
        emailCampus: 'atendimento@usp.br',
        endereco: { logradouro: 'Rua da Reitoria', numero: '374', bairro: 'Butantã', cidade: 'São Paulo', estado: 'SP', cep: '05508220' },
      },
      {
        nome: 'USP São Carlos',
        principal: false,
        telefoneFixo: '(16) 3373-9200',
        telefoneCelular: null,
        emailCampus: 'saocarlos@usp.br',
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
    logoUrl: 'assets/img/logos/unesp.svg',
    programas: ['ENEM', 'SiSU', 'ProUni', 'FIES'],
    avaliacoes: [
      { nome: 'Pedro Henrique Alves', nota: 4, comentario: 'Bom custo-benefício sendo pública, com professores acessíveis. O transporte até o campus de Bauru podia ser mais frequente.' },
      { nome: 'Juliana Ferreira', nota: 5, comentario: 'Gostei muito da grade curricular e dos projetos de extensão. A secretaria virtual facilita bastante a vida do aluno.' },
      { nome: 'Thiago Martins', nota: 4, comentario: 'Estrutura boa para os cursos da área de saúde. Falta ampliar o refeitório em horário de pico.' },
    ],
    campus: [
      {
        nome: 'UNESP Bauru',
        principal: true,
        telefoneFixo: '(14) 3103-6000',
        telefoneCelular: '(14) 99622-3344',
        emailCampus: 'bauru@unesp.br',
        endereco: { logradouro: 'Avenida Engenheiro Luiz Edmundo Carrijo Coube', numero: '14-01', bairro: 'Vargem Limpa', cidade: 'Bauru', estado: 'SP', cep: '17033360' },
      },
      {
        nome: 'UNESP Araraquara',
        principal: false,
        telefoneFixo: '(16) 3301-6000',
        telefoneCelular: null,
        emailCampus: 'araraquara@unesp.br',
        endereco: { logradouro: 'Rodovia Araraquara-Jaú', numero: '01', bairro: 'Machados', cidade: 'Araraquara', estado: 'SP', cep: '14800903' },
      },
    ],
    cursos: ['Farmácia', 'Nutrição', 'Pedagogia', 'Administração'],
  },
];

function media(notas) {
  return (notas.reduce((soma, nota) => soma + nota, 0) / notas.length).toFixed(2);
}

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

async function seedProgramaEventos(programas) {
  for (const [sigla, eventos] of Object.entries(EVENTOS_POR_SIGLA)) {
    const programa = programas[sigla];
    if (!programa) continue;

    for (const evento of eventos) {
      await prisma.programaEvento.create({
        data: {
          programaId: programa.id,
          titulo: evento.titulo,
          descricao: evento.descricao,
          dataInicio: new Date(evento.dataInicio),
        },
      });
    }
  }
}

async function seedCursosGlobais() {
  const cursosPorNome = {};

  for (const dados of CURSOS) {
    cursosPorNome[dados.nome] = dados;
  }

  return cursosPorNome;
}

async function seedUniversidades(adminId, cursosBase, programas) {
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

    const mediaAvaliacao = media(dadosUniversidade.avaliacoes.map((a) => a.nota));

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
        logoUrl: dadosUniversidade.logoUrl,
        natureza: dadosUniversidade.natureza,
        status: 'A',
        aprovadoEm: new Date(),
        aprovadoPor: adminId,
        mediaAvaliacao,
        totalAvaliacoes: dadosUniversidade.avaliacoes.length,
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
          telefoneFixo: dadosCampus.telefoneFixo ?? null,
          telefoneCelular: dadosCampus.telefoneCelular ?? null,
          emailCampus: dadosCampus.emailCampus ?? null,
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
          vagas: 40,
        },
      });
    }

    for (const sigla of dadosUniversidade.programas) {
      const programa = programas[sigla];
      if (!programa) continue;

      await prisma.universidadePrograma.create({
        data: { universidadeId: universidade.id, programaId: programa.id },
      });
    }

    for (const avaliacao of dadosUniversidade.avaliacoes) {
      const usuarioAvaliador = await prisma.usuario.upsert({
        where: { email: `${avaliacao.nome.split(' ')[0].toLowerCase()}.${universidade.id}@aluno.guiajovem.com.br` },
        update: {},
        create: {
          nome: avaliacao.nome,
          email: `${avaliacao.nome.split(' ')[0].toLowerCase()}.${universidade.id}@aluno.guiajovem.com.br`,
          senhaHash: await bcrypt.hash(SENHA_DEMO, 12),
          tipoUsuario: 'A',
        },
      });

      await prisma.avaliacao.create({
        data: {
          usuarioId: usuarioAvaliador.id,
          universidadeId: universidade.id,
          nota: avaliacao.nota,
          comentario: avaliacao.comentario,
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
  const programas = await seedProgramasGlobais(admin.id);
  await seedProgramaEventos(programas);
  const cursosBase = await seedCursosGlobais();
  await seedUniversidades(admin.id, cursosBase, programas);

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
