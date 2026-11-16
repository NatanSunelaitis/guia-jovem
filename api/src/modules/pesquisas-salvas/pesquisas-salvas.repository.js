function findById(prisma, id) {
  return prisma.pesquisaSalva.findUnique({ where: { id } });
}

function findPorNome(prisma, usuarioId, nome) {
  return prisma.pesquisaSalva.findFirst({ where: { usuarioId, nome } });
}

function list(prisma, usuarioId, { skip, take }) {
  return prisma.pesquisaSalva.findMany({
    where: { usuarioId },
    orderBy: { criadoEm: 'desc' },
    skip,
    take,
  });
}

function count(prisma, usuarioId) {
  return prisma.pesquisaSalva.count({ where: { usuarioId } });
}

function create(prisma, data) {
  return prisma.pesquisaSalva.create({ data });
}

function remove(prisma, id) {
  return prisma.pesquisaSalva.delete({ where: { id } });
}

module.exports = { findById, findPorNome, list, count, create, remove };
