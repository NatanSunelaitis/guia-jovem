const { RESUMO_CAMPUS_PRINCIPAL, RESUMO_PROGRAMAS } = require('../universidades/universidades.repository');

// Universidade inativada ou reprovada depois de salva some da lista do aluno.
function whereDoUsuario(usuarioId) {
  return { usuarioId, universidade: { status: 'A' } };
}

function list(prisma, usuarioId, { skip, take }) {
  return prisma.universidadeSalva.findMany({
    where: whereDoUsuario(usuarioId),
    include: {
      universidade: {
        include: { campus: RESUMO_CAMPUS_PRINCIPAL, universidadeProgramas: RESUMO_PROGRAMAS },
      },
    },
    orderBy: { criadoEm: 'desc' },
    skip,
    take,
  });
}

function count(prisma, usuarioId) {
  return prisma.universidadeSalva.count({ where: whereDoUsuario(usuarioId) });
}

function find(prisma, usuarioId, universidadeId) {
  return prisma.universidadeSalva.findUnique({
    where: { usuarioId_universidadeId: { usuarioId, universidadeId } },
  });
}

function idsSalvasEntre(prisma, usuarioId, universidadeIds) {
  return prisma.universidadeSalva.findMany({
    where: { usuarioId, universidadeId: { in: universidadeIds } },
    select: { universidadeId: true },
  });
}

function create(prisma, usuarioId, universidadeId) {
  return prisma.universidadeSalva.create({ data: { usuarioId, universidadeId } });
}

function remove(prisma, usuarioId, universidadeId) {
  return prisma.universidadeSalva.deleteMany({ where: { usuarioId, universidadeId } });
}

function universidadeAprovada(prisma, id) {
  return prisma.universidade.findFirst({ where: { id, status: 'A' }, select: { id: true } });
}

module.exports = { list, count, find, idsSalvasEntre, create, remove, universidadeAprovada };
