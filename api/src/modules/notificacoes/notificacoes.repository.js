function idsAdministradoresAtivos(cliente) {
  return cliente.usuario
    .findMany({ where: { tipoUsuario: 'D', ativo: true }, select: { id: true } })
    .then((admins) => admins.map((admin) => admin.id));
}

function criarVarias(cliente, data) {
  return cliente.notificacao.createMany({ data });
}

function listDoUsuario(prisma, usuarioId, { where = {}, skip, take }) {
  return prisma.notificacao.findMany({
    where: { usuarioId, ...where },
    orderBy: [{ criadoEm: 'desc' }, { id: 'desc' }],
    skip,
    take,
  });
}

function countDoUsuario(prisma, usuarioId, where = {}) {
  return prisma.notificacao.count({ where: { usuarioId, ...where } });
}

function findById(prisma, id) {
  return prisma.notificacao.findUnique({ where: { id } });
}

function marcarLida(prisma, id) {
  return prisma.notificacao.update({ where: { id }, data: { lida: true } });
}

function marcarTodasLidas(prisma, usuarioId) {
  return prisma.notificacao.updateMany({ where: { usuarioId, lida: false }, data: { lida: true } });
}

module.exports = {
  idsAdministradoresAtivos,
  criarVarias,
  listDoUsuario,
  countDoUsuario,
  findById,
  marcarLida,
  marcarTodasLidas,
};
