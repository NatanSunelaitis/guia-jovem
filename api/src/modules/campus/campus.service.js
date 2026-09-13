const AppError = require('../../shared/errors/AppError');
const repo = require('./campus.repository');

async function obterDetalhe(prisma, id) {
  const campus = await repo.findDetalhePublicado(prisma, id);
  if (!campus) {
    throw AppError.notFound('Campus não encontrado');
  }

  return {
    id: campus.id,
    nome: campus.nome,
    telefoneCelular: campus.telefoneCelular,
    telefoneFixo: campus.telefoneFixo,
    emailCampus: campus.emailCampus,
    principal: campus.principal,
    universidade: campus.universidade,
    endereco: {
      logradouro: campus.endereco.logradouro,
      numero: campus.endereco.numero,
      complemento: campus.endereco.complemento,
      bairro: campus.endereco.bairro,
      cidade: campus.endereco.cidade,
      estado: campus.endereco.estado,
      cep: campus.endereco.cep,
    },
    cursos: campus.campusCursos.map((cc) => ({
      id: cc.curso.id,
      nome: cc.curso.nome,
      areaCurso: cc.curso.areaCurso,
      grau: cc.curso.grau,
      turno: cc.turno,
      vagas: cc.vagas,
    })),
  };
}

module.exports = { obterDetalhe };
