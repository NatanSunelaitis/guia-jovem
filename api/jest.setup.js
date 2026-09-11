process.env.NODE_ENV = process.env.NODE_ENV || 'test';
process.env.DATABASE_URL =
  process.env.DATABASE_URL || 'mysql://guiajovem:guiajovem@localhost:3306/guiajovem_test';
process.env.JWT_ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || 'segredo-de-teste-access';
process.env.JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'segredo-de-teste-refresh';
