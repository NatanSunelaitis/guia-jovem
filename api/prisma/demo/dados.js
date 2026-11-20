/**
 * Instituições fictícias: os sites, as páginas de simulados e os e-mails das
 * universidades e dos campi usam o domínio reservado example.com (RFC 2606),
 * que não pertence a ninguém.
 *
 * Dados da apresentação (npm run db:demo). As instituições são fictícias,
 * com nomes plausíveis para a região de Sorocaba; os programas são os
 * nacionais e estaduais reais. Todo dado factual daqui (datas, vagas, notas,
 * endereços, telefones, CNPJs e links) é ILUSTRATIVO e precisa ser conferido
 * antes de qualquer uso fora da demonstração.
 */

const CONTAS = {
  admin: { nome: 'Equipe Guia Jovem', email: 'admin@demo.guiajovem.com.br' },
  alunos: [
    { chave: 'beatriz', nome: 'Beatriz Almeida', email: 'beatriz@demo.guiajovem.com.br' },
    { chave: 'lucas', nome: 'Lucas Pereira', email: 'lucas@demo.guiajovem.com.br' },
  ],
};

// Programas globais (administrador). As siglas casam com os ícones e as
// imagens do app (assets/img/programas).
const PROGRAMAS = [
  {
    sigla: 'ENEM',
    nome: 'Exame Nacional do Ensino Médio',
    tipo: 'ENTRADA',
    descricao: 'Prova nacional do Inep que avalia quem concluiu ou está concluindo o ensino médio. A nota é usada no SiSU, no ProUni, no FIES e em vestibulares de instituições privadas.',
    comoFunciona: 'A inscrição é feita na Página do Participante. As provas acontecem em dois domingos: no primeiro, Linguagens, Ciências Humanas e Redação; no segundo, Matemática e Ciências da Natureza.',
    requisitos: 'Estar cursando o último ano ou ter concluído o ensino médio. Estudantes de escola pública e famílias de baixa renda podem pedir isenção da taxa.',
    linkOficial: 'https://www.gov.br/inep/pt-br/areas-de-atuacao/avaliacao-e-exames-educacionais/enem',
    imagemUrl: 'assets/img/programas/enem.svg',
    eventos: [
      { titulo: 'Resultado do Enem 2026', descricao: 'Notas na Página do Participante', dataInicio: '2027-01-15' },
      { titulo: 'Inscrições do Enem 2027', descricao: 'Pela Página do Participante', dataInicio: '2027-05-10', dataFim: '2027-05-21' },
      { titulo: 'Provas do Enem 2027', descricao: 'Dois domingos de prova', dataInicio: '2027-11-07', dataFim: '2027-11-14' },
    ],
  },
  {
    sigla: 'SiSU',
    nome: 'Sistema de Seleção Unificada',
    tipo: 'ENTRADA',
    descricao: 'Sistema do MEC que seleciona estudantes para vagas em instituições públicas de ensino superior usando a nota do Enem.',
    comoFunciona: 'Na inscrição, o estudante escolhe até duas opções de curso. Durante o período, o sistema mostra a nota de corte parcial e o estudante pode trocar as opções até o encerramento.',
    requisitos: 'Ter feito a edição mais recente do Enem e não ter tirado zero na redação.',
    linkOficial: 'https://acessounico.mec.gov.br/sisu',
    imagemUrl: 'assets/img/programas/sisu.svg',
    eventos: [
      { titulo: 'Inscrições do SiSU 2027', descricao: 'Primeira edição do ano', dataInicio: '2027-01-19', dataFim: '2027-01-23' },
      { titulo: 'Resultado da chamada regular', descricao: 'No portal Acesso Único', dataInicio: '2027-01-27' },
      { titulo: 'Lista de espera', descricao: 'Manifestação de interesse', dataInicio: '2027-01-27', dataFim: '2027-02-06' },
    ],
  },
  {
    sigla: 'Provão',
    nome: 'Provão Paulista Seriado',
    tipo: 'ENTRADA',
    descricao: 'Avaliação seriada do governo de São Paulo para estudantes da rede pública estadual, com vagas em universidades estaduais paulistas e nas Fatecs.',
    comoFunciona: 'Os estudantes fazem uma prova em cada ano do ensino médio na própria escola. As notas das três séries formam a nota final usada na escolha das vagas.',
    requisitos: 'Estar matriculado no ensino médio da rede pública estadual de São Paulo.',
    linkOficial: 'https://provaopaulista.vunesp.com.br',
    imagemUrl: null,
    eventos: [
      { titulo: 'Escolha de cursos', descricao: 'Estudantes da 3ª série', dataInicio: '2026-12-07', dataFim: '2026-12-11' },
      { titulo: 'Divulgação da primeira chamada', descricao: 'No site da Vunesp', dataInicio: '2027-01-08' },
    ],
  },
  {
    sigla: 'VESTIBULAR',
    nome: 'Vestibular Tradicional',
    tipo: 'ENTRADA',
    descricao: 'Processo seletivo próprio de cada instituição, com edital, provas e calendário definidos por ela.',
    comoFunciona: 'Cada instituição publica o edital com as datas de inscrição e de prova. Muitas privadas também aceitam a nota do Enem no lugar da prova.',
    requisitos: 'Ter concluído o ensino médio até a data da matrícula.',
    linkOficial: null,
    imagemUrl: 'assets/img/programas/vestibular.svg',
    eventos: [
      { titulo: 'Vestibulares de verão', descricao: 'Período mais comum nas instituições da região', dataInicio: '2026-10-01', dataFim: '2026-12-15' },
      { titulo: 'Vestibulares de inverno', descricao: 'Ingresso no segundo semestre', dataInicio: '2027-05-01', dataFim: '2027-06-30' },
    ],
  },
  {
    sigla: 'FIES',
    nome: 'Fundo de Financiamento Estudantil',
    tipo: 'FINANCIAMENTO',
    descricao: 'Programa do MEC que financia a graduação em instituições privadas participantes, com pagamento depois da formatura.',
    comoFunciona: 'O estudante se inscreve com a nota do Enem e escolhe o curso. Se for pré-selecionado, confirma os dados na instituição e no banco. O pagamento começa depois da conclusão do curso, em parcelas de acordo com a renda.',
    requisitos: 'Ter feito o Enem a partir de 2010 com média de pelo menos 450 pontos e nota acima de zero na redação, e ter renda familiar de até três salários mínimos por pessoa.',
    linkOficial: 'https://acessounico.mec.gov.br/fies',
    imagemUrl: 'assets/img/programas/fies.svg',
    eventos: [
      { titulo: 'Inscrições do Fies 2027', descricao: 'Primeiro semestre', dataInicio: '2027-02-10', dataFim: '2027-02-13' },
      { titulo: 'Resultado da pré-seleção', descricao: 'Chamada única', dataInicio: '2027-02-18' },
      { titulo: 'Complementação da inscrição', descricao: 'Para os pré-selecionados', dataInicio: '2027-02-19', dataFim: '2027-02-23' },
    ],
  },
  {
    sigla: 'Fies Social',
    nome: 'Fies Social',
    tipo: 'FINANCIAMENTO',
    descricao: 'Modalidade do Fies para estudantes de famílias inscritas no Cadastro Único, com financiamento de até 100% da mensalidade.',
    comoFunciona: 'A inscrição é a mesma do Fies. Parte das vagas é reservada a quem está no CadÚnico, e o financiamento pode cobrir a mensalidade inteira.',
    requisitos: 'Família inscrita no Cadastro Único com renda de até meio salário mínimo por pessoa, além das regras gerais do Fies.',
    linkOficial: 'https://acessounico.mec.gov.br/fies',
    imagemUrl: null,
    eventos: [{ titulo: 'Inscrições junto com o Fies', descricao: 'Mesmo período do Fies 2027', dataInicio: '2027-02-10', dataFim: '2027-02-13' }],
  },
  {
    sigla: 'ProUni',
    nome: 'Programa Universidade para Todos',
    tipo: 'BOLSA',
    descricao: 'Programa do governo federal que oferece bolsas integrais e parciais (50%) em instituições privadas de ensino superior.',
    comoFunciona: 'A seleção usa a nota do Enem. O estudante escolhe até duas opções de curso e, se for selecionado, comprova as informações na instituição.',
    requisitos: 'Ter feito o Enem com média de pelo menos 450 pontos e nota acima de zero na redação. Bolsa integral: renda familiar de até 1,5 salário mínimo por pessoa; parcial: até 3 salários mínimos.',
    linkOficial: 'https://acessounico.mec.gov.br/prouni',
    imagemUrl: 'assets/img/programas/prouni.svg',
    eventos: [
      { titulo: 'Inscrições do ProUni 2027', descricao: 'Primeiro semestre', dataInicio: '2027-01-26', dataFim: '2027-01-29' },
      { titulo: 'Primeira chamada', descricao: 'Resultado no portal', dataInicio: '2027-02-02' },
      { titulo: 'Segunda chamada', descricao: 'Resultado no portal', dataInicio: '2027-02-16' },
    ],
  },
  {
    sigla: 'Escola da Família',
    nome: 'Programa Escola da Família',
    tipo: 'BOLSA',
    descricao: 'Programa do governo de São Paulo que paga a mensalidade de universitários que atuam aos fins de semana em escolas da rede estadual.',
    comoFunciona: 'O estudante se inscreve no site do programa e, se selecionado, trabalha como educador universitário nas escolas aos sábados e domingos. Em troca, o estado e a instituição custeiam a mensalidade.',
    requisitos: 'Ter cursado o ensino médio em escola pública e estar matriculado em instituição privada conveniada ao programa.',
    linkOficial: 'https://escoladafamilia.educacao.sp.gov.br',
    imagemUrl: null,
    eventos: [{ titulo: 'Inscrições para educadores universitários', descricao: 'Primeiro semestre', dataInicio: '2027-01-11', dataFim: '2027-02-05' }],
  },
];

