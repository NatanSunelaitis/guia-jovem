const { Router } = require('express');

const validate = require('../../middlewares/validate.middleware');
const controller = require('./programas.controller');
const schemas = require('./programas.schema');

const router = Router();

router.get('/', validate(schemas.listQuerySchema), controller.listar);
router.get('/destaques', validate(schemas.destaquesQuerySchema), controller.destaques);
router.get('/:id', validate(schemas.idParamSchema), controller.obter);
router.get('/:id/universidades', validate(schemas.idParamSchema), controller.universidades);

module.exports = router;
