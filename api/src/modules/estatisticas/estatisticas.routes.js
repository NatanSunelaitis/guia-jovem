const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const requireRole = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./estatisticas.controller');
const schemas = require('./estatisticas.schema');

const router = Router();

// RF16: dashboard de estatísticas, só administrador (seção 5.10).
router.use(auth, requireRole('D'));

router.get('/resumo', controller.resumo);
router.get('/visitas', validate(schemas.visitasQuerySchema), controller.visitas);
router.get('/ranking', validate(schemas.rankingQuerySchema), controller.ranking);

module.exports = router;
