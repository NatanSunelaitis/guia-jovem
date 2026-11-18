const { z } = require('zod');

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
  descricao: textoOpcional(5000),
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

module.exports = {
  idParamSchema,
  nomeParamSchema,
  listQuerySchema,
  destaquesQuerySchema,
  adminListQuerySchema,
  criarCursoSchema,
  atualizarCursoSchema,
};
