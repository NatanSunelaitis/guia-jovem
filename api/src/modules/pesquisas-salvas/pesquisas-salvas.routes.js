const { Router } = require('express');

const auth = require('../../middlewares/auth.middleware');
const { porUsuario } = require('../../middlewares/ownership.middleware');
const requireRole = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./pesquisas-salvas.controller');
const schemas = require('./pesquisas-salvas.schema');

const router = Router();

// Classe pesquisaSalva: exclusiva do perfil Aluno (docs/DECISOES.md); cada
// aluno só enxerga e exclui as próprias.
router.use(auth, requireRole('A'));

router.get('/', validate(schemas.listQuerySchema), controller.listar);
router.post('/', validate(schemas.criarPesquisaSchema), controller.criar);
router.get('/:id', validate(schemas.idParamSchema), porUsuario(controller.resolverDono), controller.obter);
router.delete('/:id', validate(schemas.idParamSchema), porUsuario(controller.resolverDono), controller.excluir);

module.exports = router;
