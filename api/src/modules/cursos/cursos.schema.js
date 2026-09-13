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
    limite: z.coerce.number().int().positive().max(50).optional(),
  }),
};

module.exports = { idParamSchema, nomeParamSchema, listQuerySchema, destaquesQuerySchema };
