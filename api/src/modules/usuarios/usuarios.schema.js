const { z } = require('zod');

const senha = z.string().min(7, 'Informe uma senha com 7 ou mais caracteres');

const idParamSchema = {
  params: z.object({
    id: z.coerce.number().int().positive('id inválido'),
  }),
};

const listQuerySchema = {
  query: z.object({
    tipoUsuario: z.enum(['A', 'U', 'D']).optional(),
    busca: z.string().trim().min(1).optional(),
    page: z.string().optional(),
    pageSize: z.string().optional(),
  }),
};

const createUsuarioSchema = {
  body: z.object({
    nome: z.string().trim().min(1, 'Informe o nome').max(100),
    email: z.string().trim().email('Informe um e-mail válido').max(100),
    senha,
    // Criação de usuário tipo U exige uma universidade vinculada (RF20/RF25) e
    // só é possível pelo fluxo de /auth/register/universidade (Fase 3).
    tipoUsuario: z.enum(['A', 'D'], {
      errorMap: () => ({ message: "tipoUsuario deve ser 'A' ou 'D' neste endpoint" }),
    }),
    cpf: z.string().length(11, 'cpf deve ter 11 dígitos').optional(),
  }),
};

const updateUsuarioSchema = {
  params: idParamSchema.params,
  body: z
    .object({
      nome: z.string().trim().min(1).max(100).optional(),
      fotoUrl: z.string().trim().url('fotoUrl deve ser uma URL válida').optional(),
      tipoUsuario: z.enum(['A', 'D']).optional(),
      ativo: z.boolean().optional(),
    })
    .refine((dados) => Object.keys(dados).length > 0, {
      message: 'Informe ao menos um campo para atualizar',
    }),
};

const changePasswordSchema = {
  params: idParamSchema.params,
  body: z
    .object({
      senhaAtual: z.string().min(1, 'Informe a senha atual'),
      novaSenha: senha,
      confirmacao: z.string().min(1, 'Confirme a nova senha'),
    })
    .refine((dados) => dados.novaSenha === dados.confirmacao, {
      message: 'A confirmação deve ser igual à nova senha',
      path: ['confirmacao'],
    }),
};

const deleteUsuarioSchema = {
  params: idParamSchema.params,
  body: z.object({
    confirmacao: z.string().optional(),
    senhaAtual: z.string().optional(),
  }),
};

module.exports = {
  idParamSchema,
  listQuerySchema,
  createUsuarioSchema,
  updateUsuarioSchema,
  changePasswordSchema,
  deleteUsuarioSchema,
};
