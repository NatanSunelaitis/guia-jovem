const { Router } = require('express');

const validate = require('../../middlewares/validate.middleware');
const controller = require('./relatorios.controller');
const schemas = require('./relatorios.schema');

const router = Router();

// RF03: relatório de pesquisa exportável (mesmos filtros de /universidades).
router.get('/pesquisa', validate(schemas.relatorioQuerySchema), controller.pesquisa);

module.exports = router;
