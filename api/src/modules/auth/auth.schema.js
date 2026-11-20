const { z } = require('zod');

const { cnpjObrigatorio } = require('../../shared/validation/cnpj');

const senha = z.string().min(7, 'Informe uma senha com 7 ou mais caracteres');

const registerAlunoSchema = {
  body: z.object({
    nome: z.string().trim().min(1, 'Informe o nome').max(100),
    email: z.string().trim().email('Informe um e-mail válido').max(100),
    senha,
  }),
};

// RF09, RF18 e RF23, seção 5.1 e fluxo 7.3 (Figuras 27 a 30).
const registerUniversidadeSchema = {
  body: z.object({
    aceitouTermos: z.literal(true, {
      errorMap: () => ({ message: 'É necessário concordar com os termos e condições' }),
    }),
    usuario: z.object({
      nome: z.string().trim().min(1, 'Informe o nome').max(100),
      email: z.string().trim().email('Informe um e-mail válido').max(100),
      senha,
    }),
    universidade: z.object({
      razaoSocial: z.string().trim().min(1, 'Informe a razão social').max(100),
      nomeFantasia: z.string().trim().min(1, 'Informe o nome fantasia').max(100),
      cnpj: cnpjObrigatorio,
      telefonePrincipal: z.string().trim().min(1).max(15).optional(),
      linkPagina: z.string().trim().url('Informe uma URL válida').max(255).optional(),
      linkSimulados: z.string().trim().url('Informe uma URL válida').max(255).optional(),
      natureza: z.enum(['P', 'V'], { errorMap: () => ({ message: 'Selecione a natureza da instituição' }) }),
    }),
    programasIds: z.array(z.coerce.number().int().positive()).optional().default([]),
    campus: z.object({
      nome: z.string().trim().min(1, 'Informe o nome do campus').max(100),
      telefoneCelular: z.string().trim().min(1).max(15).optional(),
      telefoneFixo: z.string().trim().min(1).max(15).optional(),
      emailCampus: z.string().trim().email('Informe um e-mail válido').max(100).optional(),
      endereco: z.object({
        logradouro: z.string().trim().min(1, 'Informe o logradouro').max(100),
        numero: z.string().trim().min(1, 'Informe o número').max(10),
        complemento: z.string().trim().max(100).optional(),
        bairro: z.string().trim().min(1, 'Informe o bairro').max(100),
        cidade: z.string().trim().min(1, 'Informe a cidade').max(100),
        estado: z.string().trim().length(2, 'UF deve ter 2 letras').toUpperCase(),
        cep: z
          .string()
          .trim()
          .transform((valor) => valor.replace(/\D/g, ''))
          .refine((valor) => valor.length === 0 || valor.length === 8, 'CEP deve ter 8 dígitos')
          .optional(),
      }),
    }),
  }),
};

const loginSchema = {
  body: z.object({
    email: z.string().trim().email('Informe um e-mail válido'),
    senha: z.string().min(1, 'Informe a senha'),
  }),
};

const googleSchema = {
  body: z.object({
    idToken: z.string().min(1, 'idToken é obrigatório'),
  }),
};

const refreshSchema = {
  body: z.object({
    refreshToken: z.string().min(1, 'refreshToken é obrigatório'),
  }),
};

const logoutSchema = {
  body: z.object({
    refreshToken: z.string().min(1, 'refreshToken é obrigatório'),
  }),
};

const forgotPasswordSchema = {
  body: z.object({
    email: z.string().trim().email('Informe um e-mail válido'),
  }),
};

const resetPasswordSchema = {
  body: z.object({
    token: z.string().min(1, 'token é obrigatório'),
    novaSenha: senha,
  }),
};

module.exports = {
  registerAlunoSchema,
  registerUniversidadeSchema,
  loginSchema,
  googleSchema,
  refreshSchema,
  logoutSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
};
