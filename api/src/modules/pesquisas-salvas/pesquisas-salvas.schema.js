const { z } = require('zod');

const { filtrosPesquisaSchema } = require('../universidades/universidades.schema');

const idParamSchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
};

const criarPesquisaSchema = {
  body: z.object({
    nome: z
      .string({ required_error: 'Informe um nome para a pesquisa' })
      .trim()
      .min(1, 'Informe um nome para a pesquisa')
      .max(100, 'O nome deve ter no máximo 100 caracteres'),
    // Por ora só a pesquisa de universidades pode ser salva (T02).
    tipo: z.literal('UNIVERSIDADE').default('UNIVERSIDADE'),
    // Mesmo schema de GET /universidades; `strict` recusa filtro desconhecido
    // em vez de descartá-lo em silêncio.
    parametros: filtrosPesquisaSchema.strict().default({}),
  }),
};

const listQuerySchema = {
  query: z.object({
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

module.exports = { idParamSchema, criarPesquisaSchema, listQuerySchema };
