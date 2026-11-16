const { z } = require('zod');

const idParamSchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
};

const salvarUniversidadeSchema = {
  body: z.object({
    universidadeId: z
      .number({ invalid_type_error: 'Informe a universidade', required_error: 'Informe a universidade' })
      .int()
      .positive('universidadeId inválido'),
  }),
};

const listQuerySchema = {
  query: z.object({
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

module.exports = { idParamSchema, salvarUniversidadeSchema, listQuerySchema };
