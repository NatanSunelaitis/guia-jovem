function findById(prisma, id) {
  return prisma.usuario.findUnique({ where: { id } });
}

function findByEmail(prisma, email) {
  return prisma.usuario.findUnique({ where: { email } });
}

function list(prisma, { where, skip, take }) {
  return prisma.usuario.findMany({
    where,
    skip,
    take,
    orderBy: { criadoEm: 'desc' },
  });
}

function count(prisma, where) {
  return prisma.usuario.count({ where });
}

function create(prisma, data) {
  return prisma.usuario.create({ data });
}

function update(prisma, id, data) {
  return prisma.usuario.update({ where: { id }, data });
}

function remove(prisma, id) {
  return prisma.usuario.delete({ where: { id } });
}

function findUniversidadePorDono(prisma, usuarioId) {
  return prisma.universidade.findUnique({ where: { usuarioId } });
}

function inativarUniversidadeDoDono(tx, usuarioId) {
  return tx.universidade.updateMany({ where: { usuarioId }, data: { status: 'I' } });
}

module.exports = {
  findById,
  findByEmail,
  list,
  count,
  create,
  update,
  remove,
  findUniversidadePorDono,
  inativarUniversidadeDoDono,
};
