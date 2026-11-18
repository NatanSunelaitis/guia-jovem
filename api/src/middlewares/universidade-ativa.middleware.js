const prisma = require('../config/database');
const AppError = require('../shared/errors/AppError');

const MENSAGENS = {
  R: 'O cadastro desta universidade foi reprovado. O painel fica bloqueado até um novo cadastro ser aprovado.',
  I: 'Esta universidade está inativa e fora do site. Os dados ficam disponíveis só para leitura.',
};

/**
 * Pendência 6: conta de universidade reprovada (R) ou inativa (I) entra no
 * sistema, mas não executa rotas de escrita de domínio. Lê o status atual
 * do banco (a sessão guarda o do momento do login). Outros perfis passam.
 * Usar depois de `auth` em toda rota de escrita que a universidade alcança.
 */
async function exigirUniversidadeAtiva(req, res, next) {
  try {
    if (req.user?.tipoUsuario !== 'U') return next();

    const universidade = req.user.universidadeId
      ? await prisma.universidade.findUnique({
          where: { id: Number(req.user.universidadeId) },
          select: { status: true },
        })
      : null;

    if (!universidade) {
      return next(AppError.forbidden('Esta conta não está vinculada a uma universidade'));
    }
    if (MENSAGENS[universidade.status]) {
      return next(new AppError('UNIVERSIDADE_NAO_APROVADA', MENSAGENS[universidade.status], 403));
    }
    return next();
  } catch (erro) {
    return next(erro);
  }
}

module.exports = exigirUniversidadeAtiva;
