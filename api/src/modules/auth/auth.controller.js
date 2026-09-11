const prisma = require('../../config/database');
const authService = require('./auth.service');

async function registerAluno(req, res, next) {
  try {
    const resultado = await authService.registrarAluno(prisma, req.body, req);
    res.status(201).json({ data: resultado, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function login(req, res, next) {
  try {
    const resultado = await authService.login(prisma, req.body, req);
    res.json({ data: resultado, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function google(req, res, next) {
  try {
    const resultado = await authService.loginComGoogle(prisma, req.body, req);
    res.json({ data: resultado, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function refresh(req, res, next) {
  try {
    const resultado = await authService.refresh(prisma, req.body);
    res.json({ data: resultado, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function logout(req, res, next) {
  try {
    await authService.logout(prisma, req.body, req);
    res.json({ data: { sucesso: true }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function forgotPassword(req, res, next) {
  try {
    await authService.forgotPassword(prisma, req.body, req);
    res.json({
      data: { mensagem: 'Se este e-mail estiver cadastrado, você receberá um link de recuperação.' },
      meta: {},
    });
  } catch (erro) {
    next(erro);
  }
}

async function resetPassword(req, res, next) {
  try {
    await authService.resetPassword(prisma, req.body, req);
    res.json({ data: { sucesso: true }, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

async function me(req, res, next) {
  try {
    const usuario = await authService.me(prisma, req.user.id);
    res.json({ data: usuario, meta: {} });
  } catch (erro) {
    next(erro);
  }
}

module.exports = { registerAluno, login, google, refresh, logout, forgotPassword, resetPassword, me };
