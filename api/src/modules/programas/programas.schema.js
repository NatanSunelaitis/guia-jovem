const { z } = require('zod');

const idParamSchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
};

const listQuerySchema = {
  query: z.object({
    tipo: z.enum(['ENTRADA', 'FINANCIAMENTO', 'BOLSA']).optional(),
    q: z.string().trim().min(1).optional(),
    universidadeId: z.coerce.number().int().positive().optional(),
    // z.coerce.boolean() trataria "false" como true (Boolean("false") === true);
    // aceitamos só os literais esperados e convertemos manualmente.
    apenasGlobais: z
      .enum(['true', 'false'])
      .optional()
      .transform((valor) => valor === 'true'),
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

const destaquesQuerySchema = {
  query: z.object({
    limite: z.coerce.number().int().positive().max(50).optional(),
    // A home mostra só os programas de entrada (seção 4.5 do TG).
    tipo: z.enum(['ENTRADA', 'FINANCIAMENTO', 'BOLSA']).optional(),
  }),
};

module.exports = { idParamSchema, listQuerySchema, destaquesQuerySchema };
