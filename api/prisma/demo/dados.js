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
 *
 * As descrições longas (cursos, "Sobre" das universidades, programas e bolsas)
 * usam a formatação simples que o app exibe: parágrafos, subtítulos (##),
 * listas (- e 1.), negrito (**), itálico (_) e links ([texto](endereço)).
 * Os textos dos programas reais só repetem as regras já registradas aqui e
 * terminam mandando conferir o edital no site oficial.
 */

const CONTAS = {
  admin: { nome: 'Equipe Guia Jovem', email: 'admin@demo.guiajovem.com.br' },
  alunos: [
    { chave: 'beatriz', nome: 'Beatriz Almeida', email: 'beatriz@demo.guiajovem.com.br' },
    { chave: 'lucas', nome: 'Lucas Pereira', email: 'lucas@demo.guiajovem.com.br' },
  ],
};

// Descrição de cada curso: conteúdo geral da área, em linguagem simples para
// quem está no ensino médio, sem números de mercado ou salário. Pedagogia tem
// duas versões (presencial na UESP e a distância na UniTatuí): com descrições
// diferentes, a página do curso mostra cada uma dentro do card da universidade.
const CURSOS = {
  enfermagem: `## O que você estuda

Enfermagem forma o profissional que cuida da saúde das pessoas em todas as fases da vida, da prevenção ao tratamento. A primeira parte do curso traz a base comum da área da saúde; depois vêm as disciplinas do cuidado, com muitas aulas práticas.

- **Ciências da saúde:** anatomia, fisiologia, microbiologia e farmacologia.
- **Cuidado de enfermagem:** procedimentos, curativos, sinais vitais e administração de medicamentos.
- **Saúde coletiva:** vacinação, prevenção de doenças e atendimento nas unidades de saúde.
- **Gestão:** organização das equipes e dos serviços de saúde.
- **Estágios supervisionados** em hospitais, unidades básicas de saúde e outros serviços.

## Onde pode trabalhar

- Hospitais e clínicas, em enfermarias, centros cirúrgicos e unidades de terapia intensiva.
- Unidades básicas de saúde e programas de saúde da família.
- Atendimento domiciliar e cuidado de idosos.
- Empresas, na área de saúde do trabalhador, e escolas.
- Ensino e pesquisa, depois de uma pós-graduação.

## Perfil de quem escolhe o curso

Combina com quem gosta de cuidar de pessoas, mantém a calma em situações de pressão e trabalha bem em equipe. O dia a dia pede atenção aos detalhes, responsabilidade e disposição para turnos variados.`,

  administracao: `## O que você estuda

Administração ensina a planejar, organizar e acompanhar o funcionamento de empresas e outras organizações, sejam elas pequenas, grandes, públicas ou do terceiro setor.

- **Gestão de pessoas:** recrutamento, liderança e trabalho em equipe.
- **Finanças e contabilidade:** custos, orçamento e análise de resultados.
- **Marketing:** como entender o cliente e divulgar produtos e serviços.
- **Produção e logística:** processos, estoques e qualidade.
- **Direito, economia e estatística** aplicados aos negócios.
- **Empreendedorismo:** como criar e fazer crescer um negócio próprio.

## Onde pode trabalhar

- Empresas de qualquer setor, nas áreas administrativa, financeira, comercial ou de recursos humanos.
- Bancos e cooperativas.
- Órgãos públicos, por meio de concurso.
- Consultoria para outras empresas.
- No próprio negócio.

## Perfil de quem escolhe o curso

É uma boa escolha para quem gosta de organizar, resolver problemas e lidar com pessoas. Ajuda ter facilidade para se comunicar, tomar decisões e trabalhar com números do dia a dia.`,

  psicologia: `## O que você estuda

Psicologia estuda o comportamento humano e os processos mentais, como emoções, pensamento, memória e relações entre as pessoas. O curso combina teoria, pesquisa e prática supervisionada.

- **Bases da psicologia:** desenvolvimento humano, personalidade e processos de aprendizagem.
- **Biologia do comportamento:** neurociências e funcionamento do sistema nervoso.
- **Abordagens teóricas:** as diferentes formas de entender e acompanhar uma pessoa.
- **Avaliação psicológica:** entrevistas, testes e observação.
- **Psicologia social e institucional:** grupos, famílias, escolas e organizações.
- **Estágios supervisionados** em clínica-escola, serviços de saúde, escolas e empresas.

## Onde pode trabalhar

- Consultório e clínicas, no atendimento de crianças, jovens e adultos.
- Hospitais e serviços públicos de saúde e de assistência social.
- Escolas, no apoio ao aprendizado e à convivência.
- Empresas, em seleção, treinamento e qualidade de vida no trabalho.
- Projetos sociais, esporte e pesquisa.

## Perfil de quem escolhe o curso

Combina com quem tem interesse genuíno pelas pessoas, sabe ouvir sem julgar e gosta de ler e refletir. O curso pede bastante leitura e maturidade para lidar com histórias e emoções difíceis.`,

  computacao: `## O que você estuda

Ciência da Computação estuda como os computadores funcionam e como criar programas e sistemas que resolvem problemas. É um curso com base forte em matemática e lógica, além de muita programação.

- **Programação:** várias linguagens, estruturas de dados e algoritmos.
- **Matemática:** cálculo, álgebra, lógica e matemática discreta.
- **Sistemas:** arquitetura de computadores, sistemas operacionais e redes.
- **Banco de dados e engenharia de software:** como planejar, construir e testar sistemas.
- **Temas avançados:** inteligência artificial, segurança da informação e computação gráfica.
- **Projetos** individuais e em grupo ao longo do curso.

## Onde pode trabalhar

- Empresas de tecnologia e de software, como desenvolvedor ou analista.
- Equipes de tecnologia de bancos, indústrias, comércio e órgãos públicos.
- Áreas de dados, segurança da informação e infraestrutura.
- Pesquisa e ensino, depois de uma pós-graduação.
- Empresas próprias e projetos independentes.

## Perfil de quem escolhe o curso

É indicado para quem gosta de lógica, de entender como as coisas funcionam por dentro e de resolver problemas com paciência. Curiosidade e vontade de aprender sempre ajudam, porque a tecnologia muda rápido.`,

  producao: `## O que você estuda

Engenharia de Produção une a base de engenharia com a gestão. O engenheiro de produção planeja e melhora processos para que uma empresa produza com qualidade, segurança e menos desperdício.

- **Base de engenharia:** cálculo, física, química e desenho técnico.
- **Processos produtivos:** como fábricas e serviços se organizam.
- **Qualidade e melhoria contínua:** métodos para reduzir erros e perdas.
- **Logística e cadeia de suprimentos:** compras, estoques e transporte.
- **Economia, custos e projetos:** como decidir onde investir.
- **Ergonomia e segurança do trabalho.**

## Onde pode trabalhar

- Indústrias de todos os tipos, no planejamento e no controle da produção.
- Empresas de logística, comércio e serviços.
- Áreas de qualidade, projetos e melhoria de processos.
- Consultoria e gestão de operações.

## Perfil de quem escolhe o curso

Combina com quem gosta de matemática, mas também de pessoas e de organização. É para quem fica incomodado com desperdício e gosta de pensar em formas melhores de fazer as coisas.`,

  pedagogia: `## O que você estuda

Pedagogia forma o professor da educação infantil e dos anos iniciais do ensino fundamental, além do profissional que organiza e acompanha o trabalho das escolas.

- **Fundamentos da educação:** história, filosofia, sociologia e psicologia da educação.
- **Didática:** como planejar aulas e avaliar o aprendizado.
- **Alfabetização e ensino** de língua portuguesa, matemática, ciências, história e geografia para crianças.
- **Educação inclusiva** e atendimento às diferenças.
- **Gestão escolar:** coordenação pedagógica e organização da escola.
- **Estágios** em escolas, acompanhando turmas e professores.

## Onde pode trabalhar

- Escolas públicas e particulares, como professor da educação infantil e dos anos iniciais.
- Coordenação pedagógica e direção de escolas.
- Educação de jovens e adultos.
- Empresas, em treinamento e desenvolvimento de pessoas.
- ONGs, bibliotecas, museus e projetos sociais.

## Perfil de quem escolhe o curso

Combina com quem gosta de ensinar, tem paciência com crianças e acredita que a educação muda vidas. Criatividade, boa comunicação e vontade de estar sempre aprendendo fazem diferença.`,

  pedagogiaEad: `## O que você estuda

Nesta universidade, Pedagogia é oferecida **a distância**: a maior parte das aulas é on-line, com materiais, atividades e encontros pelo ambiente virtual, e você organiza o próprio horário de estudo. O curso forma o professor da educação infantil e dos anos iniciais do ensino fundamental.

- **Fundamentos da educação:** história, filosofia, sociologia e psicologia da educação.
- **Didática e alfabetização:** como planejar aulas e ensinar crianças a ler, escrever e calcular.
- **Educação inclusiva** e tecnologias na educação.
- **Gestão escolar:** coordenação pedagógica e organização da escola.
- **Atividades presenciais e estágios** em escolas, conforme o calendário do curso.

## Onde pode trabalhar

- Escolas públicas e particulares, como professor da educação infantil e dos anos iniciais.
- Coordenação pedagógica e direção de escolas.
- Educação de jovens e adultos e educação a distância.
- Empresas, em treinamento de pessoas, e projetos sociais.

## Perfil de quem escolhe o curso

Além do gosto por ensinar, o curso a distância pede **disciplina e organização**: é preciso reservar horários fixos de estudo e manter o ritmo sem a rotina da sala de aula. Combina com quem trabalha durante o dia ou mora longe da universidade.`,

  biologia: `## O que você estuda

Ciências Biológicas estuda a vida em todas as formas, das células aos ecossistemas. Nesta universidade o curso é uma **licenciatura**, que forma o professor de Ciências e de Biologia, sem deixar de lado a pesquisa e as aulas de campo.

- **Biologia celular, genética e evolução.**
- **Zoologia e botânica:** animais e plantas, sua diversidade e classificação.
- **Ecologia e meio ambiente:** relações entre os seres vivos e conservação.
- **Corpo humano:** anatomia, fisiologia e saúde.
- **Didática e prática de ensino** de Ciências e Biologia.
- **Aulas de laboratório, saídas de campo e estágios** em escolas.

## Onde pode trabalhar

- Escolas, como professor de Ciências no ensino fundamental e de Biologia no ensino médio.
- Cursinhos e projetos de educação ambiental.
- Museus, zoológicos, jardins botânicos e parques.
- Pesquisa em universidades e institutos, depois de uma pós-graduação.

## Perfil de quem escolhe o curso

É para quem tem curiosidade sobre a natureza, gosta de observar e de investigar e quer compartilhar o que aprende. Gostar de explicar e de conviver com adolescentes ajuda muito na licenciatura.`,

  geografia: `## O que você estuda

Geografia estuda a relação entre a sociedade e o espaço: como as pessoas ocupam o território, usam os recursos naturais e transformam as paisagens. Este curso é uma **licenciatura**, voltada à formação do professor.

- **Geografia física:** clima, relevo, solos, rios e vegetação.
- **Geografia humana:** população, cidades, campo, economia e política.
- **Cartografia:** leitura e produção de mapas, inclusive com ferramentas digitais.
- **Questões ambientais** e regionais do Brasil e do mundo.
- **Didática e prática de ensino** de Geografia.
- **Trabalhos de campo e estágios** em escolas.

## Onde pode trabalhar

- Escolas, como professor de Geografia no ensino fundamental e médio.
- Cursinhos e produção de material didático.
- Projetos de educação ambiental e de planejamento urbano, em equipes de várias áreas.
- Pesquisa, depois de uma pós-graduação.

## Perfil de quem escolhe o curso

Combina com quem gosta de entender o mundo, acompanha notícias, se interessa por mapas e viagens e quer discutir esses temas em sala de aula.`,

  ads: `## O que você estuda

Análise e Desenvolvimento de Sistemas é um curso **tecnólogo**, mais curto e prático, que forma o profissional que cria, testa e mantém sistemas e aplicativos.

- **Lógica e programação** em diferentes linguagens.
- **Desenvolvimento web e mobile:** sites, sistemas e aplicativos.
- **Banco de dados:** como guardar e consultar informações.
- **Engenharia de software:** levantamento de requisitos, testes e trabalho em equipe.
- **Redes, segurança e sistemas operacionais** em nível básico.
- **Projetos práticos** desde os primeiros semestres.

## Onde pode trabalhar

- Empresas de software e de tecnologia, como programador ou analista de sistemas.
- Equipes de tecnologia de indústrias, comércio, bancos e órgãos públicos.
- Suporte e testes de sistemas.
- Projetos próprios e trabalho como autônomo.

## Perfil de quem escolhe o curso

É indicado para quem gosta de computador, de lógica e de ver o resultado do trabalho funcionando. Por ser mais curto e muitas vezes noturno, combina com quem quer entrar logo no mercado ou já trabalha durante o dia.`,

  rh: `## O que você estuda

Gestão de Recursos Humanos é um curso **tecnólogo** que forma o profissional responsável por cuidar das pessoas dentro das organizações, do processo de contratação ao desenvolvimento da carreira.

- **Recrutamento e seleção:** como encontrar e escolher os profissionais certos.
- **Treinamento e desenvolvimento** de equipes.
- **Rotinas de departamento pessoal:** folha de pagamento, benefícios e legislação trabalhista.
- **Cargos, salários e avaliação de desempenho.**
- **Comunicação, liderança e clima organizacional.**
- **Saúde e qualidade de vida no trabalho.**

## Onde pode trabalhar

- Departamentos de recursos humanos de empresas de qualquer setor.
- Agências de recrutamento e de emprego.
- Consultorias de gestão de pessoas.
- Hospitais, escolas, órgãos públicos e ONGs.

## Perfil de quem escolhe o curso

Combina com quem gosta de conversar, tem empatia, sabe guardar informações com discrição e gosta de ajudar as pessoas a crescerem no trabalho.`,

  logistica: `## O que você estuda

Logística é um curso **tecnólogo** que ensina a planejar o caminho dos produtos, da compra da matéria-prima até a entrega ao cliente, com o menor custo e no prazo certo.

- **Gestão de estoques e armazenagem.**
- **Transporte e distribuição:** rotas, modais e frota.
- **Compras e cadeia de suprimentos.**
- **Custos logísticos** e indicadores de desempenho.
- **Comércio exterior** e documentação de cargas.
- **Tecnologia** aplicada ao controle de mercadorias.

## Onde pode trabalhar

- Indústrias, nos setores de compras, produção e expedição.
- Centros de distribuição, transportadoras e operadores logísticos.
- Comércio varejista e atacadista, inclusive lojas on-line.
- Empresas de importação e exportação.

## Perfil de quem escolhe o curso

É uma boa escolha para quem é organizado, gosta de planejar e de resolver imprevistos rapidamente. Facilidade com números e com planilhas ajuda bastante.`,

  civil: `## O que você estuda

Engenharia Civil forma o profissional que projeta, constrói e mantém edificações e obras de infraestrutura, como casas, prédios, pontes, estradas e redes de água e esgoto.

- **Base de engenharia:** cálculo, física, química e desenho técnico.
- **Estruturas:** concreto, aço e madeira, e como calcular o que sustenta uma obra.
- **Materiais de construção** e técnicas construtivas.
- **Solos e fundações.**
- **Hidráulica e saneamento.**
- **Transportes, topografia e gestão de obras.**

## Onde pode trabalhar

- Construtoras e incorporadoras, em projetos e no canteiro de obras.
- Escritórios de projeto e de cálculo estrutural.
- Órgãos públicos de obras, transporte e saneamento.
- Empresas de manutenção, perícia e avaliação de imóveis.

## Perfil de quem escolhe o curso

Combina com quem gosta de matemática e física, tem boa noção de espaço e quer ver o próprio trabalho virar algo concreto. O curso pede dedicação aos cálculos e senso de responsabilidade com a segurança das pessoas.`,

  mecanica: `## O que você estuda

Engenharia Mecânica estuda máquinas, motores, equipamentos e sistemas que envolvem movimento, energia e calor. O engenheiro mecânico projeta, fabrica e cuida da manutenção desses sistemas.

- **Base de engenharia:** cálculo, física, química e desenho técnico.
- **Mecânica dos sólidos e resistência dos materiais.**
- **Termodinâmica e mecânica dos fluidos:** calor, energia e escoamento.
- **Processos de fabricação:** usinagem, soldagem e conformação.
- **Projeto de máquinas** com programas de desenho por computador.
- **Automação, manutenção e laboratórios.**

## Onde pode trabalhar

- Indústrias automotivas, metalúrgicas, de máquinas e de equipamentos.
- Empresas de energia, climatização e refrigeração.
- Áreas de manutenção industrial e de projetos.
- Consultoria e assistência técnica.

## Perfil de quem escolhe o curso

É indicado para quem gosta de desmontar coisas para entender como funcionam, tem afinidade com matemática e física e gosta de resolver problemas práticos.`,

  eletrica: `## O que você estuda

Engenharia Elétrica estuda a geração, a transmissão e o uso da energia elétrica, além dos circuitos e dos sistemas eletrônicos que estão em quase tudo ao nosso redor.

- **Base de engenharia:** cálculo, física e programação.
- **Circuitos elétricos e eletrônica.**
- **Máquinas elétricas:** motores, geradores e transformadores.
- **Sistemas de energia:** geração, transmissão, distribuição e instalações elétricas.
- **Controle e automação** de processos.
- **Energias renováveis** e eficiência energética.

## Onde pode trabalhar

- Empresas de geração e distribuição de energia.
- Indústrias, em automação, manutenção e projetos elétricos.
- Empresas de telecomunicações e de equipamentos eletrônicos.
- Projetos de instalações em construções e de energia solar.

## Perfil de quem escolhe o curso

Combina com quem tem facilidade com matemática e física, gosta de eletrônica e tecnologia e tem paciência para testes e medições cuidadosas.`,

  nutricao: `## O que você estuda

Nutrição estuda os alimentos e a forma como eles afetam a saúde das pessoas. O nutricionista orienta a alimentação de indivíduos e de grupos, da prevenção de doenças ao cuidado de quem está em tratamento.

- **Ciências da saúde:** anatomia, fisiologia, bioquímica e microbiologia.
- **Composição dos alimentos** e técnica dietética.
- **Avaliação nutricional:** como acompanhar o estado de saúde pela alimentação.
- **Nutrição clínica** em diferentes doenças e fases da vida.
- **Alimentação coletiva:** cozinhas industriais, restaurantes e merenda escolar.
- **Nutrição esportiva e saúde pública.**

## Onde pode trabalhar

- Hospitais, clínicas e consultórios.
- Restaurantes, cozinhas industriais e serviços de alimentação.
- Escolas, na alimentação escolar.
- Academias e clubes esportivos.
- Indústria de alimentos e unidades de saúde.

## Perfil de quem escolhe o curso

É indicado para quem se interessa por saúde e por comida, gosta de ciências e de conversar com as pessoas para entender a rotina delas.`,

  educacaoFisica: `## O que você estuda

Educação Física estuda o movimento humano, o esporte, o jogo e a atividade física como parte da saúde e da educação. Este curso é uma **licenciatura**, voltada ao professor de Educação Física nas escolas.

- **Ciências do corpo:** anatomia, fisiologia e cinesiologia.
- **Esportes, danças, lutas, jogos e ginástica.**
- **Desenvolvimento motor** de crianças e adolescentes.
- **Educação física escolar e inclusiva.**
- **Didática e prática de ensino.**
- **Estágios** em escolas da educação básica.

## Onde pode trabalhar

- Escolas públicas e particulares, como professor de Educação Física.
- Projetos esportivos e sociais com crianças e jovens.
- Clubes e escolinhas de esporte, em atividades educativas.
- Recreação e lazer.

## Perfil de quem escolhe o curso

Combina com quem gosta de esporte e de atividade física, tem energia para trabalhar com turmas e acredita no movimento como parte da formação das pessoas.`,

  contabeis: `## O que você estuda

Ciências Contábeis forma o profissional que registra, analisa e explica a situação financeira de empresas e de pessoas, ajudando nas decisões e no cumprimento das obrigações fiscais.

- **Contabilidade geral, de custos e gerencial.**
- **Legislação tributária e trabalhista.**
- **Análise de demonstrações financeiras.**
- **Auditoria e perícia contábil.**
- **Matemática financeira e estatística.**
- **Sistemas de informação** usados na contabilidade.

## Onde pode trabalhar

- Escritórios de contabilidade.
- Departamentos financeiros e contábeis de empresas.
- Auditoria e consultoria.
- Órgãos públicos, por meio de concurso.
- No próprio escritório.

## Perfil de quem escolhe o curso

É uma boa escolha para quem é organizado, atento aos detalhes e gosta de números. Também pede ética e cuidado com prazos, porque o trabalho envolve informações importantes das empresas.`,

  turismo: `## O que você estuda

Turismo forma o profissional que planeja e organiza viagens, eventos e experiências, e que ajuda cidades e regiões a receberem bem os visitantes, cuidando da cultura e do meio ambiente.

- **Planejamento turístico** de cidades e regiões.
- **Agenciamento e operação** de viagens.
- **Hotelaria, gastronomia e eventos.**
- **Patrimônio cultural e natural.**
- **Marketing e empreendedorismo** no turismo.
- **Línguas estrangeiras** e atendimento ao público.

## Onde pode trabalhar

- Agências de viagem e operadoras de turismo.
- Hotéis, pousadas, parques e empresas de eventos.
- Secretarias e órgãos públicos de turismo e cultura.
- Projetos de turismo rural, cultural e de natureza.
- No próprio negócio.

## Perfil de quem escolhe o curso

Combina com quem gosta de viajar, de conhecer culturas e de lidar com pessoas. Criatividade, organização e boa comunicação fazem diferença.`,
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
      { nome: 'Enfermagem', areaCurso: 'Saúde', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '4', descricao: CURSOS.enfermagem, ofertas: [{ campus: 0, turno: 'Integral', vagas: 60 }] },
      { nome: 'Administração', areaCurso: 'Negócios', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', descricao: CURSOS.administracao, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 100 }, { campus: 1, turno: 'Matutino', vagas: 50 }] },
      { nome: 'Psicologia', areaCurso: 'Saúde', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '5', descricao: CURSOS.psicologia, ofertas: [{ campus: 1, turno: 'Integral', vagas: 80 }] },
      { nome: 'Ciência da Computação', areaCurso: 'Tecnologia', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', descricao: CURSOS.computacao, ofertas: [{ campus: 1, turno: 'Noturno', vagas: 60 }] },
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
      { nome: 'Engenharia de Produção', areaCurso: 'Engenharia', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '5', descricao: CURSOS.producao, ofertas: [{ campus: 0, turno: 'Integral', vagas: 40 }] },
      { nome: 'Pedagogia', areaCurso: 'Humanas', grau: 'Licenciatura', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', descricao: CURSOS.pedagogia, ofertas: [{ campus: 1, turno: 'Noturno', vagas: 45 }] },
      { nome: 'Ciências Biológicas', areaCurso: 'Saúde', grau: 'Licenciatura', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '5', descricao: CURSOS.biologia, ofertas: [{ campus: 0, turno: 'Integral', vagas: 30 }] },
      { nome: 'Geografia', areaCurso: 'Humanas', grau: 'Licenciatura', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', descricao: CURSOS.geografia, ofertas: [{ campus: 1, turno: 'Noturno', vagas: 40 }] },
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
      { nome: 'Análise e Desenvolvimento de Sistemas', areaCurso: 'Tecnologia', grau: 'Tecnólogo', modalidade: 'Presencial', duracaoSemestres: 5, notaMec: '4', descricao: CURSOS.ads, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 80 }] },
      { nome: 'Gestão de Recursos Humanos', areaCurso: 'Negócios', grau: 'Tecnólogo', modalidade: 'Presencial', duracaoSemestres: 4, notaMec: '3', descricao: CURSOS.rh, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 60 }] },
      { nome: 'Logística', areaCurso: 'Negócios', grau: 'Tecnólogo', modalidade: 'Presencial', duracaoSemestres: 4, notaMec: '4', descricao: CURSOS.logistica, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 60 }] },
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
      { nome: 'Engenharia Civil', areaCurso: 'Engenharia', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '4', descricao: CURSOS.civil, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 50 }] },
      { nome: 'Engenharia Mecânica', areaCurso: 'Engenharia', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '4', descricao: CURSOS.mecanica, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 50 }] },
      { nome: 'Engenharia Elétrica', areaCurso: 'Engenharia', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 10, notaMec: '3', descricao: CURSOS.eletrica, ofertas: [{ campus: 0, turno: 'Integral', vagas: 40 }] },
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
      { nome: 'Nutrição', areaCurso: 'Saúde', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', descricao: CURSOS.nutricao, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 50 }] },
      { nome: 'Pedagogia', areaCurso: 'Humanas', grau: 'Licenciatura', modalidade: 'EAD', duracaoSemestres: 8, notaMec: '4', descricao: CURSOS.pedagogiaEad, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 120 }] },
      { nome: 'Educação Física', areaCurso: 'Saúde', grau: 'Licenciatura', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '3', descricao: CURSOS.educacaoFisica, ofertas: [{ campus: 0, turno: 'Matutino', vagas: 60 }] },
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
      { nome: 'Ciências Contábeis', areaCurso: 'Negócios', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', descricao: CURSOS.contabeis, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 50 }] },
      { nome: 'Turismo', areaCurso: 'Humanas', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 6, notaMec: '3', descricao: CURSOS.turismo, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 40 }] },
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
// diasAtras: quando a avaliação foi feita, contando da gravação dos dados,
// para as datas não saírem todas no mesmo dia.
const AVALIACOES = [
  { aluno: 'beatriz', universidade: 'univale', diasAtras: 41, nota: 5, comentario: 'Fiz o vestibular de verão e consegui a Bolsa Mérito. Os laboratórios de Enfermagem são muito bem equipados.' },
  { aluno: 'beatriz', universidade: 'fvt', diasAtras: 18, nota: 4, comentario: 'Curso de ADS bem prático e com aulas à noite, dá para trabalhar durante o dia. A biblioteca é pequena.' },
  { aluno: 'beatriz', universidade: 'feitu', diasAtras: 9, nota: 4, comentario: 'Professores com experiência na indústria. O transporte de Sorocaba até Itu à noite é o ponto difícil.' },
  { aluno: 'lucas', universidade: 'univale', diasAtras: 33, nota: 4, comentario: 'Boa estrutura no Campus Campolim. A secretaria demorou para responder sobre o Fies.' },
  { aluno: 'lucas', universidade: 'uesp', diasAtras: 64, nota: 5, comentario: 'Entrei pelo SiSU. Universidade pública com ótimos professores e projetos de pesquisa desde o primeiro ano.' },
  { aluno: 'lucas', universidade: 'unitatui', diasAtras: 5, nota: 3, comentario: 'Curso de Nutrição bom, mas faltam horários de estágio para quem trabalha.' },
];

module.exports = { CONTAS, CURSOS, PROGRAMAS, UNIVERSIDADES, UNIVERSIDADE_PENDENTE, UNIVERSIDADE_REPROVADA, AVALIACOES };
