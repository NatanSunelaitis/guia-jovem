const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const ownership = require('../../middlewares/ownership.middleware');
const requireRole = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const avaliacoesController = require('../avaliacoes/avaliacoes.controller');
const avaliacoesSchemas = require('../avaliacoes/avaliacoes.schema');
const cursosController = require('../cursos/cursos.controller');
const cursosSchemas = require('../cursos/cursos.schema');
const controller = require('./universidades.controller');
const schemas = require('./universidades.schema');

const router = Router();

// RF23: lista do administrador, com qualquer status. Antes de /:id.
router.get(
  '/administracao',
  auth,
  requireRole('D'),
  validate(schemas.adminListQuerySchema),
  controller.listarAdmin,
);

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

// RF23: dados do cadastro para a análise (administrador) e para a própria
// universidade acompanhar a situação (pendente, reprovada com o motivo...).
router.get(
  '/:id/cadastro',
  auth,
  requireRole('D', 'U'),
  validate(schemas.idParamSchema),
  ownership((req) => req.params.id),
  controller.obterCadastro,
);

// RF18: administrador edita os dados institucionais (a própria universidade
// edita na rodada do painel dela).
router.patch('/:id', auth, requireRole('D'), validate(schemas.atualizarUniversidadeSchema), controller.atualizar);

// RF19: o administrador cadastra curso numa universidade (seção 5.5).
router.post('/:id/cursos', auth, requireRole('D'), validate(cursosSchemas.criarCursoSchema), cursosController.criar);

// RF23 e RF18: aprovar, reprovar (com motivo), inativar e reativar. Só administrador.
const soAdmin = [auth, requireRole('D')];
router.post('/:id/aprovar', ...soAdmin, validate(schemas.idParamSchema), controller.aprovar);
router.post('/:id/reprovar', ...soAdmin, validate(schemas.reprovarSchema), controller.reprovar);
router.post('/:id/inativar', ...soAdmin, validate(schemas.idParamSchema), controller.inativar);
router.post('/:id/reativar', ...soAdmin, validate(schemas.idParamSchema), controller.reativar);

module.exports = router;
