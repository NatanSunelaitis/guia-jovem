const jwt = require('jsonwebtoken');
const request = require('supertest');

jest.mock('../src/config/database', () => require('./helpers/mockPrisma'));

const prisma = require('../src/config/database');
const app = require('../src/app');

function tokenPara({ id, tipoUsuario }) {
  return jwt.sign({ sub: id, tipoUsuario, universidadeId: null }, process.env.JWT_ACCESS_SECRET, { expiresIn: '15m' });
}

beforeEach(() => {
  prisma.resetMockPrisma();
});

describe('Verificação de sessão: conta inativada perde o acesso na hora (Pendência 6)', () => {
  it('token válido de conta ativa passa', async () => {
    prisma.notificacao.findMany.mockResolvedValue([]);
    prisma.notificacao.count.mockResolvedValue(0);

    const resposta = await request(app)
      .get('/api/v1/notificacoes')
      .set('Authorization', `Bearer ${tokenPara({ id: 1, tipoUsuario: 'A' })}`);

    expect(resposta.status).toBe(200);
    expect(prisma.usuario.findFirst).toHaveBeenCalledWith({
      where: { id: 1, ativo: true, tipoUsuario: 'A' },
      select: { id: true },
    });
  });

  it.each([
    ['inativada', 'A'],
    ['de administrador inativada', 'D'],
    ['de administrador rebaixada a aluno (token ainda diz D)', 'D'],
  ])('conta %s com token ainda dentro da validade responde 401', async (_, tipoUsuario) => {
    // findFirst com ativo=true não encontra a conta inativa (ou excluída).
    prisma.usuario.findFirst.mockResolvedValue(null);

    const resposta = await request(app)
      .get('/api/v1/usuarios')
      .set('Authorization', `Bearer ${tokenPara({ id: 7, tipoUsuario })}`);

    expect(resposta.status).toBe(401);
    expect(resposta.body.error).toMatchObject({ code: 'UNAUTHENTICATED', message: 'Conta inativa, excluída ou com o perfil alterado. Entre novamente.' });
    expect(prisma.usuario.findMany).not.toHaveBeenCalled();
  });

  it('vale também para rotas públicas com token opcional', async () => {
    prisma.usuario.findFirst.mockResolvedValue(null);

    const resposta = await request(app)
      .get('/api/v1/universidades')
      .set('Authorization', `Bearer ${tokenPara({ id: 7, tipoUsuario: 'A' })}`);

    expect(resposta.status).toBe(401);
  });

  it('sem cabeçalho, a rota pública segue como visitante e não consulta a conta', async () => {
    prisma.universidade.findMany.mockResolvedValue([]);
    prisma.universidade.count.mockResolvedValue(0);

    const resposta = await request(app).get('/api/v1/universidades');

    expect(resposta.status).toBe(200);
    expect(prisma.usuario.findFirst).not.toHaveBeenCalled();
  });
});
