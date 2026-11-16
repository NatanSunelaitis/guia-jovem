const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const requireRole = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./favoritos.controller');
const schemas = require('./favoritos.schema');

const router = Router();

// Faculdades salvas (Figura 25): exclusivas do perfil Aluno (docs/DECISOES.md).
router.use(auth, requireRole('A'));

router.get('/universidades', validate(schemas.listQuerySchema), controller.listar);
router.post('/universidades', validate(schemas.salvarUniversidadeSchema), controller.salvar);
router.delete('/universidades/:id', validate(schemas.idParamSchema), controller.remover);

module.exports = router;
