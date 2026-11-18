const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const requireRole = require('../../middlewares/role.middleware');
const exigirUniversidadeAtiva = require('../../middlewares/universidade-ativa.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./sugestoes.controller');
const schemas = require('./sugestoes.schema');

const router = Router();

// RF08 (envio), RF14 (notificação) e RF15 (avaliação). Seção 5.8 da especificação.
router.use(auth);

router.post('/', requireRole('A'), validate(schemas.criarSugestaoSchema), controller.criar);
router.get('/minhas', requireRole('A'), validate(schemas.minhasQuerySchema), controller.minhas);
// Recebidas: D as da administração, U as da própria universidade.
router.get('/', requireRole('D', 'U'), validate(schemas.recebidasQuerySchema), controller.recebidas);
// Autor ou destinatário; a checagem fica no service, que conhece os dois lados.
router.get('/:id', validate(schemas.idParamSchema), controller.detalhe);
// Universidade reprovada ou inativa não avalia (Pendência 6).
router.patch(
  '/:id/status',
  requireRole('D', 'U'),
  exigirUniversidadeAtiva,
  validate(schemas.avaliarSugestaoSchema),
  controller.avaliar,
);

module.exports = router;
