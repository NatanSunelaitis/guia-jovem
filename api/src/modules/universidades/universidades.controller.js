const prisma = require('../../config/database');
const adminService = require('./universidades.admin.service');
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

module.exports = {
  listar,
  destaques,
  obter,
  campus,
  cursos,
  avaliacoes,
  listarAdmin,
  obterCadastro,
  aprovar: alterarStatus('aprovar'),
  reprovar: alterarStatus('reprovar'),
  inativar: alterarStatus('inativar'),
  reativar: alterarStatus('reativar'),
};
