const { Router } = require('express');

const prisma = require('../../config/database');
const auth = require('../../middlewares/auth.middleware');
const ownership = require('../../middlewares/ownership.middleware');
const requireRole = require('../../middlewares/role.middleware');
const exigirUniversidadeAtiva = require('../../middlewares/universidade-ativa.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./cursos.controller');
const ofertas = require('./ofertas.service');
const schemas = require('./cursos.schema');

const router = Router();

// RF19 (T24.4): cadastro de cursos pelo administrador. Antes de /:id.
router.get('/administracao', auth, requireRole('D'), validate(schemas.adminListQuerySchema), controller.listarAdmin);
router.get(
  '/administracao/:id',
  auth,
  requireRole('D'),
  validate(schemas.idParamSchema),
  controller.obterAdmin,
);

router.get('/', validate(schemas.listQuerySchema), controller.listar);
router.get('/destaques', validate(schemas.destaquesQuerySchema), controller.destaques);
router.get('/nome/:nome', validate(schemas.nomeParamSchema), controller.obterPorNome);
router.get('/:id', validate(schemas.idParamSchema), controller.obter);

// RF19 e RF20: o administrador ou a universidade dona do curso (pendente ou
// aprovada) altera e exclui o curso e gerencia as ofertas em campus.
const donoDoCurso = ownership((req) => ofertas.universidadeDoCurso(prisma, req.params.id));
const gestaoDoCurso = [auth, requireRole('D', 'U')];

router.patch(
  '/:id',
  ...gestaoDoCurso,
  validate(schemas.atualizarCursoSchema),
  donoDoCurso,
  exigirUniversidadeAtiva,
  controller.atualizar,
);
router.delete('/:id', ...gestaoDoCurso, validate(schemas.idParamSchema), donoDoCurso, exigirUniversidadeAtiva, controller.excluir);

router.post(
  '/:id/ofertas',
  ...gestaoDoCurso,
  validate(schemas.criarOfertaSchema),
  donoDoCurso,
  exigirUniversidadeAtiva,
  controller.criarOferta,
);
router.patch(
  '/:id/ofertas/:campusId',
  ...gestaoDoCurso,
  validate(schemas.atualizarOfertaSchema),
  donoDoCurso,
  exigirUniversidadeAtiva,
  controller.atualizarOferta,
);
router.delete(
  '/:id/ofertas/:campusId',
  ...gestaoDoCurso,
  validate(schemas.excluirOfertaSchema),
  donoDoCurso,
  exigirUniversidadeAtiva,
  controller.excluirOferta,
);

module.exports = router;
