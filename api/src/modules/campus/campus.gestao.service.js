const AppError = require('../../shared/errors/AppError');

/**
 * Campi da universidade (RF21, RF22), geridos pela própria universidade ou
 * pelo administrador. Regras:
 * - a universidade tem sempre exatamente um campus principal: marcar outro
 *   como principal desmarca o anterior, e o principal não pode ser
 *   desmarcado nem excluído (outro precisa ser marcado antes);
 * - o único campus não pode ser excluído;
 * - campus com cursos ofertados não pode ser excluído: as ofertas são
 *   removidas antes (mesma regra do curso ofertado).
 * A exclusão é lógica (ativo = false). As mudanças travam a linha da
 * universidade (SELECT ... FOR UPDATE), para duas alterações simultâneas
 * não deixarem a universidade sem principal ou com dois.
 */

const CAMPOS = ['nome', 'cnpj', 'telefoneCelular', 'telefoneFixo', 'emailCampus', 'principal'];
const CAMPOS_ENDERECO = ['logradouro', 'numero', 'complemento', 'bairro', 'cidade', 'estado', 'cep'];

function soCampos(campus) {
  const dados = {};
  for (const campo of CAMPOS) dados[campo] = campus[campo] ?? null;
  if (campus.endereco) {
    dados.endereco = {};
    for (const campo of CAMPOS_ENDERECO) dados.endereco[campo] = campus.endereco[campo] ?? null;
  }
  return dados;
}

function paraGestao(campus) {
  return {
    id: campus.id,
    nome: campus.nome,
    cnpj: campus.cnpj,
    telefoneCelular: campus.telefoneCelular,
    telefoneFixo: campus.telefoneFixo,
    emailCampus: campus.emailCampus,
    principal: campus.principal,
    endereco: {
      logradouro: campus.endereco.logradouro,
      numero: campus.endereco.numero,
      complemento: campus.endereco.complemento,
      bairro: campus.endereco.bairro,
      cidade: campus.endereco.cidade,
      estado: campus.endereco.estado,
      cep: campus.endereco.cep,
    },
    totalOfertas: campus._count?.campusCursos ?? 0,
  };
}

const INCLUDE_GESTAO = { endereco: true, _count: { select: { campusCursos: true } } };

function travarUniversidade(tx, universidadeId) {
  return tx.$queryRaw`SELECT id_universidade FROM universidade WHERE id_universidade = ${universidadeId} FOR UPDATE`;
}

async function garantirUniversidade(prisma, universidadeId) {
  const universidade = await prisma.universidade.findUnique({ where: { id: universidadeId }, select: { id: true } });
  if (!universidade) throw AppError.notFound('Universidade não encontrada');
}

async function buscarAtivo(prisma, id) {
  const campus = await prisma.campus.findFirst({ where: { id, ativo: true }, include: INCLUDE_GESTAO });
  if (!campus) throw AppError.notFound('Campus não encontrado');
  return campus;
}

/** Campi ativos de qualquer status de universidade (o painel mostra os da pendente também). */
async function listar(prisma, universidadeId) {
  await garantirUniversidade(prisma, universidadeId);
  const campus = await prisma.campus.findMany({
    where: { universidadeId, ativo: true },
    include: INCLUDE_GESTAO,
    orderBy: [{ principal: 'desc' }, { nome: 'asc' }, { id: 'asc' }],
  });
  return campus.map(paraGestao);
}

async function criar(prisma, universidadeId, dados, req) {
  await garantirUniversidade(prisma, universidadeId);
  const { endereco, principal, ...campos } = dados;

  return prisma.$transaction(async (tx) => {
    await travarUniversidade(tx, universidadeId);
    const ativos = await tx.campus.count({ where: { universidadeId, ativo: true } });
    // O primeiro campus é sempre o principal.
    const ehPrincipal = principal === true || ativos === 0;
    if (ehPrincipal) {
      await tx.campus.updateMany({ where: { universidadeId, principal: true }, data: { principal: false } });
    }

    const enderecoCriado = await tx.endereco.create({ data: { ...endereco, complemento: endereco.complemento ?? null } });
    const campus = await tx.campus.create({
      data: {
        universidadeId,
        enderecoId: enderecoCriado.id,
        nome: campos.nome,
        cnpj: campos.cnpj ?? null,
        telefoneCelular: campos.telefoneCelular ?? null,
        telefoneFixo: campos.telefoneFixo ?? null,
        emailCampus: campos.emailCampus ?? null,
        principal: ehPrincipal,
      },
      include: INCLUDE_GESTAO,
    });

    await req.registrarAuditoria(
      { acao: 'CREATE', entidade: 'campus', entidadeId: campus.id, dadosDepois: { universidadeId, ...soCampos(campus) } },
      tx,
    );
    return paraGestao(campus);
  });
}

