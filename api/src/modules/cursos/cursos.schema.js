const { z } = require('zod');

const { textoFormatadoOpcional } = require('../../shared/validation/textoFormatado');

const idParamSchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
};

const nomeParamSchema = {
  params: z.object({ nome: z.string().trim().min(1) }),
};

const listQuerySchema = {
  query: z.object({
    q: z.string().trim().min(1).optional(),
    areaCurso: z.string().trim().min(1).optional(),
    modalidade: z.string().trim().min(1).optional(),
    grau: z.string().trim().min(1).optional(),
    universidadeId: z.coerce.number().int().positive().optional(),
    cidade: z.string().trim().min(1).optional(),
    estado: z.string().trim().length(2).optional(),
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

const destaquesQuerySchema = {
  query: z.object({
    limite: z.coerce.number().int().positive().max(200).optional(),
    q: z.string().trim().min(1).optional(),
    areaCurso: z.string().trim().min(1).optional(),
  }),
};

// Texto opcional: vazio vira null, para o formulário poder limpar o campo.
const textoOpcional = (max) =>
  z
    .string()
    .trim()
    .max(max, `Use no máximo ${max} caracteres`)
    .transform((valor) => (valor === '' ? null : valor))
    .nullable()
    .optional();

const camposCurso = {
  nome: z.string({ required_error: 'Informe o nome do curso' }).trim().min(1, 'Informe o nome do curso').max(100),
  areaCurso: textoOpcional(100),
  notaMec: textoOpcional(100),
  modalidade: textoOpcional(20),
  grau: textoOpcional(20),
  duracaoSemestres: z.number().int().min(1).max(20).nullable().optional(),
  descricao: textoFormatadoOpcional(),
};

const adminListQuerySchema = {
  query: z.object({
    busca: z.string().trim().min(1).optional(),
    areaCurso: z.string().trim().min(1).optional(),
    universidadeId: z.coerce.number().int().positive().optional(),
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

// RF19: POST /universidades/:id/cursos (seção 5.5).
const criarCursoSchema = {
  params: idParamSchema.params,
  body: z.object(camposCurso),
};

const atualizarCursoSchema = {
  params: idParamSchema.params,
  body: z
    .object(camposCurso)
    .partial()
    .strict('A universidade do curso não pode ser trocada')
    .refine((dados) => Object.keys(dados).length > 0, { message: 'Informe ao menos um campo para atualizar' }),
};

// RF20: oferta do curso em campus (turno e vagas).
const TURNOS = ['Matutino', 'Vespertino', 'Noturno', 'Integral'];
const turno = z.enum(TURNOS, { errorMap: () => ({ message: 'Turno deve ser Matutino, Vespertino, Noturno ou Integral' }) });
const vagas = z.number({ invalid_type_error: 'Vagas deve ser um número' }).int('Vagas deve ser um número inteiro').min(0).max(10000).nullable();

const criarOfertaSchema = {
  params: idParamSchema.params,
  body: z.object({
    campusId: z.number({ required_error: 'Escolha o campus' }).int().positive('Escolha o campus'),
    turno,
    vagas: vagas.optional(),
  }),
};

const ofertaParamsSchema = z.object({
  id: z.coerce.number().int().positive('id inválido'),
  campusId: z.coerce.number().int().positive('campusId inválido'),
});

const atualizarOfertaSchema = {
  params: ofertaParamsSchema,
  body: z
    .object({ turno, vagas })
    .partial()
    .strict('Para trocar o campus, remova a oferta e crie outra')
    .refine((dados) => Object.keys(dados).length > 0, { message: 'Informe ao menos um campo para atualizar' }),
};

const excluirOfertaSchema = { params: ofertaParamsSchema };

module.exports = {
  TURNOS,
  criarOfertaSchema,
  atualizarOfertaSchema,
  excluirOfertaSchema,
  idParamSchema,
  nomeParamSchema,
  listQuerySchema,
  destaquesQuerySchema,
  adminListQuerySchema,
  criarCursoSchema,
  atualizarCursoSchema,
};
