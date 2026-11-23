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
// quem está no ensino médio, sem números de mercado ou salário. Casos para a
// página do curso com universidades diferentes:
// - Pedagogia: presencial na UESP (8 semestres) e a distância na UniTatuí
//   (7 semestres), com descrições diferentes: o resumo mostra a faixa de
//   duração e "Sobre o curso" ganha uma aba por universidade;
// - Educação Física: licenciatura na UniTatuí e bacharelado na UniVale (mesmo
//   nome, graus diferentes);
// - Análise e Desenvolvimento de Sistemas: na FAMS foi cadastrado sem acento
//   e em minúsculas; a página pública junta as duas grafias, exibe a da
//   Faculdade Votorantim (cadastrada antes) e o administrador encontra o
//   caso no filtro "nomes parecidos".
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

  educacaoFisicaBacharelado: `## O que você estuda

Educação Física estuda o movimento humano, o esporte e a atividade física como parte da saúde. Este curso é um **bacharelado**, voltado ao trabalho fora da escola: academias, clubes, equipes esportivas e programas de saúde.

- **Ciências do corpo:** anatomia, fisiologia do exercício e biomecânica.
- **Treinamento esportivo** e prescrição de exercícios.
- **Atividade física e saúde** para crianças, adultos e idosos.
- **Esportes, lutas, danças e ginástica.**
- **Gestão de academias e eventos esportivos.**
- **Estágios** em academias, clubes e serviços de saúde.

## Onde pode trabalhar

- Academias e estúdios, como orientador de exercícios e personal trainer.
- Clubes e equipes esportivas, na preparação física de atletas.
- Programas de saúde e qualidade de vida em empresas e unidades de saúde.
- Recreação, lazer e eventos esportivos.

## Perfil de quem escolhe o curso

Combina com quem gosta de esporte e de cuidar da saúde das pessoas. Para dar aula em escolas, o caminho é a licenciatura.`,

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
// imagens do app (assets/img/programas). A descrição traz as seções da página
// do programa; "como funciona" e "requisitos" estão dentro dela, por isso os
// campos próprios ficam vazios.
const PROGRAMAS = [
  {
    sigla: 'ENEM',
    nome: 'Exame Nacional do Ensino Médio',
    tipo: 'ENTRADA',
    descricao: `## O que é

Prova nacional do Inep que avalia quem concluiu ou está concluindo o ensino médio. A nota é usada no SiSU, no ProUni, no FIES e em vestibulares de instituições privadas.

Com uma única prova, você pode concorrer a vagas em universidades públicas pelo SiSU, a bolsas pelo ProUni e a financiamento pelo FIES, além de usar a nota em vestibulares de faculdades particulares.

## Quem pode participar

- Quem está cursando o último ano do ensino médio.
- Quem já concluiu o ensino médio.
- Estudantes de escola pública e de famílias de baixa renda podem pedir **isenção da taxa** de inscrição.

## Como funciona

- A inscrição é feita na **Página do Participante**.
- As provas acontecem em **dois domingos**.
- No primeiro domingo: Linguagens, Ciências Humanas e Redação.
- No segundo domingo: Matemática e Ciências da Natureza.
- As notas saem na Página do Participante.

## Documentos normalmente pedidos

- CPF, para fazer a inscrição.
- Documento oficial de identificação com foto, no dia de cada prova.
- Para pedir a isenção da taxa, os comprovantes que o edital indicar.

## Passo a passo

1. Acompanhe a divulgação do edital e o período de inscrição.
2. Se tiver direito, peça a isenção da taxa no prazo do edital.
3. Faça a inscrição na Página do Participante.
4. Antes da prova, confira o local onde você vai fazer o exame.
5. Faça as provas nos dois domingos.
6. Consulte suas notas na Página do Participante e use-as no SiSU, no ProUni, no FIES ou em vestibulares.

As regras, as datas e os documentos podem mudar a cada edição. Confira sempre o edital no [site oficial do Inep](https://www.gov.br/inep/pt-br/areas-de-atuacao/avaliacao-e-exames-educacionais/enem).`,
    comoFunciona: null,
    requisitos: null,
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
    descricao: `## O que é

Sistema do MEC que seleciona estudantes para vagas em instituições públicas de ensino superior usando a nota do Enem.

O SiSU não tem prova própria: a seleção usa a nota que você tirou no Enem, comparada com a dos outros candidatos que escolheram o mesmo curso.

## Quem pode participar

- Quem fez a edição mais recente do Enem.
- Quem não tirou zero na redação.

## Como funciona

- Na inscrição, você escolhe até **duas opções** de curso.
- Durante o período de inscrição, o sistema mostra a **nota de corte parcial** de cada opção.
- Você pode trocar as opções até o encerramento das inscrições.
- O resultado da chamada regular sai no portal Acesso Único.
- Quem não for selecionado pode manifestar interesse na **lista de espera**.

## Documentos normalmente pedidos

Quem é selecionado faz a matrícula na instituição, que costuma pedir:

- Documento de identificação com foto e CPF.
- Histórico escolar e certificado de conclusão do ensino médio.
- Comprovante de residência.
- Para as vagas reservadas, os comprovantes que o edital da instituição indicar.

## Passo a passo

1. Faça o Enem e confira suas notas.
2. Acompanhe o período de inscrição no portal Acesso Único.
3. Inscreva-se e escolha até duas opções de curso.
4. Acompanhe a nota de corte parcial e, se quiser, troque as opções até o fim das inscrições.
5. Veja o resultado da chamada regular.
6. Se for selecionado, faça a matrícula no prazo. Se não for, manifeste interesse na lista de espera.

As regras e as datas podem mudar a cada edição. Confira sempre o edital no [portal Acesso Único do MEC](https://acessounico.mec.gov.br/sisu).`,
    comoFunciona: null,
    requisitos: null,
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
    descricao: `## O que é

Avaliação seriada do governo de São Paulo para estudantes da rede pública estadual, com vagas em universidades estaduais paulistas e nas Fatecs.

"Seriada" quer dizer que a avaliação acompanha o estudante ao longo do ensino médio, com uma prova em cada ano, em vez de uma prova única no final.

## Quem pode participar

- Estudantes matriculados no ensino médio da **rede pública estadual de São Paulo**.

## Como funciona

- Os estudantes fazem **uma prova em cada ano** do ensino médio, na própria escola.
- As notas das três séries formam a **nota final**.
- A nota final é usada na escolha das vagas.
- Na 3ª série, o estudante escolhe os cursos no período indicado.
- As chamadas são divulgadas no site da Vunesp.

## Documentos normalmente pedidos

Quem é convocado faz a matrícula na instituição, que costuma pedir:

- Documento de identificação com foto e CPF.
- Histórico escolar e certificado de conclusão do ensino médio.
- Outros documentos que o edital da instituição indicar.

## Passo a passo

1. Faça as provas em cada ano do ensino médio, na sua escola.
2. Na 3ª série, acompanhe o período de escolha de cursos.
3. Escolha os cursos no prazo.
4. Acompanhe a divulgação das chamadas no site da Vunesp.
5. Se for convocado, faça a matrícula na instituição no prazo.

As regras e as datas podem mudar a cada edição. Confira sempre o edital no [site oficial do Provão Paulista](https://provaopaulista.vunesp.com.br).`,
    comoFunciona: null,
    requisitos: null,
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
    descricao: `## O que é

Processo seletivo próprio de cada instituição, com edital, provas e calendário definidos por ela.

Como cada instituição faz o seu, as regras mudam de uma para outra: o tipo de prova, as datas e o número de vagas aparecem no edital de cada vestibular.

## Quem pode participar

- Quem tiver concluído o ensino médio até a data da matrícula.

## Como funciona

- Cada instituição publica o **edital** com as datas de inscrição e de prova.
- Muitas instituições privadas também aceitam a **nota do Enem** no lugar da prova.
- Na região, os vestibulares de verão costumam acontecer no fim do ano, e os de inverno, para o segundo semestre, no meio do ano.

## Documentos normalmente pedidos

- Documento de identificação com foto e CPF, na inscrição e no dia da prova.
- Na matrícula, histórico escolar e certificado de conclusão do ensino médio.
- Outros documentos que o edital indicar.

## Passo a passo

1. Escolha as instituições e os cursos que interessam a você.
2. Leia o edital de cada vestibular.
3. Faça a inscrição no prazo e, se o edital permitir, decida entre fazer a prova ou usar a nota do Enem.
4. Faça a prova na data marcada.
5. Acompanhe o resultado e, se for aprovado, faça a matrícula no prazo.

Cada instituição tem as próprias regras. Confira sempre o edital no site oficial da instituição: o link está na página de cada universidade aqui no Guia Jovem, no botão "Acessar página da faculdade".`,
    comoFunciona: null,
    requisitos: null,
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
    descricao: `## O que é

Programa do MEC que financia a graduação em instituições privadas participantes, com pagamento depois da formatura.

É um financiamento para pagar a faculdade: a devolução do valor financiado começa depois que você se forma, em parcelas. As condições de cada contrato estão no edital.

## Quem pode participar

- Quem fez o Enem a partir de 2010, com **média de pelo menos 450 pontos** e nota acima de zero na redação.
- Quem tem renda familiar de até **três salários mínimos por pessoa**.

## Como funciona

- Você se inscreve com a nota do Enem e escolhe o curso.
- Se for **pré-selecionado**, confirma os dados na instituição e no banco.
- O pagamento começa depois da conclusão do curso, em parcelas de acordo com a renda.

## Documentos normalmente pedidos

- Documento de identificação com foto e CPF.
- Comprovantes de renda das pessoas da família.
- Comprovante de residência.
- Na instituição e no banco, os documentos que o edital indicar para a contratação.

## Passo a passo

1. Confira se sua nota do Enem e a renda da família atendem às regras.
2. Acompanhe o período de inscrição no portal Acesso Único.
3. Inscreva-se e escolha o curso.
4. Veja o resultado da pré-seleção.
5. Se for pré-selecionado, complemente a inscrição no prazo.
6. Confirme os dados na instituição e no banco.

As regras, as datas e as condições podem mudar a cada edição. Confira sempre o edital no [portal Acesso Único do MEC](https://acessounico.mec.gov.br/fies).`,
    comoFunciona: null,
    requisitos: null,
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
    descricao: `## O que é

Modalidade do Fies para estudantes de famílias inscritas no Cadastro Único, com financiamento de até 100% da mensalidade.

O Cadastro Único (CadÚnico) é o cadastro do governo federal das famílias de baixa renda. O Fies Social usa esse cadastro para reservar vagas a quem mais precisa.

## Quem pode participar

- Estudantes de família inscrita no **Cadastro Único**, com renda de até **meio salário mínimo por pessoa**.
- Além disso, é preciso atender às regras gerais do Fies.

## Como funciona

- A inscrição é a **mesma do Fies**, no mesmo período.
- Parte das vagas é reservada a quem está no CadÚnico.
- O financiamento pode cobrir a mensalidade inteira.

## Documentos normalmente pedidos

- Os mesmos do Fies: identificação com foto, CPF, comprovantes de renda da família e de residência.
- Os dados da família no Cadastro Único devem estar atualizados.
- Outros documentos que o edital indicar.

## Passo a passo

1. Confira se sua família está no Cadastro Único e se os dados estão em dia.
2. Confira se você atende às regras gerais do Fies.
3. Inscreva-se no Fies no período de inscrição, pelo portal Acesso Único.
4. Acompanhe o resultado e siga as etapas do Fies.

As regras e as datas podem mudar a cada edição. Confira sempre o edital no [portal Acesso Único do MEC](https://acessounico.mec.gov.br/fies).`,
    comoFunciona: null,
    requisitos: null,
    linkOficial: 'https://acessounico.mec.gov.br/fies',
    imagemUrl: null,
    eventos: [{ titulo: 'Inscrições junto com o Fies', descricao: 'Mesmo período do Fies 2027', dataInicio: '2027-02-10', dataFim: '2027-02-13' }],
  },
  {
    sigla: 'ProUni',
    nome: 'Programa Universidade para Todos',
    tipo: 'BOLSA',
    descricao: `## O que é

Programa do governo federal que oferece bolsas integrais e parciais (50%) em instituições privadas de ensino superior.

Na bolsa integral, você não paga a mensalidade; na parcial, paga metade. Não é empréstimo: o valor da bolsa não precisa ser devolvido.

## Quem pode participar

- Quem fez o Enem com **média de pelo menos 450 pontos** e nota acima de zero na redação.
- **Bolsa integral:** renda familiar de até 1,5 salário mínimo por pessoa.
- **Bolsa parcial:** renda familiar de até 3 salários mínimos por pessoa.

## Como funciona

- A seleção usa a **nota do Enem**.
- Na inscrição, você escolhe até **duas opções** de curso.
- O resultado sai em chamadas, no portal.
- Se for selecionado, você comprova as informações na instituição.

## Documentos normalmente pedidos

- Documento de identificação com foto e CPF.
- Comprovantes de renda das pessoas da família.
- Comprovante de residência.
- Histórico escolar e outros documentos que o edital indicar.

## Passo a passo

1. Confira se sua nota do Enem e a renda da família atendem às regras.
2. Acompanhe o período de inscrição no portal Acesso Único.
3. Inscreva-se e escolha até duas opções de curso.
4. Acompanhe a primeira e a segunda chamada.
5. Se for selecionado, leve os documentos à instituição no prazo.

As regras, as datas e as faixas de renda podem mudar a cada edição. Confira sempre o edital no [portal Acesso Único do MEC](https://acessounico.mec.gov.br/prouni).`,
    comoFunciona: null,
    requisitos: null,
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
    descricao: `## O que é

Programa do governo de São Paulo que paga a mensalidade de universitários que atuam aos fins de semana em escolas da rede estadual.

O estudante participa como **educador universitário**, ajudando nas atividades abertas à comunidade que acontecem nas escolas aos sábados e domingos.

## Quem pode participar

- Quem cursou o ensino médio em **escola pública**.
- Quem está matriculado em uma **instituição privada conveniada** ao programa.

## Como funciona

- O estudante se inscreve no site do programa.
- Se for selecionado, trabalha como educador universitário nas escolas **aos sábados e domingos**.
- Em troca, o estado e a instituição custeiam a mensalidade.

## Documentos normalmente pedidos

- Documento de identificação com foto e CPF.
- Comprovante de matrícula na instituição conveniada.
- Histórico escolar do ensino médio, para comprovar que foi cursado em escola pública.
- Outros documentos que o edital indicar.

## Passo a passo

1. Confira se a sua faculdade é conveniada ao programa.
2. Acompanhe o período de inscrição no site do programa.
3. Faça a inscrição no prazo.
4. Acompanhe o resultado da seleção.
5. Se for selecionado, siga as orientações para começar a atuar na escola.

As regras e as datas podem mudar a cada edição. Confira sempre o edital no [site oficial do Programa Escola da Família](https://escoladafamilia.educacao.sp.gov.br).`,
    comoFunciona: null,
    requisitos: null,
    linkOficial: 'https://escoladafamilia.educacao.sp.gov.br',
    imagemUrl: null,
    eventos: [{ titulo: 'Inscrições para educadores universitários', descricao: 'Primeiro semestre', dataInicio: '2027-01-11', dataFim: '2027-02-05' }],
  },
];

