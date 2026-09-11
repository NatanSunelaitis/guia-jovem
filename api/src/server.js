const app = require('./app');
const env = require('./config/env');

app.listen(env.PORT, () => {
  console.log(`API Guia Jovem rodando na porta ${env.PORT}`);
  console.log(`Documentação disponível em http://localhost:${env.PORT}/docs`);
});
