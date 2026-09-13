const { Router } = require('express');

const validate = require('../../middlewares/validate.middleware');
const controller = require('./universidades.controller');
const schemas = require('./universidades.schema');

const router = Router();

// RF06: pesquisa dinâmica de universidades (pública, só status=A).
router.get('/', validate(schemas.listQuerySchema), controller.listar);
router.get('/destaques', validate(schemas.destaquesQuerySchema), controller.destaques);
router.get('/:id', validate(schemas.idParamSchema), controller.obter);
router.get('/:id/campus', validate(schemas.idParamSchema), controller.campus);
router.get('/:id/cursos', validate(schemas.idParamSchema), controller.cursos);
router.get('/:id/avaliacoes', validate(schemas.paginacaoQuerySchema), controller.avaliacoes);

module.exports = router;
