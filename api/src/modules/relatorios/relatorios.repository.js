function buscarParaRelatorio(prisma, { where, orderBy, take }) {
  return prisma.universidade.findMany({
    where,
    orderBy,
    take,
    include: {
      campus: { include: { endereco: true } },
      cursos: true,
      universidadeProgramas: { include: { programa: true } },
    },
  });
}

module.exports = { buscarParaRelatorio };
