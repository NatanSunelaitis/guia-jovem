const { z } = require('zod');

/**
 * CNPJ de 14 caracteres, numérico ou no formato alfanumérico da Receita
 * (letras e números nas 12 primeiras posições). A pontuação é ignorada e
 * as letras ficam maiúsculas antes de validar e gravar.
 */
function limparCnpj(valor) {
  return valor.replace(/[.\-/\s]/g, '').toUpperCase();
}

const cnpjObrigatorio = z
  .string()
  .trim()
  .transform(limparCnpj)
  .refine((valor) => /^[A-Z0-9]{14}$/.test(valor), 'O CNPJ deve ter 14 caracteres (números ou letras e números)');

module.exports = { limparCnpj, cnpjObrigatorio };
