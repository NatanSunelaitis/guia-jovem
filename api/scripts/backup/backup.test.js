const { nomeDoArquivo, arquivosVencidos, lerConfiguracao } = require('./backup');

const DIA = 24 * 60 * 60 * 1000;

describe('backup do banco', () => {
  it('nomeia o arquivo com o banco, a data e a hora', () => {
    expect(nomeDoArquivo('guiajovem', new Date(2026, 10, 18, 3, 5, 9))).toBe('guiajovem-guiajovem-2026-11-18_030509.sql.gz');
  });

  it('remove só os backups mais antigos que a retenção', () => {
    const agora = Date.UTC(2026, 10, 18);
    const arquivos = [
      { nome: 'guiajovem-guiajovem-2026-11-01_030000.sql.gz', modificadoEm: agora - 17 * DIA },
      { nome: 'guiajovem-guiajovem-2026-11-12_030000.sql.gz', modificadoEm: agora - 6 * DIA },
      { nome: 'anotacoes.txt', modificadoEm: agora - 30 * DIA },
    ];
    expect(arquivosVencidos(arquivos, 7, agora).map((a) => a.nome)).toEqual(['guiajovem-guiajovem-2026-11-01_030000.sql.gz']);
  });

  it('lê o banco do DATABASE_URL e deixa o envio externo desligado sem as variáveis', () => {
    const config = lerConfiguracao({ DATABASE_URL: 'mysql://root:s%40nha@127.0.0.1:3307/guiajovem' });
    expect(config).toMatchObject({ host: '127.0.0.1', porta: '3307', usuario: 'root', senha: 's@nha', banco: 'guiajovem', retencao: 7, s3: null });
  });

  it('recusa o envio externo configurado pela metade e a retenção inválida', () => {
    const base = { DATABASE_URL: 'mysql://root:x@localhost/guiajovem' };
    expect(() => lerConfiguracao({ ...base, BACKUP_S3_BUCKET: 'backups' })).toThrow(/faltam BACKUP_S3_ENDPOINT/);
    expect(() => lerConfiguracao({ ...base, BACKUP_RETENCAO_DIAS: '0' })).toThrow(/RETENCAO/);
  });

  it('liga o envio externo quando as quatro variáveis estão definidas', () => {
    const config = lerConfiguracao({
      DATABASE_URL: 'mysql://root:x@localhost/guiajovem',
      BACKUP_S3_ENDPOINT: 'https://conta.r2.cloudflarestorage.com/',
      BACKUP_S3_BUCKET: 'backups',
      BACKUP_S3_ACCESS_KEY_ID: 'id',
      BACKUP_S3_SECRET_ACCESS_KEY: 'segredo',
    });
    expect(config.s3).toMatchObject({ endpoint: 'https://conta.r2.cloudflarestorage.com', regiao: 'auto', prefixo: 'guiajovem/' });
  });
});
