const { montarEmail, escaparHtml } = require('./modeloEmail');

describe('modelo de e-mail', () => {
  const email = montarEmail({
    titulo: 'Cadastro não aprovado',
    saudacao: 'Olá, Ana.',
    paragrafos: [['O cadastro de ', { forte: 'Faculdade <Teste> & Cia' }, ' não foi aprovado.']],
    destaque: { titulo: 'Motivo', texto: 'CNPJ "inválido" <script>alert(1)</script>' },
    botao: { texto: 'Corrigir o cadastro', url: 'http://localhost:8080/#/painel-universidade' },
    observacao: 'Depois de corrigir, reenvie.',
  });

  it('escapa tudo o que vem do cadastro', () => {
    expect(email.html).toContain('<strong>Faculdade &lt;Teste&gt; &amp; Cia</strong>');
    expect(email.html).toContain('CNPJ &quot;inválido&quot; &lt;script&gt;');
    expect(email.html).not.toContain('<script>');
    expect(escaparHtml("a'b")).toBe('a&#39;b');
  });

  it('tem logo em PNG hospedado no app, com texto alternativo', () => {
    expect(email.html).toMatch(/<img src="http:\/\/localhost:8080\/email\/logo-guia-jovem\.png"[^>]*alt="Guia Jovem"/);
  });

  it('tem botão de ação, o link também em texto e rodapé', () => {
    expect(email.html).toContain('>Corrigir o cadastro</a>');
    expect(email.html).toContain('Se o botão não funcionar, copie e cole este endereço no navegador');
    expect(email.html).toContain('Este é um e-mail automático');
    expect(email.html).toContain('<html lang="pt-BR">');
  });

  it('usa tabelas e estilos em linha, sem CSS externo nem <style>', () => {
    expect(email.html).toContain('role="presentation"');
    expect(email.html).not.toMatch(/<style|<link /);
  });

  it('gera a versão em texto puro com o link', () => {
    expect(email.texto).toContain('Cadastro não aprovado');
    expect(email.texto).toContain('O cadastro de Faculdade <Teste> & Cia não foi aprovado.');
    expect(email.texto).toContain('Motivo: CNPJ');
    expect(email.texto).toContain('Corrigir o cadastro: http://localhost:8080/#/painel-universidade');
  });
});
