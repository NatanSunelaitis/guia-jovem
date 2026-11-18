const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const requireRole = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./cursos.controller');
const schemas = require('./cursos.schema');

const router = Router();

// RF19 (T24.4): cadastro de cursos pelo administrador. Antes de /:id.
router.get('/administracao', auth, requireRole('D'), validate(schemas.adminListQuerySchema), controller.listarAdmin);
router.get(
  '/administracao/:id',
  auth,
  requireRole('D'),
  validate(schemas.idParamSchema),
  controller.obterAdmin,
);

router.get('/', validate(schemas.listQuerySchema), controller.listar);
router.get('/destaques', validate(schemas.destaquesQuerySchema), controller.destaques);
router.get('/nome/:nome', validate(schemas.nomeParamSchema), controller.obterPorNome);
router.get('/:id', validate(schemas.idParamSchema), controller.obter);

router.patch('/:id', auth, requireRole('D'), validate(schemas.atualizarCursoSchema), controller.atualizar);
router.delete('/:id', auth, requireRole('D'), validate(schemas.idParamSchema), controller.excluir);

module.exports = router;
