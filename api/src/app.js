const cors = require('cors');
const express = require('express');
const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');
const path = require('path');

const auditMiddleware = require('./middlewares/audit.middleware');
const errorMiddleware = require('./middlewares/error.middleware');
const metricsMiddleware = require('./middlewares/metrics.middleware');
const AppError = require('./shared/errors/AppError');
const authRoutes = require('./modules/auth/auth.routes');
const usuariosRoutes = require('./modules/usuarios/usuarios.routes');
const universidadesRoutes = require('./modules/universidades/universidades.routes');
const campusRoutes = require('./modules/campus/campus.routes');
const cursosRoutes = require('./modules/cursos/cursos.routes');
const programasRoutes = require('./modules/programas/programas.routes');
const relatoriosRoutes = require('./modules/relatorios/relatorios.routes');
const avaliacoesRoutes = require('./modules/avaliacoes/avaliacoes.routes');
const favoritosRoutes = require('./modules/favoritos/favoritos.routes');

const app = express();

app.use(cors());
app.use(express.json());
app.use(auditMiddleware);
app.use(metricsMiddleware);

const openapiDocument = YAML.load(path.join(__dirname, 'docs', 'openapi.yaml'));
app.use('/docs', swaggerUi.serve, swaggerUi.setup(openapiDocument));

app.get('/api/v1/health', (req, res) => {
  res.json({ data: { status: 'ok' }, meta: {} });
});

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/usuarios', usuariosRoutes);
app.use('/api/v1/universidades', universidadesRoutes);
app.use('/api/v1/campus', campusRoutes);
app.use('/api/v1/cursos', cursosRoutes);
app.use('/api/v1/programas', programasRoutes);
app.use('/api/v1/relatorios', relatoriosRoutes);
app.use('/api/v1/avaliacoes', avaliacoesRoutes);
app.use('/api/v1/favoritos', favoritosRoutes);

app.use((req, res, next) => {
  next(AppError.notFound('Rota não encontrada'));
});

app.use(errorMiddleware);

module.exports = app;
