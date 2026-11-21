/**
 * Pontos da conferência de ponta a ponta, na ordem em que a banca veria o
 * sistema: visitante, aluno, universidade (cadastro, reprovação, reenvio,
 * aprovação e painel), administrador e o que só o banco mostra. Cada ponto
 * depende do estado deixado pelos anteriores.
 */
const crypto = require('crypto');

function falhar(mensagem) {
  throw new Error(mensagem);
}

function conferir(condicao, mensagem) {
  if (!condicao) falhar(mensagem);
}

function resumo(corpo) {
  const texto = typeof corpo === 'string' ? corpo : JSON.stringify(corpo);
  return texto.length > 300 ? `${texto.slice(0, 300)}...` : texto;
}

function status(resposta, esperado) {
  conferir(resposta.status === esperado, `esperava ${esperado}, recebeu ${resposta.status}: ${resumo(resposta.corpo)}`);
  return resposta.corpo;
}

function criarRoteiro({ chamar, prisma, log, admin, base }) {
  const sufixo = Date.now().toString(36);
  const estado = {};
  const pontos = [];
  const ponto = (nome, executar) => pontos.push({ nome, executar });

  const aluno = { nome: 'Aluna Conferência', email: `aluna.${sufixo}@exemplo.com`, senha: 'senha-aluna-1' };
  const aluno2 = { nome: 'Aluno Excluído', email: `aluno2.${sufixo}@exemplo.com`, senha: 'senha-aluno-2' };
  const contaUniversidade = { nome: 'Responsável Conferência', email: `uni.${sufixo}@exemplo.com`, senha: 'senha-uni-1' };
  const nomeUniversidade = `Faculdade Conferência ${sufixo}`;

  // ---------------------------------------------------------------- Visitante
  ponto('API no ar e documentação OpenAPI em /docs', async () => {
    status(await chamar('GET', '/health'), 200);
    const docs = await fetch(`${new URL(base).origin}/docs/`);
    conferir(docs.status === 200, `/docs respondeu ${docs.status}`);
  });

  ponto('Home: destaques de universidades e de programas de entrada (RF04)', async () => {
    const universidades = status(await chamar('GET', '/universidades/destaques'), 200).data;
    conferir(universidades.length > 0, 'nenhuma universidade em destaque');
    const programas = status(await chamar('GET', '/programas/destaques?tipo=ENTRADA'), 200).data;
    conferir(programas.length > 0 && programas.every((p) => p.tipo === 'ENTRADA'), 'destaques de entrada com outro tipo');
  });

  ponto('Pesquisa dinâmica com filtros de cidade e programa (RF04)', async () => {
    const todas = status(await chamar('GET', '/universidades'), 200);
    conferir(todas.data.length >= 3, `esperava as universidades do seed, veio ${todas.data.length}`);
    estado.universidadeSeed = todas.data.find((u) => u.nomeFantasia === 'Fatec Sorocaba') ?? todas.data[0];
    const sorocaba = status(await chamar('GET', '/universidades?cidade=Sorocaba'), 200).data;
    conferir(sorocaba.length >= 1, 'filtro de cidade sem resultado');
    conferir(sorocaba.every((u) => JSON.stringify(u).includes('Sorocaba')), 'filtro de cidade trouxe outra cidade');
    const programas = status(await chamar('GET', '/programas?tipo=FINANCIAMENTO'), 200).data;
    conferir(programas.length >= 1, 'nenhum programa de financiamento');
    estado.fies = programas.find((p) => p.sigla === 'FIES') ?? programas[0];
    const comFies = status(await chamar('GET', `/universidades?programaId=${estado.fies.id}`), 200).data;
    conferir(comFies.length >= 1, 'filtro por programa sem resultado');
  });

  ponto('Detalhe da universidade com campi, cursos, avaliações e links (RF03)', async () => {
    const id = estado.universidadeSeed.id;
    const detalhe = status(await chamar('GET', `/universidades/${id}`), 200).data;
    conferir(detalhe.nomeFantasia, 'detalhe sem nome');
    conferir(detalhe.linkPagina, 'detalhe sem o link da página oficial');
    const campus = status(await chamar('GET', `/universidades/${id}/campus`), 200).data;
    conferir(campus.length >= 1, 'universidade sem campus');
    estado.campusSeed = campus[0];
    const cursos = status(await chamar('GET', `/universidades/${id}/cursos`), 200).data;
    conferir(cursos.length >= 1, 'universidade sem cursos');
    const avaliacoes = status(await chamar('GET', `/universidades/${id}/avaliacoes`), 200).data;
    conferir(avaliacoes.length >= 1, 'universidade sem avaliações');
    const detalheCampus = status(await chamar('GET', `/campus/${estado.campusSeed.id}`), 200).data;
    conferir(detalheCampus.id === estado.campusSeed.id, 'detalhe do campus diferente');
  });

  ponto('Detalhe do programa com datas importantes e universidades que aceitam (RF25)', async () => {
    const programa = status(await chamar('GET', `/programas/${estado.fies.id}`), 200).data;
    conferir(Array.isArray(programa.eventos) && programa.eventos.length > 0, 'programa sem datas importantes');
    const aceitam = status(await chamar('GET', `/programas/${estado.fies.id}/universidades`), 200).data;
    conferir(aceitam.length >= 1, 'nenhuma universidade aceita o FIES');
  });

  ponto('Relatório da pesquisa em CSV e em PDF, baixado como o app baixa (RF02)', async () => {
    // O app (em outra origem) baixa o arquivo por requisição: precisa da
    // liberação do CORS e do nome do arquivo exposto, senão o download falha.
    const APP = 'http://localhost:8080';
    const login = status(await chamar('POST', '/auth/login', { corpo: { email: admin.email, senha: admin.senha } }), 200).data;
    for (const [quem, token] of [['visitante', undefined], ['usuário logado', login.accessToken]]) {
      const csv = await chamar('GET', '/relatorios/pesquisa?formato=csv&cidade=Sorocaba', { origem: APP, token, cru: true });
      status(csv, 200);
      conferir(csv.tipo.startsWith('text/csv'), `CSV (${quem}) com tipo ${csv.tipo}`);
      conferir(csv.corpo.length > 0 && csv.corpo.toString('utf8').includes('Sorocaba'), `o CSV (${quem}) não chegou com a universidade pesquisada`);
      conferir(csv.cabecalhos.get('access-control-allow-origin') === APP, `o CORS não liberou o CSV para o app (${quem})`);
      conferir(/content-disposition/i.test(csv.cabecalhos.get('access-control-expose-headers') || ''), 'o nome do arquivo não está exposto para o app');
      conferir(/relatorio-pesquisa\.csv/.test(csv.cabecalhos.get('content-disposition') || ''), 'o CSV veio sem nome de arquivo');

      const pdf = await chamar('GET', '/relatorios/pesquisa?formato=pdf', { origem: APP, token, cru: true });
      status(pdf, 200);
      conferir(pdf.tipo === 'application/pdf', `PDF (${quem}) com tipo ${pdf.tipo}`);
      conferir(pdf.corpo.length > 1000 && pdf.corpo.subarray(0, 4).toString() === '%PDF', `o PDF (${quem}) não chegou inteiro`);
      conferir(pdf.cabecalhos.get('access-control-allow-origin') === APP, `o CORS não liberou o PDF para o app (${quem})`);
    }
  });

  // -------------------------------------------------------------------- Aluno
  ponto('Cadastro de aluno já entra logado e grava a senha com hash (RF09, RNF02)', async () => {
    const corpo = status(await chamar('POST', '/auth/register/aluno', { corpo: aluno }), 201).data;
    conferir(corpo.accessToken && corpo.refreshToken, 'cadastro sem tokens');
    conferir(corpo.usuario.tipoUsuario === 'A', 'cadastro não é aluno');
    estado.aluno = { id: corpo.usuario.id, token: corpo.accessToken, refresh: corpo.refreshToken };
    const gravado = await prisma.usuario.findUnique({ where: { id: corpo.usuario.id } });
    conferir(gravado.senhaHash && gravado.senhaHash !== aluno.senha && gravado.senhaHash.startsWith('$2'), 'senha sem hash bcrypt');
    const duplicado = await chamar('POST', '/auth/register/aluno', { corpo: aluno });
    status(duplicado, 409);
  });

  ponto('Login, sessão (/auth/me), renovação e senha errada (RF05)', async () => {
    const errado = await chamar('POST', '/auth/login', { corpo: { email: aluno.email, senha: 'errada-123' } });
    status(errado, 401);
    const login = status(await chamar('POST', '/auth/login', { corpo: { email: aluno.email, senha: aluno.senha } }), 200).data;
    estado.aluno.token = login.accessToken;
    estado.aluno.refresh = login.refreshToken;
    const me = status(await chamar('GET', '/auth/me', { token: estado.aluno.token }), 200).data;
    conferir(me.email === aluno.email, '/auth/me com outro usuário');
    const renovado = status(await chamar('POST', '/auth/refresh', { corpo: { refreshToken: estado.aluno.refresh } }), 200).data;
    estado.aluno.token = renovado.accessToken;
    estado.aluno.refresh = renovado.refreshToken;
  });

  ponto('Avaliar universidade recalcula a média e não aceita a segunda avaliação (RF01)', async () => {
    const id = estado.universidadeSeed.id;
    const antes = await prisma.universidade.findUnique({ where: { id } });
    const criada = await chamar('POST', `/universidades/${id}/avaliacoes`, {
      token: estado.aluno.token,
      corpo: { nota: 1, comentario: 'Avaliação da conferência de ponta a ponta.' },
    });
    estado.avaliacao = status(criada, 201).data;
    const depois = await prisma.universidade.findUnique({ where: { id } });
    conferir(depois.totalAvaliacoes === antes.totalAvaliacoes + 1, 'total de avaliações não aumentou');
    conferir(Number(depois.mediaAvaliacao) < Number(antes.mediaAvaliacao), 'a média não caiu com a nota 1');
    status(await chamar('POST', `/universidades/${id}/avaliacoes`, { token: estado.aluno.token, corpo: { nota: 5 } }), 409);
    const detalhe = status(await chamar('GET', `/universidades/${id}`, { token: estado.aluno.token }), 200).data;
    conferir(detalhe.minhaAvaliacao, 'o detalhe não traz a avaliação do aluno');
  });

  ponto('Editar a própria avaliação (RF01)', async () => {
    const editada = await chamar('PUT', `/avaliacoes/${estado.avaliacao.id}`, {
      token: estado.aluno.token,
      corpo: { nota: 4, comentario: 'Nota revista na conferência.' },
    });
    conferir(status(editada, 200).data.nota === 4, 'a nota não mudou');
  });

  ponto('Salvar universidade, listar em faculdades salvas e remover (RF24)', async () => {
    const id = estado.universidadeSeed.id;
    status(await chamar('POST', '/favoritos/universidades', { token: estado.aluno.token, corpo: { universidadeId: id } }), 201);
    const lista = status(await chamar('GET', '/favoritos/universidades', { token: estado.aluno.token }), 200).data;
    conferir(lista.some((item) => JSON.stringify(item).includes(`"id":${id}`)), 'a faculdade salva não aparece na lista');
    status(await chamar('DELETE', `/favoritos/universidades/${id}`, { token: estado.aluno.token }), 200);
    const vazia = status(await chamar('GET', '/favoritos/universidades', { token: estado.aluno.token }), 200).data;
    conferir(vazia.length === 0, 'a faculdade continua salva');
  });

  ponto('Salvar pesquisa, nome repetido pede outro, reexecutar e excluir (RF04, Quadro 7)', async () => {
    const parametros = { cidade: 'Sorocaba', notaMinima: 1 };
    const criada = await chamar('POST', '/pesquisas-salvas', {
      token: estado.aluno.token,
      corpo: { nome: 'Faculdades em Sorocaba', parametros },
    });
    const pesquisa = status(criada, 201).data;
    const repetida = await chamar('POST', '/pesquisas-salvas', {
      token: estado.aluno.token,
      corpo: { nome: 'FACULDADES EM SOROCABA', parametros },
    });
    conferir(status(repetida, 409).error.code === 'PESQUISA_DUPLICADA', 'código diferente de PESQUISA_DUPLICADA');
    const lista = status(await chamar('GET', '/pesquisas-salvas', { token: estado.aluno.token }), 200).data;
    conferir(lista.length === 1, `esperava 1 pesquisa salva, veio ${lista.length}`);
    const gravada = status(await chamar('GET', `/pesquisas-salvas/${pesquisa.id}`, { token: estado.aluno.token }), 200).data;
    const consulta = new URLSearchParams(gravada.parametros).toString();
    const reexecutada = status(await chamar('GET', `/universidades?${consulta}`), 200).data;
    conferir(reexecutada.length >= 1, 'a pesquisa salva não trouxe resultado');
    status(await chamar('DELETE', `/pesquisas-salvas/${pesquisa.id}`, { token: estado.aluno.token }), 200);
    const depois = status(await chamar('GET', '/pesquisas-salvas', { token: estado.aluno.token }), 200).data;
    conferir(depois.length === 0, 'a pesquisa não foi excluída');
  });

  ponto('Sugestão para a administração notifica os administradores (RF08, RF14)', async () => {
    const criada = await chamar('POST', '/sugestoes', {
      token: estado.aluno.token,
      corpo: { titulo: 'Mais programas de bolsa', texto: 'Seria bom listar as bolsas municipais de Sorocaba também.' },
    });
    estado.sugestaoAdmin = status(criada, 201).data;
    conferir(estado.sugestaoAdmin.status === 'EM_ANALISE', 'a sugestão não nasceu Em análise');
  });

  // ------------------------------------------------------------ Universidade
  ponto('Cadastro de universidade nasce pendente e avisa o administrador (RF09, RF18)', async () => {
    const programas = status(await chamar('GET', '/programas?tipo=ENTRADA'), 200).data;
    const corpo = {
      aceitouTermos: true,
      usuario: contaUniversidade,
      universidade: {
        razaoSocial: `${nomeUniversidade} Ltda.`,
        nomeFantasia: nomeUniversidade,
        cnpj: String(Date.now()).slice(-14).padStart(14, '7'),
        natureza: 'V',
        linkPagina: 'https://conferencia.exemplo.com.br',
      },
      programasIds: [programas[0].id],
      campus: {
        nome: 'Campus Central',
        endereco: { logradouro: 'Rua da Conferência', numero: '100', bairro: 'Centro', cidade: 'Votorantim', estado: 'SP', cep: '18110000' },
      },
    };
    const cadastro = status(await chamar('POST', '/auth/register/universidade', { corpo }), 201).data;
    conferir(cadastro.usuario.universidade?.status === 'P', 'a universidade não nasceu pendente');
    estado.universidade = { id: cadastro.usuario.universidade.id, token: cadastro.accessToken };
    const publica = await chamar('GET', `/universidades/${estado.universidade.id}`);
    conferir(publica.status === 404, `pendente apareceu no site (${publica.status})`);
  });

  ponto('O token do cadastro já abre o painel da própria universidade', async () => {
    const cadastro = await chamar('GET', `/universidades/${estado.universidade.id}/cadastro`, { token: estado.universidade.token });
    conferir(status(cadastro, 200).data.status === 'P', 'painel não mostra a situação pendente');
    const outra = await chamar('GET', `/universidades/${estado.universidadeSeed.id}/gestao/campus`, { token: estado.universidade.token });
    status(outra, 403);
  });

  ponto('Administrador entra e vê a pendente na lista e na notificação (RF23)', async () => {
    const login = status(await chamar('POST', '/auth/login', { corpo: { email: admin.email, senha: admin.senha } }), 200).data;
    estado.admin = { id: login.usuario.id, token: login.accessToken };
    const pendentes = status(await chamar('GET', '/universidades/administracao?status=P', { token: estado.admin.token }), 200);
    conferir(pendentes.data.some((u) => u.id === estado.universidade.id), 'a pendente não está na lista');
    const notificacoes = status(await chamar('GET', '/notificacoes', { token: estado.admin.token }), 200).data;
    conferir(
      notificacoes.some((n) => n.tipo === 'UNIVERSIDADE_PENDENTE' && n.referenciaId === estado.universidade.id),
      'sem notificação UNIVERSIDADE_PENDENTE',
    );
  });

  ponto('Reprovar exige motivo, grava o motivo e notifica a universidade (RF23)', async () => {
    const id = estado.universidade.id;
    status(await chamar('POST', `/universidades/${id}/reprovar`, { token: estado.admin.token, corpo: {} }), 400);
    status(
      await chamar('POST', `/universidades/${id}/reprovar`, {
        token: estado.admin.token,
        corpo: { motivo: 'CNPJ não confere com a razão social.' },
      }),
      200,
    );
    const cadastro = status(await chamar('GET', `/universidades/${id}/cadastro`, { token: estado.universidade.token }), 200).data;
    conferir(cadastro.status === 'R' && cadastro.motivoReprovacao.includes('CNPJ'), 'motivo não chegou à universidade');
    const notificacoes = status(await chamar('GET', '/notificacoes', { token: estado.universidade.token }), 200).data;
    conferir(notificacoes.some((n) => n.tipo === 'UNIVERSIDADE_REPROVADA'), 'sem notificação UNIVERSIDADE_REPROVADA');
    const avisoEmail = log.join('').includes(`para: ${contaUniversidade.email}`);
    conferir(avisoEmail, 'o e-mail da reprovação não foi gerado');
  });

  ponto('Reprovada só corrige a instituição e os campi e reenvia para análise', async () => {
    const id = estado.universidade.id;
    const curso = await chamar('POST', `/universidades/${id}/cursos`, { token: estado.universidade.token, corpo: { nome: 'Direito' } });
    conferir(status(curso, 403).error.code === 'UNIVERSIDADE_NAO_APROVADA', 'reprovada cadastrou curso');
    status(
      await chamar('PATCH', `/universidades/${id}`, {
        token: estado.universidade.token,
        corpo: { razaoSocial: `${nomeUniversidade} Educacional Ltda.` },
      }),
      200,
    );
    status(await chamar('POST', `/universidades/${id}/reenviar`, { token: estado.universidade.token }), 200);
    const cadastro = status(await chamar('GET', `/universidades/${id}/cadastro`, { token: estado.universidade.token }), 200).data;
    conferir(cadastro.status === 'P' && !cadastro.motivoReprovacao, 'o reenvio não voltou para pendente');
  });

  ponto('Aprovar publica a universidade, notifica e gera o e-mail (RF23)', async () => {
    const id = estado.universidade.id;
    status(await chamar('POST', `/universidades/${id}/aprovar`, { token: estado.admin.token }), 200);
    const publica = status(await chamar('GET', `/universidades/${id}`), 200).data;
    conferir(publica.nomeFantasia === nomeUniversidade, 'a aprovada não aparece no site');
    const notificacoes = status(await chamar('GET', '/notificacoes', { token: estado.universidade.token }), 200).data;
    conferir(notificacoes.some((n) => n.tipo === 'UNIVERSIDADE_APROVADA'), 'sem notificação UNIVERSIDADE_APROVADA');
  });

  ponto('Painel da universidade: novo campus e regra do campus principal (RF21, RF22)', async () => {
    const id = estado.universidade.id;
    const novo = await chamar('POST', `/universidades/${id}/campus`, {
      token: estado.universidade.token,
      corpo: {
        nome: 'Campus Zona Norte',
        cnpj: '12.ABC.345/01DE-35',
        telefoneFixo: '(15) 3333-4444',
        endereco: { logradouro: 'Avenida Itavuvu', numero: '2000', bairro: 'Jardim Santa Cecília', cidade: 'Sorocaba', estado: 'sp', cep: '18078-005' },
      },
    });
    estado.campusNovo = status(novo, 201).data;
    conferir(estado.campusNovo.principal === false, 'o segundo campus virou principal');
    const lista = status(await chamar('GET', `/universidades/${id}/gestao/campus`, { token: estado.universidade.token }), 200).data;
    conferir(lista.length === 2 && lista.filter((c) => c.principal).length === 1, 'não há exatamente um campus principal');
    estado.campusPrincipal = lista.find((c) => c.principal);
    status(await chamar('DELETE', `/campus/${estado.campusPrincipal.id}`, { token: estado.universidade.token }), 409);
  });

  ponto('Curso e oferta no campus com turno e vagas (RF19, RF20)', async () => {
    const id = estado.universidade.id;
    const curso = await chamar('POST', `/universidades/${id}/cursos`, {
      token: estado.universidade.token,
      corpo: { nome: 'Análise e Desenvolvimento de Sistemas', areaCurso: 'Tecnologia', grau: 'Tecnólogo', modalidade: 'Presencial', duracaoSemestres: 6 },
    });
    estado.curso = status(curso, 201).data;
    const oferta = await chamar('POST', `/cursos/${estado.curso.id}/ofertas`, {
      token: estado.universidade.token,
      corpo: { campusId: estado.campusNovo.id, turno: 'Noturno', vagas: 40 },
    });
    status(oferta, 201);
    const repetida = await chamar('POST', `/cursos/${estado.curso.id}/ofertas`, {
      token: estado.universidade.token,
      corpo: { campusId: estado.campusNovo.id, turno: 'Matutino', vagas: 10 },
    });
    status(repetida, 409);
    const excluir = await chamar('DELETE', `/cursos/${estado.curso.id}`, { token: estado.universidade.token });
    conferir(status(excluir, 409).error.code === 'CURSO_OFERTADO', 'curso ofertado foi excluído');
    const publicos = status(await chamar('GET', `/universidades/${id}/cursos`), 200).data;
    conferir(publicos.some((c) => c.id === estado.curso.id), 'o curso não aparece na página pública');
  });

  ponto('Programas aceitos e bolsa institucional só na página da universidade (RF11, RF12, RF13, RF17)', async () => {
    const id = estado.universidade.id;
    const gestao = status(await chamar('GET', `/universidades/${id}/gestao/programas`, { token: estado.universidade.token }), 200).data;
    const escolhidos = gestao.filter((p) => ['FIES', 'ProUni', 'ENEM'].includes(p.sigla));
    status(
      await chamar('PUT', `/universidades/${id}/programas`, {
        token: estado.universidade.token,
        corpo: { programas: escolhidos.map((p) => ({ programaId: p.id, observacao: p.sigla === 'FIES' ? 'Até 100% da mensalidade' : null })) },
      }),
      200,
    );
    const bolsa = await chamar('POST', `/universidades/${id}/bolsas`, {
      token: estado.universidade.token,
      corpo: { nome: `Bolsa Mérito ${sufixo}`, descricao: 'Desconto para os primeiros colocados no vestibular.' },
    });
    estado.bolsa = status(bolsa, 201).data;
    const globais = status(await chamar('GET', '/programas?tipo=BOLSA'), 200).data;
    conferir(!globais.some((p) => p.id === estado.bolsa.id), 'a bolsa institucional apareceu na pesquisa geral');
    const detalhe = status(await chamar('GET', `/universidades/${id}`), 200).data;
    conferir(JSON.stringify(detalhe).includes(`Bolsa Mérito ${sufixo}`), 'a bolsa não aparece na página da universidade');
    conferir(JSON.stringify(detalhe).includes('Até 100% da mensalidade'), 'a observação do programa aceito não aparece');
  });

  ponto('Descrição formatada e página do curso com cada oferta (RF19, RF20, T06)', async () => {
    const descricao = '## O que você estuda\n\nProgramação **web**.\n\n- Banco de dados\n- [Edital](https://www.example.com)';
    const salvo = await chamar('PATCH', `/cursos/${estado.curso.id}`, { token: estado.universidade.token, corpo: { descricao } });
    conferir(status(salvo, 200).data.descricao === descricao, 'a descrição formatada não foi gravada como veio');
    const longa = await chamar('PATCH', `/cursos/${estado.curso.id}`, {
      token: estado.universidade.token,
      corpo: { descricao: 'a'.repeat(10001) },
    });
    conferir(status(longa, 400).error.code === 'VALIDATION_ERROR', 'descrição acima de 10.000 caracteres foi aceita');

    const porNome = status(await chamar('GET', `/cursos/nome/${encodeURIComponent(estado.curso.nome)}`), 200).data;
    const oferta = porNome.universidades.find((o) => o.cursoId === estado.curso.id);
    conferir(oferta, 'a oferta da universidade não aparece na página do curso');
    conferir(oferta.descricao === descricao && oferta.grau === 'Tecnólogo' && oferta.duracaoSemestres === 6, 'a oferta veio sem os dados do curso');
    conferir(oferta.universidade.natureza && oferta.universidade.cidade === 'Votorantim', 'a oferta veio sem natureza ou cidade');
    conferir(
      oferta.campus.some((c) => c.id === estado.campusNovo.id && c.turno === 'Noturno' && c.vagas === 40),
      'a oferta veio sem o campus com turno e vagas',
    );
    conferir(oferta.programas.FINANCIAMENTO.some((p) => p.sigla === 'FIES' && p.observacao === 'Até 100% da mensalidade'), 'a oferta veio sem os programas aceitos');
    conferir(oferta.programas.BOLSA.some((p) => p.institucional), 'a oferta veio sem a bolsa institucional');
  });

  ponto('Sugestão para a universidade: notifica, ela avalia e o aluno é notificado (RF08, RF14, RF15)', async () => {
    const criada = await chamar('POST', '/sugestoes', {
      token: estado.aluno.token,
      corpo: { titulo: 'Curso noturno', texto: 'Vocês poderiam abrir turma de Enfermagem à noite?', universidadeId: estado.universidade.id },
    });
    const sugestao = status(criada, 201).data;
    const recebidas = status(await chamar('GET', '/sugestoes', { token: estado.universidade.token }), 200).data;
    conferir(recebidas.some((s) => s.id === sugestao.id), 'a universidade não recebeu a sugestão');
    const notificacoes = status(await chamar('GET', '/notificacoes', { token: estado.universidade.token }), 200).data;
    estado.notificacaoSugestao = notificacoes.find((n) => n.tipo === 'NOVA_SUGESTAO' && n.referenciaId === sugestao.id);
    conferir(estado.notificacaoSugestao, 'sem notificação NOVA_SUGESTAO para a universidade');
    const avaliada = await chamar('PATCH', `/sugestoes/${sugestao.id}/status`, {
      token: estado.universidade.token,
      corpo: { status: 'APROVADA', resposta: 'Vamos estudar a turma para o próximo semestre.' },
    });
    status(avaliada, 200);
    const denovo = await chamar('PATCH', `/sugestoes/${sugestao.id}/status`, {
      token: estado.universidade.token,
      corpo: { status: 'REPROVADA', resposta: 'Mudança de ideia.' },
    });
    status(denovo, 409);
    const doAluno = status(await chamar('GET', '/notificacoes', { token: estado.aluno.token }), 200).data;
    conferir(doAluno.some((n) => n.tipo === 'SUGESTAO_AVALIADA' && n.referenciaId === sugestao.id), 'o aluno não foi notificado');
    const minhas = status(await chamar('GET', '/sugestoes/minhas', { token: estado.aluno.token }), 200).data;
    conferir(minhas.find((s) => s.id === sugestao.id)?.resposta, 'o histórico do aluno não mostra a resposta');
  });

  ponto('Notificações: contador, marcar uma e todas como lidas (RF14)', async () => {
    const antes = status(await chamar('GET', '/notificacoes/nao-lidas', { token: estado.universidade.token }), 200).data;
    conferir(antes.naoLidas > 0, `sem notificações não lidas: ${resumo(antes)}`);
    status(await chamar('PATCH', `/notificacoes/${estado.notificacaoSugestao.id}/lida`, { token: estado.universidade.token }), 200);
    status(await chamar('PATCH', '/notificacoes/lidas', { token: estado.universidade.token }), 200);
    const lista = status(await chamar('GET', '/notificacoes', { token: estado.universidade.token }), 200);
    conferir(lista.meta.naoLidas === 0, `ainda há ${lista.meta.naoLidas} não lidas`);
    const alheia = await chamar('PATCH', `/notificacoes/${estado.notificacaoSugestao.id}/lida`, { token: estado.aluno.token });
    status(alheia, 403);
  });

  ponto('Estatística da página da universidade (visitas e avaliações)', async () => {
    const dados = status(await chamar('GET', `/universidades/${estado.universidade.id}/estatisticas`, { token: estado.universidade.token }), 200).data;
    conferir(JSON.stringify(dados).includes('visitas'), `sem visitas na resposta: ${resumo(dados)}`);
  });

  // ------------------------------------------------------------ Administrador
  ponto('Administrador avalia a sugestão enviada à administração (RF15)', async () => {
    const recebidas = status(await chamar('GET', '/sugestoes?status=EM_ANALISE', { token: estado.admin.token }), 200).data;
    conferir(recebidas.some((s) => s.id === estado.sugestaoAdmin.id), 'o administrador não recebeu a sugestão');
    status(
      await chamar('PATCH', `/sugestoes/${estado.sugestaoAdmin.id}/status`, {
        token: estado.admin.token,
        corpo: { status: 'REPROVADA', resposta: 'As bolsas municipais ficam fora do escopo por enquanto.' },
      }),
      200,
    );
  });

  ponto('Programa global com data importante, que aparece na página do programa (RF10)', async () => {
    const criado = await chamar('POST', '/programas', {
      token: estado.admin.token,
      corpo: { nome: `Programa Escola da Família ${sufixo}`, sigla: `EF${sufixo.slice(-4)}`, tipo: 'BOLSA', descricao: 'Bolsa do governo do estado para universitários.' },
    });
    estado.programa = status(criado, 201).data;
    const evento = await chamar('POST', `/programas/${estado.programa.id}/eventos`, {
      token: estado.admin.token,
      corpo: { titulo: 'Inscrições', dataInicio: '2027-02-01', dataFim: '2027-02-28' },
    });
    status(evento, 201);
    const invalido = await chamar('POST', `/programas/${estado.programa.id}/eventos`, {
      token: estado.admin.token,
      corpo: { titulo: 'Datas trocadas', dataInicio: '2027-03-10', dataFim: '2027-03-01' },
    });
    status(invalido, 400);
    const publico = status(await chamar('GET', `/programas/${estado.programa.id}`), 200).data;
    conferir(publico.eventos.some((e) => e.titulo === 'Inscrições'), 'a data importante não aparece');
  });

  ponto('Excluir programa aceito por universidade é bloqueado (RF10)', async () => {
    const fies = await chamar('DELETE', `/programas/${estado.fies.id}`, { token: estado.admin.token });
    conferir(status(fies, 409).error.code === 'PROGRAMA_ACEITO', 'programa aceito foi excluído');
    status(await chamar('DELETE', `/programas/${estado.programa.id}`, { token: estado.admin.token }), 200);
  });

  ponto('Gerenciar usuários: filtros, novo usuário e regra do último administrador (RF09, Quadro 14)', async () => {
    const alunos = status(await chamar('GET', '/usuarios?tipoUsuario=A&ativo=true', { token: estado.admin.token }), 200).data;
    conferir(alunos.length > 0 && alunos.every((u) => u.tipoUsuario === 'A' && u.ativo), 'filtro de perfil e situação errado');
    const ultimo = await chamar('PATCH', `/usuarios/${estado.admin.id}`, { token: estado.admin.token, corpo: { ativo: false } });
    conferir(status(ultimo, 409).error.code === 'ULTIMO_ADMINISTRADOR', 'o último administrador foi inativado');
    const novo = await chamar('POST', '/usuarios', { token: estado.admin.token, corpo: { ...aluno2, tipoUsuario: 'A' } });
    estado.aluno2 = { id: status(novo, 201).data.id };
    const inativado = await chamar('PATCH', `/usuarios/${estado.aluno2.id}`, { token: estado.admin.token, corpo: { ativo: false } });
    status(inativado, 200);
    const login = await chamar('POST', '/auth/login', { corpo: { email: aluno2.email, senha: aluno2.senha } });
    status(login, 401);
    status(await chamar('PATCH', `/usuarios/${estado.aluno2.id}`, { token: estado.admin.token, corpo: { ativo: true } }), 200);
  });

  ponto('Dashboard: resumo, visitas e logins por período e mais acessados (RF16)', async () => {
    const resumoDados = status(await chamar('GET', '/estatisticas/resumo', { token: estado.admin.token }), 200).data;
    conferir(resumoDados.usuariosPorPerfil.total > 0, 'resumo sem usuários');
    conferir(resumoDados.universidadesPorStatus.A >= 4, 'resumo sem as universidades aprovadas');
    const visitas = status(await chamar('GET', '/estatisticas/visitas?agrupar=dia', { token: estado.admin.token }), 200).data;
    conferir(visitas.totalVisitas > 0, `nenhuma visita registrada: ${resumo(visitas)}`);
    conferir(visitas.loginsUnicos >= 3, `esperava ao menos 3 logins únicos, veio ${visitas.loginsUnicos}`);
    conferir(visitas.serie.length >= 30, 'a série dos 30 dias veio incompleta');
    const ranking = status(await chamar('GET', '/estatisticas/ranking', { token: estado.admin.token }), 200).data;
    conferir(ranking.universidades.length > 0, 'ranking de universidades vazio');
    status(await chamar('GET', '/estatisticas/resumo', { token: estado.aluno.token }), 403);
  });

  ponto('Inativar universidade tira do site e reativar devolve (RF18)', async () => {
    const id = estado.universidade.id;
    status(await chamar('POST', `/universidades/${id}/inativar`, { token: estado.admin.token }), 200);
    status(await chamar('GET', `/universidades/${id}`), 404);
    const pesquisa = status(await chamar('GET', `/universidades?q=${encodeURIComponent(nomeUniversidade)}`), 200).data;
    conferir(pesquisa.length === 0, 'a inativa aparece na pesquisa');
    const escrita = await chamar('PATCH', `/universidades/${id}`, { token: estado.universidade.token, corpo: { descricao: 'Teste' } });
    status(escrita, 403);
    status(await chamar('POST', `/universidades/${id}/reativar`, { token: estado.admin.token }), 200);
    status(await chamar('GET', `/universidades/${id}`), 200);
  });

  // ---------------------------------------------------------- Conta e senha
  ponto('Recuperar senha: link por e-mail, nova senha e link de uso único (RF07)', async () => {
    status(await chamar('POST', '/auth/forgot-password', { corpo: { email: aluno.email } }), 200);
    status(await chamar('POST', '/auth/forgot-password', { corpo: { email: `ninguem.${sufixo}@exemplo.com` } }), 200);
    const textoLog = log.join('');
    const achado = [...textoLog.matchAll(/redefinir-senha\?token=([0-9a-f]{64})/g)].pop();
    conferir(achado, 'o link de recuperação não saiu no log do e-mail');
    const token = achado[1];
    const registro = await prisma.tokenRecuperacao.findUnique({ where: { tokenHash: crypto.createHash('sha256').update(token).digest('hex') } });
    conferir(registro && registro.expiraEm > new Date(), 'token sem validade no banco');
    aluno.senha = 'senha-recuperada-1';
    status(await chamar('POST', '/auth/reset-password', { corpo: { token, novaSenha: aluno.senha } }), 200);
    status(await chamar('POST', '/auth/reset-password', { corpo: { token, novaSenha: 'outra-senha-1' } }), 400);
    const login = status(await chamar('POST', '/auth/login', { corpo: { email: aluno.email, senha: aluno.senha } }), 200).data;
    estado.aluno.token = login.accessToken;
    estado.aluno.refresh = login.refreshToken;
  });

  ponto('Alterar senha confere a atual e derruba as sessões (RF09, Quadro 13)', async () => {
    const errada = await chamar('PATCH', `/usuarios/${estado.aluno.id}/senha`, {
      token: estado.aluno.token,
      corpo: { senhaAtual: 'nao-e-esta', novaSenha: 'senha-nova-123', confirmacao: 'senha-nova-123' },
    });
    conferir(errada.status === 400 || errada.status === 401, `senha atual errada respondeu ${errada.status}`);
    status(
      await chamar('PATCH', `/usuarios/${estado.aluno.id}/senha`, {
        token: estado.aluno.token,
        corpo: { senhaAtual: aluno.senha, novaSenha: 'senha-nova-123', confirmacao: 'senha-nova-123' },
      }),
      200,
    );
    status(await chamar('POST', '/auth/refresh', { corpo: { refreshToken: estado.aluno.refresh } }), 401);
    aluno.senha = 'senha-nova-123';
    const login = status(await chamar('POST', '/auth/login', { corpo: { email: aluno.email, senha: aluno.senha } }), 200).data;
    estado.aluno.token = login.accessToken;
    estado.aluno.refresh = login.refreshToken;
  });

  ponto('Logoff encerra a sessão (RF06)', async () => {
    status(await chamar('POST', '/auth/logout', { token: estado.aluno.token, corpo: { refreshToken: estado.aluno.refresh } }), 200);
    status(await chamar('POST', '/auth/refresh', { corpo: { refreshToken: estado.aluno.refresh } }), 401);
  });

  ponto('Excluir conta: aluno é apagado, universidade fica inativa (RF09, Quadro 13)', async () => {
    const login = status(await chamar('POST', '/auth/login', { corpo: { email: aluno2.email, senha: aluno2.senha } }), 200).data;
    status(await chamar('DELETE', `/usuarios/${estado.aluno2.id}`, { token: login.accessToken, corpo: { confirmacao: 'EXCLUIR' } }), 200);
    conferir((await prisma.usuario.findUnique({ where: { id: estado.aluno2.id } })) === null, 'o aluno não foi apagado');
    const uni = status(await chamar('POST', '/auth/login', { corpo: { email: contaUniversidade.email, senha: contaUniversidade.senha } }), 200).data;
    status(await chamar('DELETE', `/usuarios/${uni.usuario.id}`, { token: uni.accessToken, corpo: { confirmacao: 'EXCLUIR' } }), 200);
    const universidade = await prisma.universidade.findUnique({ where: { id: estado.universidade.id } });
    conferir(universidade && universidade.status === 'I', 'a universidade não ficou inativa');
    status(await chamar('GET', `/universidades/${estado.universidade.id}`), 404);
  });

  // ------------------------------------------------------------------ Banco
  ponto('Auditoria grava as operações de escrita com usuário, entidade e data (RNF09)', async () => {
    const acoes = await prisma.logAuditoria.groupBy({ by: ['acao'], _count: { _all: true } });
    const porAcao = Object.fromEntries(acoes.map((a) => [a.acao, a._count._all]));
    for (const acao of ['CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT']) {
      conferir(porAcao[acao] > 0, `nenhum registro de ${acao} em log_auditoria`);
    }
    const aprovacao = await prisma.logAuditoria.findFirst({
      where: { entidade: 'universidade', entidadeId: estado.universidade.id, usuarioId: estado.admin.id },
    });
    conferir(aprovacao, 'a decisão do administrador não está na auditoria');
  });

  ponto('Visitas às páginas públicas ficam registradas para o dashboard (RF16)', async () => {
    const entidades = await prisma.visitaPagina.groupBy({ by: ['entidade'], _count: { _all: true } });
    const nomes = entidades.map((e) => e.entidade);
    for (const entidade of ['home', 'universidade', 'programa', 'campus']) {
      conferir(nomes.includes(entidade), `nenhuma visita de ${entidade}`);
    }
  });

  return pontos;
}

module.exports = { criarRoteiro };
