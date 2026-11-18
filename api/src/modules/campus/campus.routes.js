const { Router } = require('express');

const prisma = require('../../config/database');
const auth = require('../../middlewares/auth.middleware');
const ownership = require('../../middlewares/ownership.middleware');
const requireRole = require('../../middlewares/role.middleware');
const { permitirCorrecaoDoCadastro } = require('../../middlewares/universidade-ativa.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./campus.controller');
const gestao = require('./campus.gestao.service');
const schemas = require('./campus.schema');

const router = Router();

router.get('/:id', validate(schemas.idParamSchema), controller.obter);

// RF21: a universidade dona (pendente, aprovada ou reprovada corrigindo o
// cadastro) ou o administrador altera e exclui o campus.
const donoDoCampus = ownership((req) => gestao.universidadeDoCampus(prisma, req.params.id));
router.patch(
  '/:id',
  auth,
  requireRole('D', 'U'),
  validate(schemas.atualizarCampusSchema),
  donoDoCampus,
  permitirCorrecaoDoCadastro,
  controller.atualizar,
);
router.delete(
  '/:id',
  auth,
  requireRole('D', 'U'),
  validate(schemas.idParamSchema),
  donoDoCampus,
  permitirCorrecaoDoCadastro,
  controller.excluir,
);

module.exports = router;
