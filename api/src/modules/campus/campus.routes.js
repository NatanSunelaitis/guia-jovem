const { Router } = require('express');

const validate = require('../../middlewares/validate.middleware');
const controller = require('./campus.controller');
const schemas = require('./campus.schema');

const router = Router();

router.get('/:id', validate(schemas.idParamSchema), controller.obter);

module.exports = router;
