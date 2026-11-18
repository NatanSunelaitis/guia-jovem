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

/**
 * Trava as linhas dos administradores ativos até o fim da transação: duas
 * contas de administrador tentando se inativar ao mesmo tempo esperam uma
 * pela outra, e a segunda já enxerga a primeira como inativa.
 */
function travarAdministradoresAtivos(tx) {
  return tx.$queryRaw`SELECT id_usuario FROM usuario WHERE tipo_usuario = 'D' AND ativo = 1 FOR UPDATE`;
}

function contarOutrosAdministradoresAtivos(tx, usuarioId) {
  return tx.usuario.count({ where: { tipoUsuario: 'D', ativo: true, id: { not: usuarioId } } });
}

module.exports = {
  travarAdministradoresAtivos,
  contarOutrosAdministradoresAtivos,
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