// Instituições aprovadas. Endereços com ruas reais das cidades e números,
// CEPs, telefones e CNPJs ilustrativos; sites e e-mails em example.com.
// O "Sobre" é fictício, coerente com o porte e a cidade de cada uma.
const UNIVERSIDADES = [
  {
    chave: 'univale',
    nomeFantasia: 'UniVale Sorocaba',
    razaoSocial: 'Centro Universitário Vale do Sorocaba',
    cnpj: '90000001000100',
    natureza: 'V',
    email: 'univale@example.com',
    responsavel: 'Mariana Torres',
    descricao: `Centro universitário com cursos de graduação nas áreas de saúde, negócios e tecnologia, com dois campi em Sorocaba e programa próprio de bolsas por mérito.

O **Campus Centro**, perto do comércio e dos terminais de ônibus da cidade, concentra os cursos de saúde e as turmas da noite. O **Campus Campolim**, em uma região de crescimento da zona sul, reúne os cursos de tecnologia, Psicologia e as turmas da manhã de Administração.

A proposta da UniVale é unir teoria e prática desde o primeiro ano, com professores que também atuam no mercado e projetos feitos em parceria com empresas e serviços de saúde de Sorocaba.

Para quem precisa de ajuda com a mensalidade, a instituição aceita o ProUni, o Fies e o Programa Escola da Família, além de oferecer a **Bolsa Mérito UniVale** aos melhores colocados no vestibular.

## Diferenciais

- **Infraestrutura:** laboratórios de saúde com simuladores, laboratórios de informática e biblioteca nos dois campi.
- **Apoio ao estudante:** núcleo de atendimento psicopedagógico, monitorias e plantão de dúvidas nas disciplinas básicas.
- **Estágios:** central de estágios com vagas em hospitais, clínicas e empresas da região.
- **Clínica-escola de Psicologia** com atendimento à comunidade.`,
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
      { nome: 'Educação Física', areaCurso: 'Saúde', grau: 'Bacharelado', modalidade: 'Presencial', duracaoSemestres: 8, notaMec: '4', descricao: CURSOS.educacaoFisicaBacharelado, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 50 }] },
    ],
    programas: { ENEM: null, VESTIBULAR: 'Vestibular de verão com prova on-line', FIES: 'Até 100% da mensalidade', 'Fies Social': null, ProUni: 'Bolsas integrais e parciais em todos os cursos', 'Escola da Família': 'Conveniada ao programa' },
    bolsas: [
      {
        nome: 'Bolsa Mérito UniVale',
        sigla: 'Mérito',
        descricao: `Desconto de 50% na mensalidade durante todo o curso para os dez primeiros colocados no vestibular de cada curso.

## Critérios

- Ficar entre os **dez primeiros colocados** do curso no vestibular da UniVale.
- Manter **média 7** nas disciplinas.
- Ter **frequência mínima de 75%** em cada semestre.

## Percentual

- **50% de desconto** na mensalidade, durante todo o curso.
- A bolsa é renovada a cada semestre enquanto os critérios forem mantidos.

## Prazo

- Inscrições do vestibular de verão: de 3 de novembro a 4 de dezembro de 2026, pelo site da instituição.
- Prova do vestibular: 6 de dezembro de 2026, no Campus Centro.

## Como se inscrever

1. Faça a inscrição no vestibular de verão pelo site da UniVale.
2. Faça a prova na data marcada.
3. Se ficar entre os dez primeiros do seu curso, a bolsa é aplicada na matrícula, sem pedido separado.`,
        requisitos: null,
        comoFunciona: null,
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
    descricao: `Universidade pública estadual com campi em Sorocaba e Itapetininga. Ingresso pelo SiSU e pelo Provão Paulista, sem mensalidade.

Criada para levar o ensino superior público ao sudoeste do estado, a UESP oferece bacharelados em engenharia e licenciaturas que formam professores para as escolas da região.

O **Campus Sorocaba**, às margens da rodovia, reúne os laboratórios de engenharia e de biologia. O **Campus Itapetininga** concentra as licenciaturas noturnas, pensadas para quem trabalha durante o dia.

Além do ensino, a universidade mantém grupos de pesquisa e projetos de extensão abertos à comunidade, em que os estudantes participam desde os primeiros semestres.

## Diferenciais

- **Infraestrutura:** laboratórios de engenharia e de ciências biológicas, biblioteca e área verde para aulas de campo.
- **Apoio ao estudante:** programas de permanência estudantil, restaurante universitário e moradia para estudantes de outras cidades.
- **Estágios:** parcerias com indústrias da região e com escolas públicas para os estágios das licenciaturas.
- **Iniciação científica** com orientação de professores pesquisadores.`,
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
    descricao: `Faculdade de cursos tecnológicos de dois a três anos, com aulas à noite e foco em empregabilidade na indústria da região.

A FVT funciona em uma unidade no centro de Votorantim, a poucos minutos de Sorocaba, e foi pensada para quem trabalha durante o dia e quer uma formação superior mais curta e prática.

Os cursos de tecnologia, gestão de pessoas e logística foram desenhados com a participação de empresas da região, e boa parte das aulas acontece em laboratórios e em projetos com problemas reais.

A faculdade aceita a nota do Enem no lugar da prova do vestibular e participa do ProUni e do Fies.

## Diferenciais

- **Infraestrutura:** laboratórios de informática com acesso fora do horário de aula e salas preparadas para trabalhos em grupo.
- **Apoio ao estudante:** aulas de nivelamento em matemática e português no primeiro semestre e atendimento da coordenação à noite.
- **Estágios:** banco de vagas com empresas de Votorantim e Sorocaba e feira de carreiras uma vez por semestre.`,
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
    descricao: `Faculdade de engenharia com laboratórios abertos à comunidade e parceria com empresas do polo industrial de Itu e Salto.

Instalada no centro histórico de Itu, a FEITU é uma faculdade de porte médio dedicada só à engenharia, com turmas menores e contato próximo com os professores.

As aulas práticas acontecem em laboratórios de materiais, de máquinas e de instalações elétricas, que também recebem estudantes do ensino médio da região em visitas e oficinas.

Para incentivar a presença feminina na engenharia, a faculdade mantém a **Bolsa Engenheiras do Futuro**, voltada a estudantes mulheres egressas de escola pública.

## Diferenciais

- **Infraestrutura:** laboratórios de materiais de construção, de máquinas térmicas e de eletrotécnica.
- **Apoio ao estudante:** monitoria em cálculo e física e grupos de estudo organizados pelos próprios alunos.
- **Estágios:** parcerias com empresas do polo industrial de Itu e Salto, com visitas técnicas desde o primeiro ano.
- **Equipes de competição** em projetos de engenharia.`,
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
        descricao: `Bolsa de 40% para estudantes mulheres egressas de escola pública nos cursos de engenharia.

## Critérios

- Ser **estudante mulher**.
- Ter cursado **todo o ensino médio em escola pública**.
- Ser aprovada no vestibular da FEITU em um dos cursos de engenharia.

## Percentual

- **40% de desconto** na mensalidade.

## Prazo

- Inscrição junto com o vestibular do primeiro semestre de 2027, de 10 de novembro de 2026 a 29 de janeiro de 2027.

## Como se inscrever

1. Faça a inscrição no vestibular da FEITU e indique o interesse na bolsa no formulário.
2. Faça a prova ou use a nota do Enem, conforme o edital do vestibular.
3. Se for aprovada, entregue o histórico escolar do ensino médio na matrícula.`,
        requisitos: null,
        comoFunciona: null,
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
    descricao: `Centro universitário com tradição em licenciaturas e cursos da área de saúde, a uma hora de Sorocaba.

A UniTatuí atende estudantes de Tatuí e das cidades vizinhas e é conhecida pela formação de professores. O curso de Pedagogia é oferecido a distância, com encontros presenciais no campus, para quem não consegue frequentar aulas todos os dias.

Os cursos de Nutrição e Educação Física aproveitam a estrutura de laboratórios e de esporte do campus e mantêm projetos de atendimento à comunidade, como orientação alimentar e atividades físicas para crianças e idosos.

A instituição aceita o ProUni, o Fies e o Programa Escola da Família, que ajudam boa parte dos estudantes a pagar a mensalidade.

## Diferenciais

- **Infraestrutura:** laboratório de técnica dietética, ginásio poliesportivo e polo de apoio aos alunos a distância.
- **Apoio ao estudante:** tutoria para os cursos a distância e atendimento financeiro para orientar sobre bolsas e financiamento.
- **Estágios:** convênios com escolas da região e com a rede municipal de saúde de Tatuí.`,
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
      { nome: 'Pedagogia', areaCurso: 'Humanas', grau: 'Licenciatura', modalidade: 'EAD', duracaoSemestres: 7, notaMec: '4', descricao: CURSOS.pedagogiaEad, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 120 }] },
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
    descricao: `Faculdade pública municipal, sem mensalidade, com ingresso por vestibular próprio e pela nota do Enem.

Mantida por uma fundação do município, a FAMS é uma faculdade pequena, com três graduações noturnas e turmas que permitem acompanhar cada estudante de perto.

O curso de Turismo aproveita os atrativos naturais e históricos de Salto e da região em aulas de campo, e o curso de Ciências Contábeis mantém um núcleo que orienta pequenos empreendedores da cidade.

Parte das vagas é preenchida pela nota do Enem, e o restante pelo vestibular próprio, com prova em dezembro.

## Diferenciais

- **Infraestrutura:** laboratório de informática com programas de contabilidade e biblioteca com acervo da área de turismo.
- **Apoio ao estudante:** acompanhamento da coordenação desde o primeiro semestre e aulas de reforço em matemática.
- **Estágios:** parcerias com escritórios de contabilidade, hotéis e a secretaria de turismo do município.`,
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
      // Grafia diferente de propósito (sem acento e em minúsculas): ver o comentário de CURSOS.
      { nome: 'Analise e desenvolvimento de sistemas', areaCurso: 'Tecnologia', grau: 'Tecnólogo', modalidade: 'Presencial', duracaoSemestres: 5, notaMec: '3', descricao: CURSOS.ads, ofertas: [{ campus: 0, turno: 'Noturno', vagas: 40 }] },
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
