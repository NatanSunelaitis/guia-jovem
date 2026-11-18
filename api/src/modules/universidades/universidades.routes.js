const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const ownership = require('../../middlewares/ownership.middleware');
const requireRole = require('../../middlewares/role.middleware');
const exigirUniversidadeAtiva = require('../../middlewares/universidade-ativa.middleware');
const validate = require('../../middlewares/validate.middleware');
const avaliacoesController = require('../avaliacoes/avaliacoes.controller');
const avaliacoesSchemas = require('../avaliacoes/avaliacoes.schema');
const programasSchemas = require('../programas/programas.schema');
const campusController = require('../campus/campus.controller');
const campusSchemas = require('../campus/campus.schema');
const cursosController = require('../cursos/cursos.controller');
const cursosSchemas = require('../cursos/cursos.schema');
const controller = require('./universidades.controller');
const schemas = require('./universidades.schema');

const { permitirCorrecaoDoCadastro } = exigirUniversidadeAtiva;

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

// Painel da universidade (Pendência 3): a universidade dona ou o
// administrador. O ownership barra a conta de outra universidade (403) e o
// status atual decide o que a dona pode alterar: pendente e aprovada
// alteram tudo; reprovada só os dados da instituição e dos campi; inativa
// só lê.
const gestao = [auth, requireRole('D', 'U')];
const daPropria = ownership((req) => req.params.id);

// Leituras do painel, em qualquer situação do cadastro.
router.get('/:id/gestao/campus', ...gestao, validate(schemas.idParamSchema), daPropria, campusController.listarGestao);
router.get('/:id/gestao/cursos', ...gestao, validate(schemas.idParamSchema), daPropria, cursosController.listarGestao);
router.get('/:id/gestao/programas', ...gestao, validate(schemas.idParamSchema), daPropria, controller.programasGestao);
router.get('/:id/gestao/bolsas', ...gestao, validate(schemas.idParamSchema), daPropria, controller.listarBolsas);
router.get(
  '/:id/gestao/avaliacoes',
  ...gestao,
  validate(schemas.paginacaoQuerySchema),
  daPropria,
  controller.avaliacoesRecebidas,
);
router.get('/:id/estatisticas', ...gestao, validate(schemas.estatisticasQuerySchema), daPropria, controller.estatisticas);

// RF18: dados da instituição, incluindo os links da página oficial e de simulados.
router.patch(
  '/:id',
  ...gestao,
  validate(schemas.atualizarUniversidadeSchema),
  daPropria,
  permitirCorrecaoDoCadastro,
  controller.atualizar,
);

// RF21 e RF22: novo campus (alterar e excluir em /campus/:id).
router.post(
  '/:id/campus',
  ...gestao,
  validate(campusSchemas.criarCampusSchema),
  daPropria,
  permitirCorrecaoDoCadastro,
  campusController.criar,
);

// RF19: novo curso (seção 5.5); alterar, excluir e ofertas em /cursos/:id.
router.post(
  '/:id/cursos',
  ...gestao,
  validate(cursosSchemas.criarCursoSchema),
  daPropria,
  exigirUniversidadeAtiva,
  cursosController.criar,
);

// RF12, RF13 e RF17: programas globais aceitos (substitui o conjunto).
router.put(
  '/:id/programas',
  ...gestao,
  validate(schemas.definirProgramasSchema),
  daPropria,
  exigirUniversidadeAtiva,
  controller.definirProgramas,
);

// RF11: bolsas institucionais, visíveis só na página da universidade.
router.post(
  '/:id/bolsas',
  ...gestao,
  validate(programasSchemas.criarBolsaSchema),
  daPropria,
  exigirUniversidadeAtiva,
  controller.criarBolsa,
);
router.patch(
  '/:id/bolsas/:bolsaId',
  ...gestao,
  validate(programasSchemas.atualizarBolsaSchema),
  daPropria,
  exigirUniversidadeAtiva,
  controller.atualizarBolsa,
);
router.delete(
  '/:id/bolsas/:bolsaId',
  ...gestao,
  validate(programasSchemas.excluirBolsaSchema),
  daPropria,
  exigirUniversidadeAtiva,
  controller.excluirBolsa,
);

// Reenvio do cadastro reprovado: só a própria universidade (R vira P).
router.post(
  '/:id/reenviar',
  auth,
  requireRole('U'),
  validate(schemas.idParamSchema),
  daPropria,
  controller.reenviar,
);

// RF23 e RF18: aprovar, reprovar (com motivo), inativar e reativar. Só administrador.
const soAdmin = [auth, requireRole('D')];
router.post('/:id/aprovar', ...soAdmin, validate(schemas.idParamSchema), controller.aprovar);
router.post('/:id/reprovar', ...soAdmin, validate(schemas.reprovarSchema), controller.reprovar);
router.post('/:id/inativar', ...soAdmin, validate(schemas.idParamSchema), controller.inativar);
router.post('/:id/reativar', ...soAdmin, validate(schemas.idParamSchema), controller.reativar);

module.exports = router;
