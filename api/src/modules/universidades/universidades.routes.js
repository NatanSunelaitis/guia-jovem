const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const requireRole = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const avaliacoesController = require('../avaliacoes/avaliacoes.controller');
const avaliacoesSchemas = require('../avaliacoes/avaliacoes.schema');
const controller = require('./universidades.controller');
const schemas = require('./universidades.schema');

const router = Router();

// RF06: pesquisa dinâmica de universidades (pública, só status=A).
router.get('/', auth.opcional, validate(schemas.listQuerySchema), controller.listar);
router.get('/destaques', validate(schemas.destaquesQuerySchema), controller.destaques);
// Com sessão de aluno, o detalhe diz se ele já avaliou (minhaAvaliacao) e se salvou (salva).
router.get('/:id', auth.opcional, validate(schemas.idParamSchema), controller.obter);
router.get('/:id/campus', validate(schemas.idParamSchema), controller.campus);
router.get('/:id/cursos', validate(schemas.idParamSchema), controller.cursos);
router.get('/:id/avaliacoes', validate(schemas.paginacaoQuerySchema), controller.avaliacoes);
// RF02: uma avaliação por aluno por universidade; edição e exclusão em /avaliacoes/:id.
router.post(
  '/:id/avaliacoes',
  auth,
  requireRole('A'),
  validate(avaliacoesSchemas.criarAvaliacaoSchema),
  avaliacoesController.criar,
);

module.exports = router;
