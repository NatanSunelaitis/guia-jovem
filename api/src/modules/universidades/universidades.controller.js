const prisma = require('../../config/database');
const notificacoesService = require('../notificacoes/notificacoes.service');
const bolsas = require('../programas/bolsas.service');
const adminService = require('./universidades.admin.service');
const gestao = require('./universidades.gestao.service');
const service = require('./universidades.service');

async function listar(req, res, next) {
  try {
    const resultado = await service.listar(prisma, req.query, req.user);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

async function destaques(req, res, next) {
  try {
    const universidades = await service.listarDestaques(prisma, req.query.limite);
    // RF16: os destaques de universidades só são pedidos pela home (T01),
    // então cada chamada conta como uma visita à home.
    req.registrarVisita({ entidade: 'home', rota: '/' });
    res.json({ data: universidades, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function obter(req, res, next) {
  try {
    const universidade = await service.obterDetalhe(prisma, req.params.id, req);
    res.json({ data: universidade, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function campus(req, res, next) {
  try {
    const dados = await service.listarCampus(prisma, req.params.id);
    res.json({ data: dados, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function cursos(req, res, next) {
  try {
    const dados = await service.listarCursos(prisma, req.params.id);
    res.json({ data: dados, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function avaliacoes(req, res, next) {
  try {
    const resultado = await service.listarAvaliacoes(prisma, req.params.id, req.query);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

async function listarAdmin(req, res, next) {
  try {
    const resultado = await adminService.listarAdmin(prisma, req.query);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

async function obterCadastro(req, res, next) {
  try {
    const universidade = await adminService.obterCadastro(prisma, req.params.id);
    // Abrir o cadastro (o administrador na análise, a universidade no painel)
    // marca como lidos os avisos dele: pendente, aprovada, reprovada.
    await notificacoesService.marcarLidasDaReferencia(prisma, req, 'universidade', [universidade.id]);
    res.json({ data: universidade, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function atualizar(req, res, next) {
  try {
    const universidade = await adminService.atualizar(prisma, req.params.id, req.body, req);
    res.json({ data: universidade, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

function alterarStatus(acao) {
  return async function alterarStatusHandler(req, res, next) {
    try {
      const universidade = await adminService.alterarStatus(prisma, req.params.id, acao, req.body, req);
      res.json({ data: universidade, meta: {} });
    } catch (erro) {
      next(erro);
    }
  };
}

function responder(executar, status = 200) {
  return async function handler(req, res, next) {
    try {
      res.status(status).json({ data: await executar(req), meta: {} });
    } catch (erro) {
      next(erro);
    }
  };
}

async function avaliacoesRecebidas(req, res, next) {
  try {
    res.json(await service.listarAvaliacoes(prisma, req.params.id, req.query, { qualquerStatus: true }));
  } catch (erro) {
    next(erro);
  }
}

module.exports = {
  avaliacoesRecebidas,
  programasGestao: responder((req) => gestao.listarProgramas(prisma, req.params.id)),
  definirProgramas: responder((req) => gestao.definirProgramas(prisma, req.params.id, req.body, req)),
  reenviar: responder((req) => gestao.reenviar(prisma, req.params.id, req)),
  estatisticas: responder((req) => gestao.estatisticas(prisma, req.params.id, req.query)),
  listarBolsas: responder((req) => bolsas.listar(prisma, req.params.id)),
  criarBolsa: responder((req) => bolsas.criar(prisma, req.params.id, req.body, req), 201),
  atualizarBolsa: responder((req) => bolsas.atualizar(prisma, req.params.id, req.params.bolsaId, req.body, req)),
  excluirBolsa: responder(async (req) => {
    await bolsas.excluir(prisma, req.params.id, req.params.bolsaId, req);
    return { sucesso: true };
  }),
  listar,
  destaques,
  obter,
  campus,
  cursos,
  avaliacoes,
  listarAdmin,
  obterCadastro,
  atualizar,
  aprovar: alterarStatus('aprovar'),
  reprovar: alterarStatus('reprovar'),
  inativar: alterarStatus('inativar'),
  reativar: alterarStatus('reativar'),
};
