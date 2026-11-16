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

/**
 * Garante que o usuário logado só altere recursos que ele mesmo criou
 * (avaliação, pesquisa salva). `resolverUsuarioId` recebe o `req` e retorna
 * (ou resolve) o id_usuario dono do recurso; deve lançar AppError.notFound
 * quando o recurso não existe. Com `permitirAdmin`, o Administrador (D)
 * passa sem checar o dono.
 */
function porUsuario(resolverUsuarioId, { permitirAdmin = false } = {}) {
  return async function ownershipPorUsuarioMiddleware(req, res, next) {
    try {
      if (!req.user) {
        return next(AppError.unauthenticated());
      }

      const usuarioIdDoRecurso = await resolverUsuarioId(req);

      if (permitirAdmin && req.user.tipoUsuario === 'D') {
        return next();
      }

      if (usuarioIdDoRecurso == null || Number(usuarioIdDoRecurso) !== Number(req.user.id)) {
        return next(AppError.forbidden());
      }

      return next();
    } catch (erro) {
      return next(erro);
    }
  };
}

module.exports = ownership;
module.exports.porUsuario = porUsuario;
