const prisma = require('../../config/database');
const adminService = require('./cursos.admin.service');
const ofertas = require('./ofertas.service');
const service = require('./cursos.service');

async function listar(req, res, next) {
  try {
    const resultado = await service.listar(prisma, req.query);
    res.json(resultado);
  } catch (erro) {
    next(erro);
  }
}

async function destaques(req, res, next) {
  try {
    const cursos = await service.listarDestaques(prisma, req.query);
    res.json({ data: cursos, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function obter(req, res, next) {
  try {
    const curso = await service.obterDetalhe(prisma, req.params.id, req);
    res.json({ data: curso, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function obterPorNome(req, res, next) {
  try {
    const resultado = await service.obterPorNome(prisma, req.params.nome, req);
    res.json({ data: resultado, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function listarAdmin(req, res, next) {
  try {
    res.json(await adminService.listarAdmin(prisma, req.query));
  } catch (erro) {
    next(erro);
  }
}

async function obterAdmin(req, res, next) {
  try {
    res.json({ data: await adminService.obterAdmin(prisma, req.params.id), meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function criar(req, res, next) {
  try {
    const curso = await adminService.criar(prisma, req.params.id, req.body, req);
    res.status(201).json({ data: curso, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function atualizar(req, res, next) {
  try {
    res.json({ data: await adminService.atualizar(prisma, req.params.id, req.body, req), meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function excluir(req, res, next) {
  try {
    await adminService.excluir(prisma, req.params.id, req);
    res.json({ data: { sucesso: true }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function listarGestao(req, res, next) {
  try {
    res.json({ data: await ofertas.listarCursosComOfertas(prisma, req.params.id), meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function criarOferta(req, res, next) {
  try {
    res.status(201).json({ data: await ofertas.criar(prisma, req.params.id, req.body, req), meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function atualizarOferta(req, res, next) {
  try {
    const oferta = await ofertas.atualizar(prisma, req.params.id, req.params.campusId, req.body, req);
    res.json({ data: oferta, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function excluirOferta(req, res, next) {
  try {
    await ofertas.excluir(prisma, req.params.id, req.params.campusId, req);
    res.json({ data: { sucesso: true }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

module.exports = {
  listar,
  destaques,
  obter,
  obterPorNome,
  listarAdmin,
  obterAdmin,
  criar,
  atualizar,
  excluir,
  listarGestao,
  criarOferta,
  atualizarOferta,
  excluirOferta,
};
