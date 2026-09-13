function findDetalhePublicado(prisma, id) {
  return prisma.campus.findFirst({
    where: { id, ativo: true, universidade: { status: 'A' } },
    include: {
      endereco: true,
      universidade: { select: { id: true, nomeFantasia: true } },
      campusCursos: { include: { curso: true } },
    },
  });
}

module.exports = { findDetalhePublicado };
