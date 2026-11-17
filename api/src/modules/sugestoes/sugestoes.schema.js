const { z } = require('zod');

const idParamSchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
};

const paginacao = {
  page: z.string().optional(),
  pageSize: z.string().optional(),
};

// RF08: título (VARCHAR(100)), texto e universidade de destino opcional.
const criarSugestaoSchema = {
  body: z.object({
    titulo: z
      .string({ required_error: 'Informe o título', invalid_type_error: 'Informe o título' })
      .trim()
      .min(3, 'O título deve ter pelo menos 3 caracteres')
      .max(100, 'O título deve ter no máximo 100 caracteres'),
    texto: z
      .string({ required_error: 'Escreva a sugestão', invalid_type_error: 'Escreva a sugestão' })
      .trim()
      .min(10, 'A sugestão deve ter pelo menos 10 caracteres')
      .max(2000, 'A sugestão deve ter no máximo 2000 caracteres'),
    universidadeId: z.number().int().positive('Universidade inválida').nullish(),
  }),
};

const minhasQuerySchema = { query: z.object(paginacao) };

const recebidasQuerySchema = {
  query: z.object({
    ...paginacao,
    status: z.enum(['EM_ANALISE', 'APROVADA', 'REPROVADA']).optional(),
  }),
};

// RF15: o destinatário aprova ou reprova, sempre com resposta.
const avaliarSugestaoSchema = {
  params: idParamSchema.params,
  body: z.object({
    status: z.enum(['APROVADA', 'REPROVADA'], {
      errorMap: () => ({ message: 'Escolha Aprovada ou Reprovada' }),
    }),
    resposta: z
      .string({ required_error: 'Escreva a resposta', invalid_type_error: 'Escreva a resposta' })
      .trim()
      .min(1, 'Escreva a resposta')
      .max(2000, 'A resposta deve ter no máximo 2000 caracteres'),
  }),
};

module.exports = {
  idParamSchema,
  criarSugestaoSchema,
  minhasQuerySchema,
  recebidasQuerySchema,
  avaliarSugestaoSchema,
};
