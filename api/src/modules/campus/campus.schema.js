const { z } = require('zod');

const idParamSchema = {
  params: z.object({ id: z.coerce.number().int().positive('id inválido') }),
};

// Texto opcional: vazio vira null, para o formulário poder limpar o campo.
const textoOpcional = (max) =>
  z
    .string()
    .trim()
    .max(max, `Use no máximo ${max} caracteres`)
    .transform((valor) => (valor === '' ? null : valor))
    .nullable()
    .optional();

// CNPJ do campus (RF21, opcional): 14 caracteres, aceitando o formato
// alfanumérico da Receita. A pontuação é removida antes de validar.
const cnpjCampus = z
  .string()
  .trim()
  .transform((valor) => valor.replace(/[.\-/\s]/g, '').toUpperCase())
  .refine((valor) => valor === '' || /^[A-Z0-9]{14}$/.test(valor), 'O CNPJ do campus deve ter 14 caracteres')
  .transform((valor) => (valor === '' ? null : valor))
  .nullable()
  .optional();

const emailOpcional = z
  .string()
  .trim()
  .max(100)
  .transform((valor) => (valor === '' ? null : valor))
  .refine((valor) => valor === null || z.string().email().safeParse(valor).success, 'Informe um e-mail válido')
  .nullable()
  .optional();

const cep = z
  .string({ required_error: 'Informe o CEP' })
  .trim()
  .transform((valor) => valor.replace(/\D/g, ''))
  .refine((valor) => valor.length === 8, 'CEP deve ter 8 dígitos');

const camposEndereco = {
  logradouro: z.string({ required_error: 'Informe o logradouro' }).trim().min(1, 'Informe o logradouro').max(100),
  numero: z.string({ required_error: 'Informe o número' }).trim().min(1, 'Informe o número').max(10),
  complemento: textoOpcional(100),
  bairro: z.string({ required_error: 'Informe o bairro' }).trim().min(1, 'Informe o bairro').max(100),
  cidade: z.string({ required_error: 'Informe a cidade' }).trim().min(1, 'Informe a cidade').max(100),
  estado: z
    .string({ required_error: 'Informe o estado' })
    .trim()
    .length(2, 'UF deve ter 2 letras')
    .transform((valor) => valor.toUpperCase()),
  cep,
};

// RF21 Gerenciar campus (Quadro 26): nome, CNPJ opcional, endereço com CEP,
// telefones, e-mail e indicação de campus principal.
const camposCampus = {
  nome: z.string({ required_error: 'Informe o nome do campus' }).trim().min(1, 'Informe o nome do campus').max(100),
  cnpj: cnpjCampus,
  telefoneCelular: textoOpcional(15),
  telefoneFixo: textoOpcional(15),
  emailCampus: emailOpcional,
  principal: z.boolean().optional(),
};

// POST /universidades/:id/campus
const criarCampusSchema = {
  params: idParamSchema.params,
  body: z.object({ ...camposCampus, endereco: z.object(camposEndereco, { required_error: 'Informe o endereço' }) }),
};

// PATCH /campus/:id: campos e endereço parciais.
const atualizarCampusSchema = {
  params: idParamSchema.params,
  body: z
    .object({ ...camposCampus, endereco: z.object(camposEndereco).partial().strict() })
    .partial()
    .strict('A universidade do campus não pode ser trocada')
    .refine((dados) => Object.keys(dados).length > 0, { message: 'Informe ao menos um campo para atualizar' }),
};

module.exports = { idParamSchema, criarCampusSchema, atualizarCampusSchema };
