const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const requireRole = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./programas.controller');
const schemas = require('./programas.schema');

const router = Router();

// RF10, RF11 e RF17 (T24.5 a T24.7): cadastro dos programas globais e das
// datas importantes, só administrador. Antes de /:id.
const soAdmin = [auth, requireRole('D')];
router.get('/administracao', ...soAdmin, validate(schemas.adminListQuerySchema), controller.listarAdmin);
router.get('/administracao/:id', ...soAdmin, validate(schemas.idParamSchema), controller.obterAdmin);
router.post('/', ...soAdmin, validate(schemas.criarProgramaSchema), controller.criar);
router.patch('/eventos/:id', ...soAdmin, validate(schemas.atualizarEventoSchema), controller.atualizarEvento);
router.delete('/eventos/:id', ...soAdmin, validate(schemas.idParamSchema), controller.excluirEvento);
router.patch('/:id', ...soAdmin, validate(schemas.atualizarProgramaSchema), controller.atualizar);
router.delete('/:id', ...soAdmin, validate(schemas.idParamSchema), controller.excluir);
router.post('/:id/eventos', ...soAdmin, validate(schemas.criarEventoSchema), controller.criarEvento);

router.get('/', validate(schemas.listQuerySchema), controller.listar);
router.get('/destaques', validate(schemas.destaquesQuerySchema), controller.destaques);
router.get('/:id', validate(schemas.idParamSchema), controller.obter);
router.get('/:id/universidades', validate(schemas.idParamSchema), controller.universidades);

module.exports = router;
