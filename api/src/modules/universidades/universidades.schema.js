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

module.exports = {
  idParamSchema,
  filtrosPesquisaSchema,
  listQuerySchema,
  destaquesQuerySchema,
  paginacaoQuerySchema,
};
