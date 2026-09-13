const PDFDocument = require('pdfkit');

const prisma = require('../../config/database');
const service = require('./relatorios.service');

async function pesquisa(req, res, next) {
  try {
    const universidades = await service.buscarUniversidades(prisma, req.query);

    if (req.query.formato === 'pdf') {
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename="relatorio-pesquisa.pdf"');
      const documento = new PDFDocument({ margin: 40 });
      documento.pipe(res);
      service.gerarPdf(universidades, documento);
      documento.end();
      return;
    }

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="relatorio-pesquisa.csv"');
    res.send(service.gerarCsv(universidades));
  } catch (erro) {
    next(erro);
  }
}

module.exports = { pesquisa };
