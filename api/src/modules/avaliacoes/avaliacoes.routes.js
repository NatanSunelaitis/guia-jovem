const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const { porUsuario } = require('../../middlewares/ownership.middleware');
const requireRole = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./avaliacoes.controller');
const schemas = require('./avaliacoes.schema');

const router = Router();

router.use(auth);

// RF02. O POST fica em /universidades/:id/avaliacoes (universidades.routes.js).
router.get('/minhas', requireRole('A'), validate(schemas.minhasQuerySchema), controller.minhas);
router.put(
  '/:id',
  requireRole('A'),
  validate(schemas.atualizarAvaliacaoSchema),
  porUsuario(controller.resolverDono),
  controller.atualizar,
);
router.delete(
  '/:id',
  requireRole('A', 'D'),
  validate(schemas.idParamSchema),
  porUsuario(controller.resolverDono, { permitirAdmin: true }),
  controller.excluir,
);

module.exports = router;
