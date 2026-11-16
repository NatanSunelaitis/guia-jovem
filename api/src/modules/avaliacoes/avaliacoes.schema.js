const { z } = require('zod');

const idParamSchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
};

// RF02: nota inteira de 1 a 5 estrelas (CHECK avaliacao_nota_check no banco).
const corpoAvaliacao = z.object({
  nota: z
    .number({ invalid_type_error: 'Informe a nota', required_error: 'Informe a nota' })
    .int('A nota deve ser um número inteiro')
    .min(1, 'A nota deve ser de 1 a 5')
    .max(5, 'A nota deve ser de 1 a 5'),
  comentario: z
    .string()
    .trim()
    .max(500, 'O comentário deve ter no máximo 500 caracteres')
    .nullish()
    .transform((valor) => valor || null),
});

const criarAvaliacaoSchema = {
  params: idParamSchema.params,
  body: corpoAvaliacao,
};

const atualizarAvaliacaoSchema = {
  params: idParamSchema.params,
  body: corpoAvaliacao,
};

const minhasQuerySchema = {
  query: z.object({
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

module.exports = {
  idParamSchema,
  criarAvaliacaoSchema,
  atualizarAvaliacaoSchema,
  minhasQuerySchema,
};