async function atualizar(prisma, id, dados, req) {
  const antes = await buscarAtivo(prisma, id);
  const { endereco, principal, ...campos } = dados;

  return prisma.$transaction(async (tx) => {
    await travarUniversidade(tx, antes.universidadeId);
    const atual = await tx.campus.findFirst({ where: { id, ativo: true }, select: { principal: true } });
    if (!atual) throw AppError.notFound('Campus não encontrado');

    if (principal === false && atual.principal) {
      throw AppError.conflict(
        'CAMPUS_PRINCIPAL_OBRIGATORIO',
        'A universidade precisa ter um campus principal. Marque outro campus como principal para desmarcar este.',
      );
    }
    if (principal === true && !atual.principal) {
      await tx.campus.updateMany({
        where: { universidadeId: antes.universidadeId, principal: true, id: { not: id } },
        data: { principal: false },
      });
    }

    if (endereco && Object.keys(endereco).length > 0) {
      await tx.endereco.update({ where: { id: antes.enderecoId }, data: endereco });
    }
    const campus = await tx.campus.update({
      where: { id },
      data: { ...campos, ...(principal === true ? { principal: true } : {}) },
      include: INCLUDE_GESTAO,
    });

    await req.registrarAuditoria(
      { acao: 'UPDATE', entidade: 'campus', entidadeId: id, dadosAntes: soCampos(antes), dadosDepois: soCampos(campus) },
      tx,
    );
    return paraGestao(campus);
  });
}

async function excluir(prisma, id, req) {
  const campus = await buscarAtivo(prisma, id);

  await prisma.$transaction(async (tx) => {
    await travarUniversidade(tx, campus.universidadeId);
    const ativos = await tx.campus.count({ where: { universidadeId: campus.universidadeId, ativo: true } });
    if (ativos <= 1) {
      throw AppError.conflict('UNICO_CAMPUS', 'A universidade precisa ter ao menos um campus. Cadastre outro antes de excluir este.');
    }
    const atual = await tx.campus.findFirst({ where: { id, ativo: true }, select: { principal: true } });
    if (!atual) throw AppError.notFound('Campus não encontrado');
    if (atual.principal) {
      throw AppError.conflict(
        'CAMPUS_PRINCIPAL',
        'Este é o campus principal. Marque outro campus como principal antes de excluir este.',
      );
    }
    // Conta dentro da transação: uma oferta nova não escapa da regra.
    const ofertas = await tx.campusCurso.count({ where: { campusId: id } });
    if (ofertas > 0) {
      throw AppError.conflict(
        'CAMPUS_COM_OFERTAS',
        `Este campus oferta ${ofertas} ${ofertas === 1 ? 'curso' : 'cursos'}. Remova as ofertas antes de excluir.`,
      );
    }

    await tx.campus.update({ where: { id }, data: { ativo: false } });
    await req.registrarAuditoria(
      { acao: 'DELETE', entidade: 'campus', entidadeId: id, dadosAntes: soCampos(campus), dadosDepois: { ativo: false } },
      tx,
    );
  });
}

/** Dono do campus para o ownership.middleware; 404 quando não existe. */
async function universidadeDoCampus(prisma, id) {
  const campus = await prisma.campus.findFirst({ where: { id, ativo: true }, select: { universidadeId: true } });
  if (!campus) throw AppError.notFound('Campus não encontrado');
  return campus.universidadeId;
}

module.exports = { listar, criar, atualizar, excluir, universidadeDoCampus, travarUniversidade };
