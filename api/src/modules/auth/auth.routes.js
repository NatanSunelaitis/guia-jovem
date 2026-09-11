const { Router } = require('express');
const rateLimit = require('express-rate-limit');

const auth = require('../../middlewares/auth.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./auth.controller');
const schemas = require('./auth.schema');

// 5.11: login e forgot-password limitados a 10 requisições / 15 min por IP.
const limitadorSensivel = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    res.status(429).json({
      error: { code: 'RATE_LIMITED', message: 'Muitas tentativas. Tente novamente mais tarde.', details: [] },
    });
  },
});

const router = Router();

router.post('/register/aluno', validate(schemas.registerAlunoSchema), controller.registerAluno);
router.post('/login', limitadorSensivel, validate(schemas.loginSchema), controller.login);
router.post('/google', validate(schemas.googleSchema), controller.google);
router.post('/refresh', validate(schemas.refreshSchema), controller.refresh);
router.post('/logout', auth, validate(schemas.logoutSchema), controller.logout);
router.post(
  '/forgot-password',
  limitadorSensivel,
  validate(schemas.forgotPasswordSchema),
  controller.forgotPassword,
);
router.post('/reset-password', validate(schemas.resetPasswordSchema), controller.resetPassword);
router.get('/me', auth, controller.me);

module.exports = router;
