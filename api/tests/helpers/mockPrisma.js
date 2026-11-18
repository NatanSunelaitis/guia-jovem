function createModel(methods) {
  const model = {};
  for (const nomeMetodo of methods) {
    model[nomeMetodo] = jest.fn().mockResolvedValue(undefined);
  }
  return model;
}

const prisma = {
  usuario: createModel(['findUnique', 'findFirst', 'findMany', 'count', 'create', 'update', 'delete', 'groupBy']),
  refreshToken: createModel(['create', 'findUnique', 'update', 'updateMany']),
  tokenRecuperacao: createModel(['create', 'findUnique', 'update']),
  universidade: createModel(['findUnique', 'findFirst', 'findMany', 'count', 'create', 'update', 'updateMany', 'groupBy']),
  campus: createModel(['findUnique', 'findFirst', 'findMany', 'create']),
  curso: createModel(['findUnique', 'findFirst', 'findMany', 'count', 'create', 'update']),
  campusCurso: createModel(['count']),
  programaEvento: createModel(['findUnique', 'create', 'update', 'delete']),
  programa: createModel(['findUnique', 'findFirst', 'findMany', 'count', 'groupBy', 'create', 'update']),
  universidadePrograma: createModel(['createMany', 'count']),
  endereco: createModel(['create']),
  notificacao: createModel(['create', 'createMany', 'findUnique', 'findMany', 'count', 'update', 'updateMany']),
  sugestao: createModel(['create', 'findUnique', 'findMany', 'count', 'updateMany']),
  avaliacao: createModel(['findUnique', 'findMany', 'count', 'create', 'update', 'delete', 'aggregate']),
  universidadeSalva: createModel(['findUnique', 'findMany', 'count', 'create', 'deleteMany']),
  pesquisaSalva: createModel(['findUnique', 'findFirst', 'findMany', 'count', 'create', 'delete']),
  logAuditoria: createModel(['create']),
  visitaPagina: createModel(['create', 'groupBy']),
  $queryRaw: jest.fn().mockResolvedValue([]),
  $transaction: jest.fn((operacoes) => {
    if (Array.isArray(operacoes)) return Promise.all(operacoes);
    return operacoes(prisma);
  }),
};

/**
 * O middleware de sessão consulta `usuario.findFirst` para saber se a conta
 * segue ativa. Por padrão, toda conta do token está ativa; o teste que
 * quiser uma conta inativa sobrescreve com `mockResolvedValue(null)`.
 */
function contaDoTokenAtiva() {
  prisma.usuario.findFirst.mockImplementation(async ({ where }) => ({ id: where.id }));
}

function resetMockPrisma() {
  for (const [chave, modelo] of Object.entries(prisma)) {
    if (chave === '$transaction') {
      prisma.$transaction.mockClear();
      continue;
    }
    if (chave === '$queryRaw') {
      prisma.$queryRaw.mockClear();
      continue;
    }
    for (const metodo of Object.values(modelo)) {
      metodo.mockReset();
      metodo.mockResolvedValue(undefined);
    }
  }
  contaDoTokenAtiva();
}

contaDoTokenAtiva();

module.exports = prisma;
module.exports.resetMockPrisma = resetMockPrisma;
