const { z } = require('zod');

/**
 * Descrições longas com formatação simples (Markdown: parágrafos, subtítulos,
 * listas, negrito, itálico e links), usadas em curso, universidade ("Sobre"),
 * programa e bolsa institucional. A API guarda o texto como veio; quem
 * interpreta a formatação é o app, que exibe como texto puro o que não for
 * suportado (HTML e imagens incluídos).
 *
 * As colunas são TEXT (65.535 bytes). O limite de 10.000 caracteres comporta
 * um texto de várias seções e, mesmo com caracteres de 4 bytes, cabe na coluna.
 */
const LIMITE_TEXTO_FORMATADO = 10000;

const MENSAGEM_LIMITE = 'Use no máximo 10.000 caracteres';

/** Texto formatado opcional: vazio vira null, para o formulário poder limpar o campo. */
const textoFormatadoOpcional = () =>
  z
    .string()
    .trim()
    .max(LIMITE_TEXTO_FORMATADO, MENSAGEM_LIMITE)
    .transform((valor) => (valor === '' ? null : valor))
    .nullable()
    .optional();

/** Texto formatado obrigatório (descrição de programa e de bolsa). */
const textoFormatadoObrigatorio = (mensagemVazio) =>
  z
    .string({ required_error: mensagemVazio })
    .trim()
    .min(1, mensagemVazio)
    .max(LIMITE_TEXTO_FORMATADO, MENSAGEM_LIMITE);

module.exports = { LIMITE_TEXTO_FORMATADO, MENSAGEM_LIMITE, textoFormatadoOpcional, textoFormatadoObrigatorio };
