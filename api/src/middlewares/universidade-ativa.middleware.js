const prisma = require('../config/database');
const AppError = require('../shared/errors/AppError');

/**
 * Regras de acesso da conta de universidade pela situação do cadastro
 * (Pendência 3):
 * - P pendente: edita os próprios dados enquanto aguarda a análise;
 * - A aprovada: edita tudo, sem nova aprovação;
 * - R reprovada: só corrige os dados da instituição e dos campi e reenvia;
 * - I inativa: somente leitura.
 */
const MENSAGENS = {
  P: 'Esta ação fica disponível depois que o cadastro da universidade for aprovado.',
  A: 'Esta ação não está disponível para uma universidade aprovada.',
  R: 'O cadastro desta universidade foi reprovado. Corrija os dados da instituição e dos campi e reenvie o cadastro para análise; cursos, ofertas, programas e bolsas ficam bloqueados até a aprovação.',
  I: 'Esta universidade está inativa e fora do site. Os dados ficam disponíveis só para leitura.',
};

/**
 * Deixa passar a conta de universidade só quando o status atual (lido do
 * banco, porque a sessão guarda o do momento do login) está entre os
 * `statusPermitidos`; senão responde 403 `UNIVERSIDADE_NAO_APROVADA`.
 * Outros perfis passam. Usar depois de `auth` e do `ownership`.
 */
function permitirStatusUniversidade(...statusPermitidos) {
  return async function permitirStatusUniversidadeMiddleware(req, res, next) {
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
      if (!statusPermitidos.includes(universidade.status)) {
        return next(new AppError('UNIVERSIDADE_NAO_APROVADA', MENSAGENS[universidade.status], 403));
      }
      return next();
    } catch (erro) {
      return next(erro);
    }
  };
}

/** Pendente ou aprovada: cursos, ofertas, programas aceitos, bolsas e sugestões. */
const exigirUniversidadeAtiva = permitirStatusUniversidade('P', 'A');

/** Também a reprovada, que corrige os dados da instituição e dos campi. */
const permitirCorrecaoDoCadastro = permitirStatusUniversidade('P', 'A', 'R');

module.exports = exigirUniversidadeAtiva;
module.exports.permitirStatusUniversidade = permitirStatusUniversidade;
module.exports.permitirCorrecaoDoCadastro = permitirCorrecaoDoCadastro;
