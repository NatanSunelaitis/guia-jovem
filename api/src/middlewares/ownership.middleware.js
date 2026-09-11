const AppError = require('../shared/errors/AppError');

/**
 * Garante que o perfil Universidade só acesse recursos da própria instituição.
 * Administrador (D) sempre passa. `resolverUniversidadeId` recebe o `req` e
 * retorna (ou resolve) o id_universidade dono do recurso sendo acessado.
 */
function ownership(resolverUniversidadeId) {
  return async function ownershipMiddleware(req, res, next) {
    try {
      if (!req.user) {
        return next(AppError.unauthenticated());
      }

      if (req.user.tipoUsuario === 'D') {
        return next();
      }

      if (req.user.tipoUsuario !== 'U') {
        return next(AppError.forbidden());
      }

      const universidadeIdDoRecurso = await resolverUniversidadeId(req);

      if (
        universidadeIdDoRecurso == null ||
        Number(universidadeIdDoRecurso) !== Number(req.user.universidadeId)
      ) {
        return next(AppError.forbidden());
      }

      return next();
    } catch (erro) {
      return next(erro);
    }
  };
}

module.exports = ownership;
