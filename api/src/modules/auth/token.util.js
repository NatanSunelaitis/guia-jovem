const crypto = require('crypto');

const jwt = require('jsonwebtoken');

const env = require('../../config/env');

function signAccessToken(usuario) {
  return jwt.sign(
    {
      sub: usuario.id,
      tipoUsuario: usuario.tipoUsuario,
      universidadeId: usuario.universidade?.id ?? null,
    },
    env.JWT_ACCESS_SECRET,
    { expiresIn: env.JWT_ACCESS_EXPIRES_IN },
  );
}

function signRefreshToken(usuarioId) {
  return jwt.sign({ sub: usuarioId, jti: crypto.randomUUID() }, env.JWT_REFRESH_SECRET, {
    expiresIn: env.JWT_REFRESH_EXPIRES_IN,
  });
}

function hashToken(rawToken) {
  return crypto.createHash('sha256').update(rawToken).digest('hex');
}

function expiryDateOf(rawJwt) {
  const payload = jwt.decode(rawJwt);
  return new Date(payload.exp * 1000);
}

/** Assina o par access/refresh e persiste o refresh_token hasheado. */
async function issueTokenPair(prisma, usuario) {
  const accessToken = signAccessToken(usuario);
  const refreshToken = signRefreshToken(usuario.id);

  await prisma.refreshToken.create({
    data: {
      usuarioId: usuario.id,
      tokenHash: hashToken(refreshToken),
      expiraEm: expiryDateOf(refreshToken),
    },
  });

  return { accessToken, refreshToken };
}

module.exports = {
  signAccessToken,
  signRefreshToken,
  hashToken,
  expiryDateOf,
  issueTokenPair,
};
