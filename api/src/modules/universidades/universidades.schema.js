const { z } = require('zod');

const idParamSchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
};

// Filtros da pesquisa dinâmica (RF06). Reaproveitados por
// pesquisas-salvas.schema.js para validar os `parametros` antes de gravar.
const filtrosPesquisaSchema = z.object({
  q: z.string().trim().min(1).optional(),
  cidade: z.string().trim().min(1).optional(),
  estado: z.string().trim().length(2).optional(),
  natureza: z.enum(['P', 'V']).optional(),
  programaId: z.coerce.number().int().positive().optional(),
  cursoId: z.coerce.number().int().positive().optional(),
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

module.exports = {
  adminListQuerySchema,
  reprovarSchema,
  idParamSchema,
  filtrosPesquisaSchema,
  listQuerySchema,
  destaquesQuerySchema,
  paginacaoQuerySchema,
};
