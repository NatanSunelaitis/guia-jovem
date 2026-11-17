const { z } = require('zod');

const idParamSchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
};

const listQuerySchema = {
  query: z.object({
    page: z.string().optional(),
    pageSize: z.string().optional(),
    // Mesmo cuidado do apenasGlobais em programas: z.coerce.boolean() leria "false" como true.
    lida: z
      .enum(['true', 'false'])
      .optional()
      .transform((valor) => (valor === undefined ? undefined : valor === 'true')),
  }),
};

module.exports = { idParamSchema, listQuerySchema };
