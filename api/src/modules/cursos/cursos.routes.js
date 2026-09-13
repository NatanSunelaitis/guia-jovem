const { Router } = require('express');

const validate = require('../../middlewares/validate.middleware');
const controller = require('./cursos.controller');
const schemas = require('./cursos.schema');

const router = Router();

router.get('/', validate(schemas.listQuerySchema), controller.listar);
router.get('/destaques', validate(schemas.destaquesQuerySchema), controller.destaques);
router.get('/nome/:nome', validate(schemas.nomeParamSchema), controller.obterPorNome);
router.get('/:id', validate(schemas.idParamSchema), controller.obter);

module.exports = router;