// Instituições aprovadas. Endereços com ruas reais das cidades e números,
// CEPs, telefones e CNPJs ilustrativos; sites e e-mails em example.com.
const UNIVERSIDADES = [
  {
    chave: 'univale',
    nomeFantasia: 'UniVale Sorocaba',
    razaoSocial: 'Centro Universitário Vale do Sorocaba',
    cnpj: '90000001000100',
    natureza: 'V',
    email: 'univale@example.com',
    responsavel: 'Mariana Torres',
    descricao: 'Centro universitário com cursos de graduação nas áreas de saúde, negócios e tecnologia, com dois campi em Sorocaba e programa próprio de bolsas por mérito.',
    telefonePrincipal: '(15) 3201-4500',
    linkPagina: 'https://www.example.com/univale',
    linkSimulados: 'https://www.example.com/univale/simulados',
    campi: [
      {
        nome: 'Campus Centro',
        principal: true,
        telefoneFixo: '(15) 3201-4500',
        emailCampus: 'centro@example.com',
        endereco: { logradouro: 'Rua XV de Novembro', numero: '1250', bairro: 'Centro', cidade: 'Sorocaba', estado: 'SP', cep: '18010081' },
      },
      {
        nome: 'Campus Campolim',
        principal: false,
        telefoneFixo: '(15) 3201-4600',
        emailCampus: 'campolim@example.com',
        endereco: { logradouro: 'Avenida Antônio Carlos Comitre', numero: '1800', bairro: 'Parque Campolim', cidade: 'Sorocaba', estado: 'SP', cep: '18047620' },
      },
    ],
    cursos: [
      { nome: 'Enfermagem', areaCurso: 'Saúde', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '4', ofertas: [{ campus: 0, turno: 'Integral', vagas: 60 }] },
      { nome: 'Administração', areaCurso: 'Negócios', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', ofertas: [{ campus: 0, turno: 'Noturno', vagas: 100 }, { campus: 1, turno: 'Matutino', vagas: 50 }] },
      { nome: 'Psicologia', areaCurso: 'Saúde', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '5', ofertas: [{ campus: 1, turno: 'Integral', vagas: 80 }] },
      { nome: 'Ciência da Computação', areaCurso: 'Tecnologia', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', ofertas: [{ campus: 1, turno: 'Noturno', vagas: 60 }] },
    ],
    programas: { ENEM: null, VESTIBULAR: 'Vestibular de verão com prova on-line', FIES: 'Até 100% da mensalidade', 'Fies Social': null, ProUni: 'Bolsas integrais e parciais em todos os cursos', 'Escola da Família': 'Conveniada ao programa' },
    bolsas: [
      {
        nome: 'Bolsa Mérito UniVale',
        sigla: 'Mérito',
        descricao: 'Desconto de 50% na mensalidade durante todo o curso para os dez primeiros colocados no vestibular de cada curso.',
        requisitos: 'Classificação entre os dez primeiros do curso no vestibular e frequência mínima de 75% em cada semestre.',
        comoFunciona: 'A bolsa é aplicada na matrícula e renovada a cada semestre enquanto o aluno mantiver média 7 e a frequência mínima.',
        eventos: [
          { titulo: 'Inscrições do vestibular de verão', descricao: 'Pelo site da instituição', dataInicio: '2026-11-03', dataFim: '2026-12-04' },
          { titulo: 'Prova do vestibular', descricao: 'Campus Centro', dataInicio: '2026-12-06' },
        ],
      },
    ],
  },
  {
    chave: 'uesp',
    nomeFantasia: 'UESP',
    razaoSocial: 'Universidade Estadual do Sudoeste Paulista',
    cnpj: '90000002000100',
    natureza: 'P',
    email: 'uesp@example.com',
    responsavel: 'Carlos Henrique Prado',
    descricao: 'Universidade pública estadual com campi em Sorocaba e Itapetininga. Ingresso pelo SiSU e pelo Provão Paulista, sem mensalidade.',
    telefonePrincipal: '(15) 3229-8000',
    linkPagina: 'https://www.example.com/uesp',
    linkSimulados: 'https://www.example.com/uesp/simulados',
    campi: [
      {
        nome: 'Campus Sorocaba',
        principal: true,
        telefoneFixo: '(15) 3229-8000',
        emailCampus: 'sorocaba@example.com',
        endereco: { logradouro: 'Rodovia João Leme dos Santos', numero: 'km 110', bairro: 'Itinga', cidade: 'Sorocaba', estado: 'SP', cep: '18052780' },
      },
      {
        nome: 'Campus Itapetininga',
        principal: false,
        telefoneFixo: '(15) 3271-2200',
        emailCampus: 'itapetininga@example.com',
        endereco: { logradouro: 'Avenida Padre Antônio Brunetti', numero: '1360', bairro: 'Vila Rio Branco', cidade: 'Itapetininga', estado: 'SP', cep: '18208080' },
      },
    ],
    cursos: [
      { nome: 'Engenharia de Produção', areaCurso: 'Engenharia', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '5', ofertas: [{ campus: 0, turno: 'Integral', vagas: 40 }] },
      { nome: 'Pedagogia', areaCurso: 'Humanas', grau: 'Licenciatura', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', ofertas: [{ campus: 1, turno: 'Noturno', vagas: 45 }] },
      { nome: 'Ciências Biológicas', areaCurso: 'Saúde', grau: 'Licenciatura', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '5', ofertas: [{ campus: 0, turno: 'Integral', vagas: 30 }] },
      { nome: 'Geografia', areaCurso: 'Humanas', grau: 'Licenciatura', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', ofertas: [{ campus: 1, turno: 'Noturno', vagas: 40 }] },
    ],
    programas: { ENEM: null, SiSU: 'Todas as vagas de ampla concorrência e cotas', Provão: '15% das vagas de cada curso' },
    bolsas: [],
  },
  {
    chave: 'fvt',
    nomeFantasia: 'Faculdade Votorantim de Tecnologia',
    razaoSocial: 'Faculdade Votorantim de Tecnologia Ltda.',
    cnpj: '90000003000100',
    natureza: 'V',
    email: 'fvt@example.com',
    responsavel: 'Renata Gouveia',
    descricao: 'Faculdade de cursos tecnológicos de dois a três anos, com aulas à noite e foco em empregabilidade na indústria da região.',
    telefonePrincipal: '(15) 3243-7100',
    linkPagina: 'https://www.example.com/fvt',
    linkSimulados: 'https://www.example.com/fvt/simulados',
    campi: [
      {
        nome: 'Unidade Votorantim',
        principal: true,
        telefoneFixo: '(15) 3243-7100',
        emailCampus: 'secretaria@example.com',
        endereco: { logradouro: 'Avenida 31 de Março', numero: '520', bairro: 'Centro', cidade: 'Votorantim', estado: 'SP', cep: '18110005' },
      },
    ],
    cursos: [
      { nome: 'Análise e Desenvolvimento de Sistemas', areaCurso: 'Tecnologia', grau: 'Tecnólogo', modalidade: 'Presencial', duracaoSemestres: 5, notaMec: '4', ofertas: [{ campus: 0, turno: 'Noturno', vagas: 80 }] },
      { nome: 'Gestão de Recursos Humanos', areaCurso: 'Negócios', grau: 'Tecnólogo', modalidade: 'Presencial', duracaoSemestres: 4, notaMec: '3', ofertas: [{ campus: 0, turno: 'Noturno', vagas: 60 }] },
      { nome: 'Logística', areaCurso: 'Negócios', grau: 'Tecnólogo', modalidade: 'Presencial', duracaoSemestres: 4, notaMec: '4', ofertas: [{ campus: 0, turno: 'Noturno', vagas: 60 }] },
    ],
    programas: { ENEM: 'Nota do Enem no lugar da prova', VESTIBULAR: null, ProUni: null, FIES: null },
    bolsas: [],
  },
  {
    chave: 'feitu',
    nomeFantasia: 'FEITU',
    razaoSocial: 'Faculdade de Engenharia de Itu',
    cnpj: '90000004000100',
    natureza: 'V',
    email: 'feitu@example.com',
    responsavel: 'Paulo Sérgio Rinaldi',
    descricao: 'Faculdade de engenharia com laboratórios abertos à comunidade e parceria com empresas do polo industrial de Itu e Salto.',
    telefonePrincipal: '(11) 4022-3300',
    linkPagina: 'https://www.example.com/feitu',
    linkSimulados: 'https://www.example.com/feitu/simulados',
    campi: [
      {
        nome: 'Campus Itu',
        principal: true,
        telefoneFixo: '(11) 4022-3300',
        emailCampus: 'atendimento@example.com',
        endereco: { logradouro: 'Rua Floriano Peixoto', numero: '870', bairro: 'Centro', cidade: 'Itu', estado: 'SP', cep: '13300005' },
      },
    ],
    cursos: [
      { nome: 'Engenharia Civil', areaCurso: 'Engenharia', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '4', ofertas: [{ campus: 0, turno: 'Noturno', vagas: 50 }] },
      { nome: 'Engenharia Mecânica', areaCurso: 'Engenharia', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '4', ofertas: [{ campus: 0, turno: 'Noturno', vagas: 50 }] },
      { nome: 'Engenharia Elétrica', areaCurso: 'Engenharia', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '3', ofertas: [{ campus: 0, turno: 'Integral', vagas: 40 }] },
    ],
    programas: { ENEM: null, VESTIBULAR: null, FIES: 'Até 80% da mensalidade', ProUni: null },
    bolsas: [
      {
        nome: 'Bolsa Engenheiras do Futuro',
        sigla: null,
        descricao: 'Bolsa de 40% para estudantes mulheres egressas de escola pública nos cursos de engenharia.',
        requisitos: 'Ter cursado todo o ensino médio em escola pública e ser aprovada no vestibular da FEITU.',
        comoFunciona: 'A candidata indica o interesse na inscrição do vestibular e entrega o histórico escolar na matrícula.',
        eventos: [{ titulo: 'Inscrição junto com o vestibular', descricao: 'Primeiro semestre de 2027', dataInicio: '2026-11-10', dataFim: '2027-01-29' }],
      },
    ],
  },
  {
    chave: 'unitatui',
    nomeFantasia: 'UniTatuí',
    razaoSocial: 'Centro Universitário de Tatuí',
    cnpj: '90000005000100',
    natureza: 'V',
    email: 'unitatui@example.com',
    responsavel: 'Fernanda Lopes',
    descricao: 'Centro universitário com tradição em licenciaturas e cursos da área de saúde, a uma hora de Sorocaba.',
    telefonePrincipal: '(15) 3251-9000',
    linkPagina: 'https://www.example.com/unitatui',
    linkSimulados: 'https://www.example.com/unitatui/simulados',
    campi: [
      {
        nome: 'Campus Tatuí',
        principal: true,
        telefoneFixo: '(15) 3251-9000',
        emailCampus: 'secretaria@example.com',
        endereco: { logradouro: 'Rua Onze de Agosto', numero: '1024', bairro: 'Centro', cidade: 'Tatuí', estado: 'SP', cep: '18270000' },
      },
    ],
    cursos: [
      { nome: 'Nutrição', areaCurso: 'Saúde', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', ofertas: [{ campus: 0, turno: 'Noturno', vagas: 50 }] },
      { nome: 'Pedagogia', areaCurso: 'Humanas', grau: 'Licenciatura', modalidade: 'EAD', duracaoSemestres: 8, notaMec: '4', ofertas: [{ campus: 0, turno: 'Noturno', vagas: 120 }] },
      { nome: 'Educação Física', areaCurso: 'Saúde', grau: 'Licenciatura', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '3', ofertas: [{ campus: 0, turno: 'Matutino', vagas: 60 }] },
    ],
    programas: { ENEM: null, VESTIBULAR: null, ProUni: null, FIES: null, 'Escola da Família': null },
    bolsas: [],
  },
  {
    chave: 'fams',
    nomeFantasia: 'Faculdade Municipal de Salto',
    razaoSocial: 'Fundação Educacional Municipal de Salto',
    cnpj: '90000006000100',
    natureza: 'P',
    email: 'fams@example.com',
    responsavel: 'Rogério Antunes',
    descricao: 'Faculdade pública municipal, sem mensalidade, com ingresso por vestibular próprio e pela nota do Enem.',
    telefonePrincipal: '(11) 4602-5500',
    linkPagina: 'https://www.example.com/fams',
    linkSimulados: 'https://www.example.com/fams/simulados',
    campi: [
      {
        nome: 'Campus Salto',
        principal: true,
        telefoneFixo: '(11) 4602-5500',
        emailCampus: 'vestibular@example.com',
        endereco: { logradouro: 'Avenida Dom Pedro II', numero: '1500', bairro: 'Centro', cidade: 'Salto', estado: 'SP', cep: '13320240' },
      },
    ],
    cursos: [
      { nome: 'Ciências Contábeis', areaCurso: 'Negócios', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', ofertas: [{ campus: 0, turno: 'Noturno', vagas: 50 }] },
      { nome: 'Turismo', areaCurso: 'Humanas', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 6, notaMec: '3', ofertas: [{ campus: 0, turno: 'Noturno', vagas: 40 }] },
    ],
    programas: { ENEM: '30% das vagas pela nota do Enem', VESTIBULAR: 'Prova em dezembro' },
    bolsas: [],
  },
];

// Para demonstrar a aprovação (RF23): uma pendente e uma reprovada.
const UNIVERSIDADE_PENDENTE = {
  nomeFantasia: 'FCS Boituva',
  razaoSocial: 'Faculdade de Ciências da Saúde de Boituva',
  cnpj: '90000007000100',
  natureza: 'V',
  email: 'fcsboituva@example.com',
  responsavel: 'Juliana Mattos',
  descricao: 'Faculdade nova, com cursos de Enfermagem e Fisioterapia previstos para 2027.',
  telefonePrincipal: '(15) 3363-1200',
  linkPagina: 'https://www.example.com/fcsboituva',
  linkSimulados: 'https://www.example.com/fcsboituva/simulados',
  campus: {
    nome: 'Campus Boituva',
    telefoneFixo: '(15) 3363-1200',
    emailCampus: 'contato@example.com',
    endereco: { logradouro: 'Avenida Vereador José Ângelo Biagioni', numero: '400', bairro: 'Centro', cidade: 'Boituva', estado: 'SP', cep: '18550000' },
  },
  programas: ['ENEM', 'VESTIBULAR', 'FIES'],
};

const UNIVERSIDADE_REPROVADA = {
  nomeFantasia: 'ISE Piedade',
  razaoSocial: 'Instituto Superior de Educação de Piedade',
  cnpj: '90000008000100',
  natureza: 'V',
  email: 'isepiedade@example.com',
  responsavel: 'Antônio Bastos',
  descricao: 'Instituto com cursos de licenciatura.',
  telefonePrincipal: '(15) 3244-0800',
  linkPagina: 'https://www.example.com/isepiedade',
  linkSimulados: 'https://www.example.com/isepiedade/simulados',
  motivo: 'O CNPJ informado não corresponde à razão social cadastrada. Envie o cadastro de novo com o CNPJ da mantenedora.',
  campus: {
    nome: 'Campus Piedade',
    telefoneFixo: '(15) 3244-0800',
    emailCampus: 'secretaria@example.com',
    endereco: { logradouro: 'Rua Barão de Piedade', numero: '210', bairro: 'Centro', cidade: 'Piedade', estado: 'SP', cep: '18170000' },
  },
  programas: ['VESTIBULAR'],
};

// Avaliações dos dois alunos de demonstração. Beatriz ainda não avaliou a
// UESP, a UniTatuí e a FAMS, para a avaliação ao vivo.
const AVALIACOES = [
  { aluno: 'beatriz', universidade: 'univale', nota: 5, comentario: 'Fiz o vestibular de verão e consegui a Bolsa Mérito. Os laboratórios de Enfermagem são muito bem equipados.' },
  { aluno: 'beatriz', universidade: 'fvt', nota: 4, comentario: 'Curso de ADS bem prático e com aulas à noite, dá para trabalhar durante o dia. A biblioteca é pequena.' },
  { aluno: 'beatriz', universidade: 'feitu', nota: 4, comentario: 'Professores com experiência na indústria. O transporte de Sorocaba até Itu à noite é o ponto difícil.' },
  { aluno: 'lucas', universidade: 'univale', nota: 4, comentario: 'Boa estrutura no Campus Campolim. A secretaria demorou para responder sobre o Fies.' },
  { aluno: 'lucas', universidade: 'uesp', nota: 5, comentario: 'Entrei pelo SiSU. Universidade pública com ótimos professores e projetos de pesquisa desde o primeiro ano.' },
  { aluno: 'lucas', universidade: 'unitatui', nota: 3, comentario: 'Curso de Nutrição bom, mas faltam horários de estágio para quem trabalha.' },
];

module.exports = { CONTAS, PROGRAMAS, UNIVERSIDADES, UNIVERSIDADE_PENDENTE, UNIVERSIDADE_REPROVADA, AVALIACOES };
