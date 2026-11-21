const { z } = require('zod');

const { textoFormatadoObrigatorio, textoFormatadoOpcional } = require('../../shared/validation/textoFormatado');

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

// GET /programas/:id/universidades: paginada, com busca por nome ou cidade.
const universidadesQuerySchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
  query: z.object({
    q: z.string().trim().min(1).optional(),
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

const tipo = z.enum(['ENTRADA', 'FINANCIAMENTO', 'BOLSA'], {
  errorMap: () => ({ message: 'tipo deve ser ENTRADA, FINANCIAMENTO ou BOLSA' }),
});

// Texto opcional: vazio vira null, para o formulário poder limpar o campo.
const textoOpcional = (max) =>
  z
    .string()
    .trim()
    .max(max, `Use no máximo ${max} caracteres`)
    .transform((valor) => (valor === '' ? null : valor))
    .nullable()
    .optional();

const urlOpcional = z
  .string()
  .trim()
  .max(255)
  .transform((valor) => (valor === '' ? null : valor))
  .refine((valor) => valor === null || /^https?:\/\/\S+$/.test(valor), 'Informe uma URL que comece com http:// ou https://')
  .nullable()
  .optional();

// Campos que a página do programa (T08, RF25) exibe.
const camposPrograma = {
  nome: z.string({ required_error: 'Informe o nome do programa' }).trim().min(1, 'Informe o nome do programa').max(100),
  sigla: textoOpcional(20),
  tipo,
  // Descrição, requisitos e como funciona aceitam formatação (textoFormatado.js).
  descricao: textoFormatadoObrigatorio('Informe a descrição'),
  requisitos: textoFormatadoOpcional(),
  comoFunciona: textoFormatadoOpcional(),
  linkOficial: urlOpcional,
  imagemUrl: urlOpcional,
};

const adminListQuerySchema = {
  query: z.object({
    tipo: tipo.optional(),
    busca: z.string().trim().min(1).optional(),
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

const criarProgramaSchema = { body: z.object(camposPrograma) };

const atualizarProgramaSchema = {
  params: idParamSchema.params,
  body: z
    .object(camposPrograma)
    .partial()
    .refine((dados) => Object.keys(dados).length > 0, { message: 'Informe ao menos um campo para atualizar' }),
};

const data = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Use o formato AAAA-MM-DD')
  .refine((valor) => !Number.isNaN(Date.parse(`${valor}T00:00:00Z`)), 'Data inválida');

// Datas importantes (programa_evento): título, descrição, início e fim.
const camposEvento = {
  titulo: z.string({ required_error: 'Informe o título' }).trim().min(1, 'Informe o título').max(100),
  descricao: textoOpcional(255),
  dataInicio: data,
  dataFim: data.nullable().optional(),
};

const criarEventoSchema = { params: idParamSchema.params, body: z.object(camposEvento) };

const atualizarEventoSchema = {
  params: idParamSchema.params,
  body: z
    .object(camposEvento)
    .partial()
    .refine((dados) => Object.keys(dados).length > 0, { message: 'Informe ao menos um campo para atualizar' }),
};

// RF11: bolsa institucional (programa do tipo BOLSA da universidade). O tipo é fixo.
const camposBolsa = { ...camposPrograma };
delete camposBolsa.tipo;

const bolsaParamsSchema = z.object({
  id: z.coerce.number().int().positive('id inválido'),
  bolsaId: z.coerce.number().int().positive('bolsaId inválido'),
});

const criarBolsaSchema = {
  params: idParamSchema.params,
  body: z.object(camposBolsa).strict('O tipo da bolsa institucional é sempre BOLSA'),
};

const atualizarBolsaSchema = {
  params: bolsaParamsSchema,
  body: z
    .object(camposBolsa)
    .partial()
    .strict('O tipo da bolsa institucional é sempre BOLSA')
    .refine((dados) => Object.keys(dados).length > 0, { message: 'Informe ao menos um campo para atualizar' }),
};

const excluirBolsaSchema = { params: bolsaParamsSchema };

module.exports = {
  criarBolsaSchema,
  atualizarBolsaSchema,
  excluirBolsaSchema,
  idParamSchema,
  universidadesQuerySchema,
  listQuerySchema,
  destaquesQuerySchema,
  adminListQuerySchema,
  criarProgramaSchema,
  atualizarProgramaSchema,
  criarEventoSchema,
  atualizarEventoSchema,
};
