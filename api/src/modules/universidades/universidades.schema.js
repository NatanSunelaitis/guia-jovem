const { z } = require('zod');

const { cnpjObrigatorio } = require('../../shared/validation/cnpj');
const { textoFormatadoOpcional } = require('../../shared/validation/textoFormatado');

const idParamSchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
};

// Filtros da pesquisa dinâmica (RF04). Reaproveitados por
// pesquisas-salvas.schema.js para validar os `parametros` antes de gravar.
const filtrosPesquisaSchema = z.object({
  q: z.string().trim().min(1).optional(),
  cidade: z.string().trim().min(1).optional(),
  estado: z.string().trim().length(2).optional(),
  natureza: z.enum(['P', 'V']).optional(),
  programaId: z.coerce.number().int().positive().optional(),
  cursoId: z.coerce.number().int().positive().optional(),
  // Nome do curso (campo "Curso" da home e da pesquisa).
  curso: z.string().trim().min(1).optional(),
  areaCurso: z.string().trim().min(1).optional(),
  notaMinima: z.coerce.number().min(0).max(5).optional(),
  sort: z.enum(['nome', 'media', 'avaliacoes']).optional(),
});

const listQuerySchema = {
  query: filtrosPesquisaSchema.extend({
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

const destaquesQuerySchema = {
  query: z.object({
    limite: z.coerce.number().int().positive().max(50).optional(),
  }),
};

const paginacaoQuerySchema = {
  params: idParamSchema.params,
  query: z.object({
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

// Administração (RF23): filtro por status e busca por nome.
const adminListQuerySchema = {
  query: z.object({
    status: z.enum(['P', 'A', 'R', 'I'], {
      errorMap: () => ({ message: 'status deve ser P, A, R ou I' }),
    }).optional(),
    busca: z.string().trim().min(1).optional(),
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

const reprovarSchema = {
  params: idParamSchema.params,
  body: z.object({
    motivo: z
      .string({ required_error: 'Informe o motivo da reprovação' })
      .trim()
      .min(1, 'Informe o motivo da reprovação')
      .max(500, 'O motivo deve ter no máximo 500 caracteres'),
  }),
};

const textoOpcional = (max) =>
  z
    .string()
    .trim()
    .max(max, `Use no máximo ${max} caracteres`)
    .transform((valor) => (valor === '' ? null : valor))
    .nullable()
    .optional();

const urlOpcional = z
  .string()
  .trim()
  .max(255)
  .transform((valor) => (valor === '' ? null : valor))
  .refine((valor) => valor === null || /^https?:\/\/\S+$/.test(valor), 'Informe uma URL que comece com http:// ou https://')
  .nullable()
  .optional();

// Edição dos dados institucionais pelo administrador (RF18, seção 5.3).
// Mesmas regras do cadastro (Figura 28); status tem rotas próprias.
const atualizarUniversidadeSchema = {
  params: idParamSchema.params,
  body: z
    .object({
      nomeFantasia: z.string().trim().min(1, 'Informe o nome fantasia').max(100),
      razaoSocial: z.string().trim().min(1, 'Informe a razão social').max(100),
      cnpj: cnpjObrigatorio,
      natureza: z.enum(['P', 'V'], { errorMap: () => ({ message: 'natureza deve ser P ou V' }) }),
      descricao: textoFormatadoOpcional(),
      telefonePrincipal: textoOpcional(15),
      linkPagina: urlOpcional,
      linkSimulados: urlOpcional,
    })
    .partial()
    .strict('Status e programas têm rotas próprias')
    .refine((dados) => Object.keys(dados).length > 0, { message: 'Informe ao menos um campo para atualizar' }),
};

// PUT /universidades/:id/programas: substitui o conjunto de programas aceitos.
const definirProgramasSchema = {
  params: idParamSchema.params,
  body: z
    .object({
      programas: z
        .array(
          z
            .object({
              programaId: z.number({ required_error: 'Informe o programa' }).int().positive(),
              observacao: textoOpcional(255),
            })
            .strict(),
          { required_error: 'Informe a lista de programas (pode ser vazia)' },
        )
        .max(200),
    })
    .strict(),
};

const dataIso = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Use o formato AAAA-MM-DD')
  .refine((valor) => !Number.isNaN(Date.parse(`${valor}T00:00:00Z`)), 'Data inválida');

// GET /universidades/:id/estatisticas: período em datas de Brasília (padrão: 30 dias).
const estatisticasQuerySchema = {
  params: idParamSchema.params,
  query: z
    .object({ de: dataIso.optional(), ate: dataIso.optional() })
    .refine((q) => !q.de || !q.ate || q.de <= q.ate, {
      message: 'A data inicial deve ser anterior ou igual à final',
      path: ['de'],
    }),
};

module.exports = {
  definirProgramasSchema,
  estatisticasQuerySchema,
  atualizarUniversidadeSchema,
  adminListQuerySchema,
  reprovarSchema,
  idParamSchema,
  filtrosPesquisaSchema,
  listQuerySchema,
  destaquesQuerySchema,
  paginacaoQuerySchema,
};
