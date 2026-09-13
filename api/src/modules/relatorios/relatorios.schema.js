const { z } = require('zod');

// RF03/seção 5.10: "Mesmos filtros de /universidades" + formato.
const relatorioQuerySchema = {
  query: z.object({
    q: z.string().trim().min(1).optional(),
    cidade: z.string().trim().min(1).optional(),
    estado: z.string().trim().length(2).optional(),
    natureza: z.enum(['P', 'V']).optional(),
    programaId: z.coerce.number().int().positive().optional(),
    cursoId: z.coerce.number().int().positive().optional(),
    areaCurso: z.string().trim().min(1).optional(),
    notaMinima: z.coerce.number().min(0).max(5).optional(),
    sort: z.enum(['nome', 'media', 'avaliacoes']).optional(),
    formato: z.enum(['csv', 'pdf']),
  }),
};

module.exports = { relatorioQuerySchema };
