const { OAuth2Client } = require('google-auth-library');

const env = require('../../config/env');
const AppError = require('../../shared/errors/AppError');

const client = new OAuth2Client(env.GOOGLE_CLIENT_ID);

/**
 * Verifica um ID token do Google (assinatura, validade e `aud` igual ao
 * GOOGLE_CLIENT_ID) e retorna os dados básicos do perfil. Isolado em módulo
 * próprio para poder ser mockado nos testes (RF05).
 */
async function verifyGoogleIdToken(idToken) {
  try {
    const ticket = await client.verifyIdToken({ idToken, audience: env.GOOGLE_CLIENT_ID });
    const payload = ticket.getPayload();

    return {
      googleId: payload.sub,
      email: payload.email,
      emailVerificado: payload.email_verified === true,
      nome: payload.name ?? payload.email,
      fotoUrl: payload.picture ?? null,
    };
  } catch (erro) {
    throw AppError.unauthenticated('Token do Google inválido ou expirado');
  }
}

module.exports = { verifyGoogleIdToken };
