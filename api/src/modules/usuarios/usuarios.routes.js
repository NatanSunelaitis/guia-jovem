const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const requireRole = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./usuarios.controller');
const schemas = require('./usuarios.schema');

const router = Router();

router.use(auth);

router.get('/', requireRole('D'), validate(schemas.listQuerySchema), controller.listar);
router.post('/', requireRole('D'), validate(schemas.createUsuarioSchema), controller.criar);
router.get('/:id', validate(schemas.idParamSchema), controller.obter);
router.patch('/:id', validate(schemas.updateUsuarioSchema), controller.atualizar);
router.patch('/:id/senha', validate(schemas.changePasswordSchema), controller.alterarSenha);
router.delete('/:id', validate(schemas.deleteUsuarioSchema), controller.excluir);

module.exports = router;
