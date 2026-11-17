const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./notificacoes.controller');
const schemas = require('./notificacoes.schema');

const router = Router();

// RF14: sino do cabeçalho. Cada usuário logado vê só as próprias notificações.
router.use(auth);

router.get('/', validate(schemas.listQuerySchema), controller.listar);
router.get('/nao-lidas', controller.contarNaoLidas);
router.patch('/lidas', controller.marcarTodasLidas);
router.patch('/:id/lida', validate(schemas.idParamSchema), controller.marcarLida);

module.exports = router;
