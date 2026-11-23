const { Router } = require('express');

const env = require('../../config/env');
const auth = require('../../middlewares/auth.middleware');
const { limitadorDeLogin, limitadorDeRecuperacao } = require('../../middlewares/limiteTentativas.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./auth.controller');
const schemas = require('./auth.schema');

// 5.11: LIMITE_TENTATIVAS_LOGIN (10 em produção) a cada 15 minutos. No login
// contam só as falhas, por IP + e-mail (e um teto maior por IP); no
// forgot-password, cada pedido por IP. A conferência de ponta a ponta e a
// demonstração sobem a API com um valor maior.
const limiteLogin = limitadorDeLogin({ limite: env.LIMITE_TENTATIVAS_LOGIN });
const limiteRecuperacao = limitadorDeRecuperacao({ limite: env.LIMITE_TENTATIVAS_LOGIN });

const router = Router();

router.post('/register/aluno', validate(schemas.registerAlunoSchema), controller.registerAluno);
router.post(
  '/register/universidade',
  validate(schemas.registerUniversidadeSchema),
  controller.registerUniversidade,
);
router.post('/login', ...limiteLogin, validate(schemas.loginSchema), controller.login);
router.post('/google', validate(schemas.googleSchema), controller.google);
router.post('/refresh', validate(schemas.refreshSchema), controller.refresh);
router.post('/logout', auth, validate(schemas.logoutSchema), controller.logout);
router.post(
  '/forgot-password',
  limiteRecuperacao,
  validate(schemas.forgotPasswordSchema),
  controller.forgotPassword,
);
router.post('/reset-password', validate(schemas.resetPasswordSchema), controller.resetPassword);
router.get('/me', auth, controller.me);

module.exports = router;
