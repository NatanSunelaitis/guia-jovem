function createModel(methods) {
  const model = {};
  for (const nomeMetodo of methods) {
    model[nomeMetodo] = jest.fn().mockResolvedValue(undefined);
  }
  return model;
}

const prisma = {
  usuario: createModel(['findUnique', 'findMany', 'count', 'create', 'update', 'delete']),
  refreshToken: createModel(['create', 'findUnique', 'update', 'updateMany']),
  tokenRecuperacao: createModel(['create', 'findUnique', 'update']),
  universidade: createModel(['findUnique', 'findFirst', 'findMany', 'count', 'create', 'update', 'updateMany']),
  campus: createModel(['findUnique', 'findFirst', 'findMany', 'create']),
  curso: createModel(['findUnique', 'findFirst', 'findMany', 'count']),
  programa: createModel(['findUnique', 'findFirst', 'findMany', 'count']),
  universidadePrograma: createModel(['createMany']),
  endereco: createModel(['create']),
  notificacao: createModel(['create', 'createMany']),
  avaliacao: createModel(['findUnique', 'findMany', 'count', 'create', 'update', 'delete', 'aggregate']),
  universidadeSalva: createModel(['findUnique', 'findMany', 'count', 'create', 'deleteMany']),
  logAuditoria: createModel(['create']),
  visitaPagina: createModel(['create']),
  $queryRaw: jest.fn().mockResolvedValue([]),
  $transaction: jest.fn((operacoes) => {
    if (Array.isArray(operacoes)) return Promise.all(operacoes);
    return operacoes(prisma);
  }),
};

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
}

module.exports = prisma;
module.exports.resetMockPrisma = resetMockPrisma;
