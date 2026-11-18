const { z } = require('zod');

const data = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Use o formato AAAA-MM-DD')
  .refine((valor) => !Number.isNaN(Date.parse(`${valor}T00:00:00Z`)), 'Data inválida');

const periodo = z.object({ de: data.optional(), ate: data.optional() });

const refinarPeriodo = (schema) =>
  schema.refine((q) => !q.de || !q.ate || q.de <= q.ate, {
    message: 'A data inicial deve ser anterior ou igual à final',
    path: ['de'],
  });

const visitasQuerySchema = {
  query: refinarPeriodo(periodo.extend({ agrupar: z.enum(['dia', 'mes']).optional() })),
};

const rankingQuerySchema = {
  query: refinarPeriodo(periodo.extend({ limite: z.coerce.number().int().positive().max(20).optional() })),
};

module.exports = { visitasQuerySchema, rankingQuerySchema };
