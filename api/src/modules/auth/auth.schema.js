const { z } = require('zod');

const senha = z.string().min(7, 'Informe uma senha com 7 ou mais caracteres');

const registerAlunoSchema = {
  body: z.object({
    nome: z.string().trim().min(1, 'Informe o nome').max(100),
    email: z.string().trim().email('Informe um e-mail válido').max(100),
    senha,
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
  loginSchema,
  googleSchema,
  refreshSchema,
  logoutSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
};
