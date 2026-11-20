# Guia Jovem: Especificação Técnica de Desenvolvimento

> Documento de referência para o desenvolvimento da plataforma.
> Origem: Trabalho de Graduação "Guia Jovem: Seu Guia Completo para Financiamento Estudantil, Ingresso Universitário e Bolsas de Estudos" (FATEC Sorocaba, ADS, 2026), de Mayara Sabrina dos Santos e Natan Pierre de Almeida Sunelaitis.
> Numeração: os RF e RNF citados aqui seguem o documento final do TG (RF01 a RF25 e RNF01 a RNF12), a mesma usada no código e no OpenAPI.
> Regra de ouro: tudo o que está aqui foi derivado do TG. Quando houver dúvida entre o que este documento diz e o que o TG diz, o TG prevalece e a divergência deve ser registrada na seção 12.

---

## 0. Como usar este documento

1. Este arquivo vive em `docs/ESPECIFICACAO.md` e é a fonte de verdade do escopo.
2. O `docs/DESIGN-SYSTEM.md` é a fonte de verdade visual; as convenções de código estão na seção 3.
3. Desenvolver seguindo a ordem de fases da seção 11. Cada fase termina com os testes descritos nela passando.
4. Cada requisito funcional (RF) possui um ID. Commits, branches e testes devem referenciar o RF (`feat(RF01): avaliação de universidade`).
5. Antes de implementar uma tela, ler a seção 8 (telas) e a seção 9 (matriz de rastreabilidade) para saber quais endpoints e tabelas ela consome.

---

## 1. Visão geral do produto

**Objetivo:** plataforma web que centraliza informações sobre programas de financiamento estudantil (FIES), bolsas de estudo (ProUni e bolsas institucionais), programas de entrada (ENEM, SiSU, vestibulares) e universidades (com campus e cursos), voltada principalmente a estudantes de ensino médio de escolas públicas.

**Escopo do TG (o que existe no produto):**
- Catálogo público de universidades, campus, cursos e programas de entrada, com pesquisa dinâmica por filtros.
- Página de detalhamento de universidade com links para o site institucional e para a página de simulados anteriores.
- Avaliação de universidades por usuários logados (nota + comentário, com cálculo de média).
- Área de sugestões (usuário envia, administrador é notificado e avalia).
- Cadastro em dois perfis: Aluno e Universidade. Universidade passa por aprovação do Administrador.
- Painel de Administração da Universidade (dados institucionais, cursos, campus, programas de ingresso, bolsas, sugestões recebidas).
- Painel de Administração geral (dashboard, usuários, universidades, cursos, financiamento, bolsas, sugestões, aprovações).
- Login com e-mail/senha e com conta Google, recuperação de senha, alteração de senha, exclusão de conta.
- Relatório de pesquisa exportável (RF02) e estatísticas do site (RF16).

**Fora do escopo (não implementar sem alinhar):** fórum entre alunos, intercâmbio, chat, conteúdo editorial de artigos. Aparecem apenas como sugestões dos entrevistados no Apêndice.

---

## 2. Atores e perfis

| Perfil | Código `tipo_usuario` | Descrição | Acesso |
| --- | --- | --- | --- |
| Visitante | (não autenticado) | Qualquer pessoa navegando | Home, pesquisa, detalhamento, login, cadastro, recuperação de senha |
| Aluno | `A` | Estudante cadastrado | Tudo do Visitante + avaliar universidade, enviar sugestão, salvar faculdades, salvar pesquisas, perfil, alterar senha, excluir conta |
| Universidade | `U` | Representante de uma instituição | Tudo do Aluno (exceto avaliar) + Painel de Administração da Universidade (somente da sua instituição). Só aparece publicamente após aprovação |
| Administrador | `D` | Equipe Guia Jovem | Painel de Administração geral: CRUD de tudo, aprovação de universidades, avaliação de sugestões, estatísticas |

Observação sobre o TG: o modelo lógico define `tipoUsuario VARCHAR(1)`. Mantemos o campo com um caractere e a legenda acima. No diagrama de classes o administrador possui `CPF`; manter o campo `cpf` apenas para o perfil `D`, opcional, respeitando o RNF07 (não coletar dados além do necessário).

---

## 3. Stack, arquitetura e convenções

### 3.1 Stack (fixada pelo RNF12 do TG)

| Camada | Tecnologia | Observação |
| --- | --- | --- |
| Apresentação | Flutter (Dart), alvo Web principal, com Android/iOS como bônus | Flutter Web responsivo. O protótipo do Stitch (HTML/Tailwind) é referência visual, não código a ser reaproveitado literalmente |
| Negócio | Node.js + Express.js | API REST em JSON, padrão MVC (Controller e Model, conforme Figura 7 do TG) |
| Dados | MySQL 8 | Acesso via Prisma ORM (recomendado) ou mysql2 + Knex. Migrations versionadas |
| Autenticação | JWT (access token + refresh token) e OAuth 2.0 Google | Senhas com bcrypt (RNF02) |
| E-mail | Nodemailer com SMTP configurável | Recuperação de senha e aprovação de universidade |
| Testes | Backend: Jest + Supertest. Frontend: flutter_test + integration_test | Cobertura mínima nas regras de negócio |
| Infra local | Docker Compose (mysql + api) | `docker compose up` sobe o ambiente |

### 3.2 Repositórios

O TG cita o repositório `GuiaJovem-Front-end`. Recomendação: monorepo com dois pacotes, mantendo o histórico.

```
guia-jovem/
├── docs/
│   ├── ESPECIFICACAO.md            (este arquivo)
│   ├── DESIGN-SYSTEM.md
│   ├── DECISOES.md                 (divergências e decisões registradas durante o desenvolvimento)
│   └── prototipo/                  (exportação HTML do protótipo aprovado, por grupo de telas)
├── api/                            (Node.js + Express)
├── app/                            (Flutter)
├── docker-compose.yml
└── README.md
```

### 3.3 Estrutura do backend (`api/`)

```
api/
├── src/
│   ├── server.js                   sobe o Express
│   ├── app.js                      middlewares globais, rotas, tratamento de erro
│   ├── config/
│   │   ├── env.js                  leitura e validação de variáveis de ambiente
│   │   ├── database.js             conexão MySQL / Prisma client
│   │   └── mailer.js
│   ├── middlewares/
│   │   ├── auth.middleware.js      valida JWT, injeta req.user
│   │   ├── role.middleware.js      requireRole('D'), requireRole('U','D')
│   │   ├── ownership.middleware.js Universidade só altera a própria instituição
│   │   ├── validate.middleware.js  valida body/query com Zod
│   │   ├── audit.middleware.js     grava log_auditoria (RNF09)
│   │   ├── metrics.middleware.js   grava visita_pagina (RF16)
│   │   └── error.middleware.js     formato padrão de erro
│   ├── modules/
│   │   ├── auth/                   RF05, RF06, RF07
│   │   ├── usuarios/               RF09, alterar senha, excluir conta
│   │   ├── universidades/          RF03, RF18, RF23
│   │   ├── campus/                 RF21, RF22
│   │   ├── cursos/                 RF19, RF20
│   │   ├── programas/              RF10, RF11, RF12, RF13, RF17 (entrada, financiamento, bolsa)
│   │   ├── avaliacoes/             RF01
│   │   ├── sugestoes/              RF08, RF14, RF15
│   │   ├── pesquisa/               RF04, RF02
│   │   ├── favoritos/              faculdades salvas e pesquisas salvas (perfil aluno)
│   │   ├── notificacoes/           RF14
│   │   └── estatisticas/           RF16
│   │   (cada módulo: *.routes.js, *.controller.js, *.service.js, *.repository.js, *.schema.js, *.test.js)
│   ├── shared/
│   │   ├── errors/AppError.js
│   │   ├── utils/pagination.js
│   │   ├── utils/cnpj.js           validação de CNPJ
│   │   └── utils/report.js         geração de CSV/PDF (RF02)
│   └── docs/openapi.yaml           contrato da API (Swagger UI em /docs)
├── prisma/
│   ├── schema.prisma
│   ├── migrations/
│   └── seed.js                     admin inicial, programas padrão (ENEM, SiSU, ProUni, FIES), universidades de exemplo
├── tests/
├── .env.example
└── package.json
```

### 3.4 Estrutura do frontend (`app/`)

Arquitetura em camadas por feature, com Riverpod (ou Bloc) para estado e go_router para navegação.

```
app/
├── lib/
│   ├── main.dart
│   ├── app.dart                    MaterialApp.router + tema do design system
│   ├── core/
│   │   ├── theme/                  tokens e ThemeData (ver DESIGN-SYSTEM.md)
│   │   │   ├── gj_colors.dart
│   │   │   ├── gj_typography.dart
│   │   │   ├── gj_spacing.dart
│   │   │   ├── gj_radius.dart
│   │   │   └── gj_theme.dart
│   │   ├── router/app_router.dart  rotas e guards por perfil
│   │   ├── network/api_client.dart Dio + interceptor JWT + refresh
│   │   ├── storage/token_storage.dart
│   │   ├── utils/ (formatters de CNPJ, telefone, validators)
│   │   └── constants/
│   ├── shared/
│   │   ├── widgets/                componentes do design system (GJButton, GJCard, GJInput, GJModal, GJTabs, GJTag, GJEmptyState, GJToast, GJRating, GJCarousel, GJHeader, GJFooter, GJDataTable)
│   │   └── layouts/                PublicLayout, ProfileLayout, AdminLayout
│   ├── features/
│   │   ├── home/
│   │   ├── universidades/          pesquisa, detalhe, campus, avaliação
│   │   ├── programas/              pesquisa, detalhe
│   │   ├── cursos/                 lista e detalhe
│   │   ├── auth/                   login, cadastro (aluno/universidade), recuperar senha
│   │   ├── perfil/                 perfil, alterar senha, excluir conta, sugestões, salvos
│   │   ├── sugestoes/
│   │   ├── painel_universidade/    6 abas
│   │   └── painel_admin/           8 abas
│   │   (cada feature: data/ (dto, repository), domain/ (model), presentation/ (page, widgets, controller))
│   └── l10n/                       textos em pt-BR
├── test/
├── integration_test/
└── pubspec.yaml
```

### 3.5 Convenções

- Idioma do código: inglês em identificadores técnicos, português em textos exibidos ao usuário e nomes de tabelas/colunas (conforme o modelo lógico do TG).
- Tabelas em `snake_case` singular (`usuario`, `universidade`). Colunas em `snake_case`.
- Respostas da API sempre em envelope: `{ "data": ..., "meta": {...} }` para sucesso e `{ "error": { "code": "...", "message": "...", "details": [...] } }` para erro.
- Paginação padrão: `?page=1&pageSize=20`, resposta `meta: { page, pageSize, total, totalPages }`.
- Datas em ISO 8601 UTC.
- Toda ação de escrita gera registro em `log_auditoria` (RNF09).
- Tempo de resposta alvo abaixo de 5 s em qualquer operação (RNF11). Índices nas colunas de filtro da pesquisa.
- Exclusões de usuário são físicas (RNF07 e Figura 36: "eliminar permanentemente"), com anonimização das avaliações e sugestões deixadas (mantém a média, remove o vínculo). Exclusões de catálogo (universidade, campus, curso, programa) são lógicas via `ativo`.

---

## 4. Modelo de dados

### 4.1 Base: modelo lógico do TG (Figura 9) e complementos necessários

O modelo lógico do TG traz as tabelas `USUARIO`, `UNIVERSIDADE`, `CAMPUS`, `ENDERECO`, `CURSO` e `PROGRAMA DE ENTRADA`. Para atender aos 25 RFs e às telas descritas (Figuras 12 a 36) e ao diagrama de classes (Figura 10: `Sugestão`, `pesquisaSalva`, `endereco`, `programaEntrada`), foram adicionadas as tabelas marcadas com **(complemento)**. Toda adição tem justificativa no RF correspondente.

### 4.2 Decisões de modelagem (registrar no TG se necessário)

1. **Curso x Campus:** o modelo lógico coloca `idCampus` dentro de `CURSO`. O RF20 ("Relacionar curso e campus") e a Figura 19 (campus mostra os cursos que oferece) indicam que um mesmo curso da universidade pode existir em vários campus. Decisão: `curso` pertence à universidade e a tabela `campus_curso` faz o relacionamento N:N. Isso atende ao RF19, RF20 e RF21 sem duplicar cursos.
2. **Programa de entrada unificado:** o modelo lógico tem uma tabela `PROGRAMA DE ENTRADA` com coluna `tipo VARCHAR(15)`. Decisão: uma única tabela `programa` com `tipo ENUM('ENTRADA','FINANCIAMENTO','BOLSA')`. RF10 (financiamento), RF11 (bolsa) e RF17 (entrada) são o mesmo CRUD filtrado por tipo. Programas globais (ENEM, SiSU, ProUni, FIES) são criados pelo Administrador com `id_universidade NULL`. Bolsas institucionais são criadas pela Universidade com `id_universidade` preenchido (aba "Bolsas de Estudo" do painel da universidade).
3. **Endereço:** tabela própria conforme o modelo lógico, 1:1 com campus. A universidade tem endereço principal via o campus marcado como `principal = 1`.
4. **Status da universidade:** `VARCHAR(1)`: `P` pendente, `A` aprovada, `R` reprovada, `I` inativa. Somente `A` aparece nas pesquisas públicas (RF23).
5. **Sugestão:** status conforme RF15: `EM_ANALISE` (padrão), `APROVADA`, `REPROVADA`. Sugestão pode ser direcionada ao Guia Jovem (`id_universidade NULL`) ou a uma universidade (aba "Sugestões" do painel da universidade).

### 4.3 DDL de referência (MySQL 8)

```sql
CREATE TABLE usuario (
  id_usuario        INT AUTO_INCREMENT PRIMARY KEY,
  nome              VARCHAR(100) NOT NULL,
  email             VARCHAR(100) NOT NULL UNIQUE,
  senha_hash        VARCHAR(255) NULL,            -- NULL quando conta criada só via Google
  tipo_usuario      CHAR(1) NOT NULL,             -- A aluno | U universidade | D administrador
  cpf               CHAR(11) NULL,                -- apenas perfil D, opcional
  google_id         VARCHAR(64) NULL UNIQUE,
  foto_url          VARCHAR(255) NULL,
  ativo             TINYINT(1) NOT NULL DEFAULT 1,
  criado_em         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (tipo_usuario IN ('A','U','D'))
);

CREATE TABLE universidade (
  id_universidade   INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario        INT NOT NULL UNIQUE,          -- conta do perfil Universidade (dono)
  nome_fantasia     VARCHAR(100) NOT NULL,
  razao_social      VARCHAR(100) NOT NULL,
  cnpj              CHAR(14) NOT NULL UNIQUE,
  descricao         TEXT NULL,
  telefone_principal VARCHAR(15) NULL,
  link_pagina        VARCHAR(255) NULL,           -- RF03: site institucional
  link_simulados     VARCHAR(255) NULL,           -- RF03: página de simulados anteriores
  logo_url           VARCHAR(255) NULL,
  natureza           CHAR(1) NOT NULL DEFAULT 'V', -- P pública | V privada (filtro "Públicas/Federais" vs "Privadas" da Figura 17)
  status             CHAR(1) NOT NULL DEFAULT 'P', -- P pendente | A aprovada | R reprovada | I inativa (RF23)
  aprovado_em        DATETIME NULL,
  aprovado_por       INT NULL,
  media_avaliacao    DECIMAL(3,2) NULL,            -- cache calculado (RF01)
  total_avaliacoes   INT NOT NULL DEFAULT 0,
  criado_em          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  FOREIGN KEY (aprovado_por) REFERENCES usuario(id_usuario),
  INDEX idx_universidade_status (status),
  INDEX idx_universidade_nome (nome_fantasia)
);

CREATE TABLE endereco (
  id_endereco   INT AUTO_INCREMENT PRIMARY KEY,
  logradouro    VARCHAR(100) NOT NULL,
  numero        VARCHAR(10) NOT NULL,
  complemento   VARCHAR(100) NULL,
  bairro        VARCHAR(100) NOT NULL,
  cidade        VARCHAR(100) NOT NULL,
  estado        CHAR(2) NOT NULL,
  cep           CHAR(8) NULL,
  INDEX idx_endereco_cidade (cidade),
  INDEX idx_endereco_estado (estado)
);

CREATE TABLE campus (
  id_campus        INT AUTO_INCREMENT PRIMARY KEY,
  id_universidade  INT NOT NULL,
  id_endereco      INT NOT NULL,
  nome             VARCHAR(100) NOT NULL,
  telefone_celular VARCHAR(15) NULL,
  telefone_fixo    VARCHAR(15) NULL,
  email_campus     VARCHAR(100) NULL,
  principal        TINYINT(1) NOT NULL DEFAULT 0,
  ativo            TINYINT(1) NOT NULL DEFAULT 1,
  FOREIGN KEY (id_universidade) REFERENCES universidade(id_universidade) ON DELETE CASCADE,
  FOREIGN KEY (id_endereco) REFERENCES endereco(id_endereco)
);

CREATE TABLE curso (
  id_curso        INT AUTO_INCREMENT PRIMARY KEY,
  id_universidade INT NOT NULL,
  nome            VARCHAR(100) NOT NULL,
  area_curso      VARCHAR(100) NULL,             -- ex.: Saúde, Tecnologia, Humanas
  nota_mec        VARCHAR(100) NULL,             -- conforme modelo lógico (texto livre, ex.: "4")
  modalidade      VARCHAR(20) NULL,              -- Presencial | EAD | Híbrido
  grau            VARCHAR(20) NULL,              -- Bacharelado | Licenciatura | Tecnólogo
  duracao_semestres TINYINT NULL,
  descricao       TEXT NULL,
  ativo           TINYINT(1) NOT NULL DEFAULT 1,
  FOREIGN KEY (id_universidade) REFERENCES universidade(id_universidade) ON DELETE CASCADE,
  INDEX idx_curso_nome (nome),
  INDEX idx_curso_area (area_curso)
);

CREATE TABLE campus_curso (                      -- RF20 (complemento ao modelo lógico)
  id_campus INT NOT NULL,
  id_curso  INT NOT NULL,
  turno     VARCHAR(20) NULL,                    -- Manhã | Tarde | Noite | Integral
  vagas     INT NULL,
  PRIMARY KEY (id_campus, id_curso),
  FOREIGN KEY (id_campus) REFERENCES campus(id_campus) ON DELETE CASCADE,
  FOREIGN KEY (id_curso)  REFERENCES curso(id_curso)  ON DELETE CASCADE
);

CREATE TABLE programa (                          -- PROGRAMA DE ENTRADA do modelo lógico, unificado
  id_programa     INT AUTO_INCREMENT PRIMARY KEY,
  nome            VARCHAR(100) NOT NULL,
  sigla           VARCHAR(20) NULL,              -- ENEM, SISU, PROUNI, FIES
  descricao       TEXT NOT NULL,
  tipo            ENUM('ENTRADA','FINANCIAMENTO','BOLSA') NOT NULL,  -- RF17 | RF10 | RF11
  requisitos      TEXT NULL,
  como_funciona   TEXT NULL,
  link_oficial    VARCHAR(255) NULL,
  imagem_url      VARCHAR(255) NULL,
  id_usuario      INT NOT NULL,                  -- quem cadastrou
  id_universidade INT NULL,                      -- NULL = programa global (governo); preenchido = bolsa/programa institucional
  ativo           TINYINT(1) NOT NULL DEFAULT 1,
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  FOREIGN KEY (id_universidade) REFERENCES universidade(id_universidade) ON DELETE CASCADE,
  INDEX idx_programa_tipo (tipo)
);

CREATE TABLE programa_evento (                   -- "Cronograma" e "Datas Importantes" do protótipo (complemento)
  id_evento    INT AUTO_INCREMENT PRIMARY KEY,
  id_programa  INT NOT NULL,
  titulo       VARCHAR(100) NOT NULL,            -- Inscrições, Provas, Resultado
  descricao    VARCHAR(255) NULL,
  data_inicio  DATE NOT NULL,
  data_fim     DATE NULL,
  FOREIGN KEY (id_programa) REFERENCES programa(id_programa) ON DELETE CASCADE
);

CREATE TABLE universidade_programa (             -- RF12, RF13, RF17 (relacionamento "Possui" do DER)
  id_universidade INT NOT NULL,
  id_programa     INT NOT NULL,
  observacao      VARCHAR(255) NULL,             -- ex.: "aceita nota do ENEM a partir de 450"
  PRIMARY KEY (id_universidade, id_programa),
  FOREIGN KEY (id_universidade) REFERENCES universidade(id_universidade) ON DELETE CASCADE,
  FOREIGN KEY (id_programa) REFERENCES programa(id_programa) ON DELETE CASCADE
);

CREATE TABLE avaliacao (                         -- RF01 (relacionamento "Avalia" do DER)
  id_avaliacao    INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario      INT NULL,                      -- NULL após exclusão de conta (anonimizada)
  id_universidade INT NOT NULL,
  nota            TINYINT NOT NULL,              -- 1 a 5
  comentario      VARCHAR(500) NULL,
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_avaliacao_usuario_univ (id_usuario, id_universidade),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE SET NULL,
  FOREIGN KEY (id_universidade) REFERENCES universidade(id_universidade) ON DELETE CASCADE,
  CHECK (nota BETWEEN 1 AND 5)
);

CREATE TABLE sugestao (                          -- RF08, RF15 (classe Sugestão do diagrama)
  id_sugestao     INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario      INT NULL,
  id_universidade INT NULL,                      -- NULL = sugestão para o Guia Jovem
  titulo          VARCHAR(100) NOT NULL,
  texto           TEXT NOT NULL,
  status          ENUM('EM_ANALISE','APROVADA','REPROVADA') NOT NULL DEFAULT 'EM_ANALISE',
  resposta        TEXT NULL,
  avaliado_por    INT NULL,
  avaliado_em     DATETIME NULL,
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE SET NULL,
  FOREIGN KEY (id_universidade) REFERENCES universidade(id_universidade) ON DELETE CASCADE,
  FOREIGN KEY (avaliado_por) REFERENCES usuario(id_usuario)
);

CREATE TABLE notificacao (                       -- RF14, RF23 (complemento)
  id_notificacao  INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario      INT NOT NULL,                  -- destinatário
  tipo            VARCHAR(30) NOT NULL,          -- NOVA_SUGESTAO | UNIVERSIDADE_PENDENTE | UNIVERSIDADE_APROVADA | SUGESTAO_AVALIADA
  titulo          VARCHAR(100) NOT NULL,
  mensagem        VARCHAR(255) NOT NULL,
  referencia_tipo VARCHAR(30) NULL,              -- sugestao | universidade
  referencia_id   INT NULL,
  lida            TINYINT(1) NOT NULL DEFAULT 0,
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  INDEX idx_notificacao_usuario_lida (id_usuario, lida)
);

CREATE TABLE universidade_salva (                -- "Faculdades Salvas" da Figura 25 (complemento)
  id_usuario      INT NOT NULL,
  id_universidade INT NOT NULL,
  criado_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario, id_universidade),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
  FOREIGN KEY (id_universidade) REFERENCES universidade(id_universidade) ON DELETE CASCADE
);

CREATE TABLE pesquisa_salva (                    -- classe pesquisaSalva do diagrama (complemento)
  id_pesquisa  INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario   INT NOT NULL,
  nome         VARCHAR(100) NOT NULL,
  tipo         ENUM('UNIVERSIDADE','PROGRAMA','CURSO') NOT NULL,
  parametros   JSON NOT NULL,                    -- filtros aplicados
  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

CREATE TABLE token_recuperacao (                 -- RF07 (complemento)
  id_token    INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario  INT NOT NULL,
  token_hash  CHAR(64) NOT NULL UNIQUE,
  expira_em   DATETIME NOT NULL,
  usado_em    DATETIME NULL,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

CREATE TABLE refresh_token (                     -- RF05, RF06 (complemento)
  id_refresh  INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario  INT NOT NULL,
  token_hash  CHAR(64) NOT NULL UNIQUE,
  expira_em   DATETIME NOT NULL,
  revogado_em DATETIME NULL,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

CREATE TABLE log_auditoria (                     -- RNF09 (complemento)
  id_log      BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_usuario  INT NULL,
  acao        VARCHAR(20) NOT NULL,              -- CREATE | UPDATE | DELETE | LOGIN | LOGOUT | APROVAR
  entidade    VARCHAR(40) NOT NULL,
  entidade_id INT NULL,
  dados_antes JSON NULL,
  dados_depois JSON NULL,
  ip          VARCHAR(45) NULL,
  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE visita_pagina (                     -- RF16 (complemento). Sem dados pessoais: RNF07
  id_visita   BIGINT AUTO_INCREMENT PRIMARY KEY,
  rota        VARCHAR(120) NOT NULL,
  entidade    VARCHAR(30) NULL,                  -- universidade | programa | curso
  entidade_id INT NULL,
  tipo_usuario CHAR(1) NULL,                     -- NULL visitante
  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_visita_data (criado_em),
  INDEX idx_visita_entidade (entidade, entidade_id)
);
```

### 4.4 Seed obrigatório

- 1 usuário Administrador (`D`) com credenciais vindas do `.env`.
- Programas globais: ENEM (ENTRADA), SiSU (ENTRADA), Vestibular Tradicional (ENTRADA), ProUni (BOLSA), FIES (FINANCIAMENTO), PNAES (BOLSA, assistência), com descrição, como funciona, requisitos e link oficial baseados na seção 2.1 do TG.
- 3 universidades de exemplo aprovadas (Fatec, USP, UNESP, usadas nas figuras do TG), cada uma com pelo menos 2 campus e 4 cursos.
- Cursos listados na Figura 15: Administração, Biomedicina, Medicina Veterinária, Nutrição, Pedagogia, Gestão de Recursos Humanos, Farmácia, Ciências Contábeis.

---

## 5. API REST: contrato

Base: `/api/v1`. Autenticação via header `Authorization: Bearer <access_token>`. Legenda de acesso: **Pub** público, **Aut** qualquer logado, **A** aluno, **U** universidade (dona), **D** administrador.

### 5.1 Auth (RF05, RF06, RF07)

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| POST | `/auth/register/aluno` | Pub | Body: `nome, email, senha`. Cria usuário `A`. Retorna tokens |
| POST | `/auth/register/universidade` | Pub | Body: `aceitouTermos (true), usuario{nome,email,senha}, universidade{razaoSocial, nomeFantasia, cnpj, telefonePrincipal, linkPagina, linkSimulados, natureza}, programasIds[], campus{nome, telefoneCelular, telefoneFixo, emailCampus, endereco{...}}`. Cria usuário `U` + universidade `status=P` + relacionamentos + primeiro campus (`principal=1`). Notifica admins (`UNIVERSIDADE_PENDENTE`). Corresponde ao fluxo das Figuras 27 a 30 |
| POST | `/auth/login` | Pub | Body: `email, senha`. Retorna `accessToken, refreshToken, usuario{ id, nome, email, tipoUsuario, fotoUrl, universidade?{id,status} }` |
| POST | `/auth/google` | Pub | Body: `idToken` do Google. Cria ou vincula conta `A`. Universidade não pode ser criada via Google (precisa dos dados institucionais) |
| POST | `/auth/refresh` | Pub | Body: `refreshToken`. Rotaciona o refresh token |
| POST | `/auth/logout` | Aut | Revoga o refresh token. Frontend pede confirmação antes (RF06, passo 2) |
| POST | `/auth/forgot-password` | Pub | Body: `email`. Sempre responde 200 (não revela se o e-mail existe). Envia e-mail com link `/#/redefinir-senha?token=...` válido por 1 h |
| POST | `/auth/reset-password` | Pub | Body: `token, novaSenha` |
| GET | `/auth/me` | Aut | Dados do usuário logado |

Regras: senha com mínimo 7 caracteres (Figura 24: "senha com 7 ou mais caracteres"), hash bcrypt custo 12. Access token 15 min, refresh 7 dias. Login de universidade com `status=P` é permitido, mas o painel exibe aviso "Cadastro em análise" e o perfil não aparece publicamente. `status=R` bloqueia o painel com a justificativa.

### 5.2 Usuários (RF09, alteração de senha, exclusão)

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| GET | `/usuarios` | D | Lista paginada, filtros `tipoUsuario, busca` |
| GET | `/usuarios/:id` | D ou próprio | Detalhe |
| PATCH | `/usuarios/:id` | D ou próprio | `nome, fotoUrl`. Admin pode alterar `tipoUsuario` e `ativo` |
| PATCH | `/usuarios/:id/senha` | próprio | Body: `senhaAtual, novaSenha, confirmacao` (Figura 35) |
| DELETE | `/usuarios/:id` | D ou próprio | Exclusão permanente. Body: `confirmacao: "EXCLUIR"` ou senha atual. Anonimiza avaliações e sugestões. Se for `U`, a universidade vai para `status=I` |
| POST | `/usuarios` | D | Admin cria usuário de qualquer tipo |

### 5.3 Universidades (RF03, RF18, RF23)

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| GET | `/universidades` | Pub | Pesquisa dinâmica (RF04). Query: `q, cidade, estado, natureza (P/V), programaId, cursoId, areaCurso, page, pageSize, sort (nome|media|avaliacoes)`. Retorna só `status=A` |
| GET | `/universidades/destaques` | Pub | Carrossel da home (Figura 13): top N por média/visitas |
| GET | `/universidades/:id` | Pub | Detalhe (Figura 18): dados, endereço principal, media, total avaliações, `programas[]` agrupados por tipo, `campus[]` resumido, `linkPagina`, `linkSimulados`. Registra `visita_pagina` |
| GET | `/universidades/:id/campus` | Pub | Lista campus com cursos (Figura 19) |
| GET | `/universidades/:id/cursos` | Pub | Cursos da universidade |
| GET | `/universidades/:id/avaliacoes` | Pub | Lista paginada de avaliações |
| POST | `/universidades` | D | Admin cadastra universidade já aprovada (RF18) |
| PATCH | `/universidades/:id` | U (dona) ou D | Atualiza dados institucionais (aba Informações do painel) |
| DELETE | `/universidades/:id` | D | Exclusão lógica (`status=I`) |
| PUT | `/universidades/:id/programas` | U (dona) ou D | Body: `programasIds[]`. Substitui o conjunto (RF12, RF13, RF17) |
| GET | `/universidades/pendentes` | D | Lista `status=P` (RF23) |
| POST | `/universidades/:id/aprovar` | D | `status=A`, `aprovado_em`, envia e-mail e notificação (RF23) |
| POST | `/universidades/:id/reprovar` | D | Body: `motivo`. `status=R`, envia e-mail |

Regra RF03: `linkPagina` e `linkSimulados` são retornados como URLs absolutas validadas; o frontend abre em nova aba.

### 5.4 Campus (RF21, RF22)

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| GET | `/campus/:id` | Pub | Detalhe com endereço e cursos |
| POST | `/universidades/:id/campus` | U (dona) ou D | Body: `nome, telefoneCelular, telefoneFixo, emailCampus, principal, endereco{logradouro, numero, complemento, bairro, cidade, estado, cep}` (Figura 30) |
| PATCH | `/campus/:id` | U (dona) ou D | Atualiza campus e endereço |
| DELETE | `/campus/:id` | U (dona) ou D | Lógica. Não permite excluir o único campus |
| PUT | `/campus/:id/cursos` | U (dona) ou D | Body: `[{cursoId, turno, vagas}]`. RF20 |

### 5.5 Cursos (RF19, RF20)

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| GET | `/cursos` | Pub | Pesquisa: `q, areaCurso, modalidade, grau, universidadeId, cidade, estado`. Agrupa por nome para a lista "Principais Cursos" (Figura 15) |
| GET | `/cursos/destaques` | Pub | 8 cursos mais ofertados (Figura 15) |
| GET | `/cursos/:id` | Pub | Detalhe + campus onde é ofertado |
| GET | `/cursos/nome/:nome` | Pub | "Em quais universidades este curso está disponível" (texto da Figura 15) |
| POST | `/universidades/:id/cursos` | U (dona) ou D | Cria curso |
| PATCH | `/cursos/:id` | U (dona) ou D | Atualiza |
| DELETE | `/cursos/:id` | U (dona) ou D | Lógica |

### 5.6 Programas (RF10, RF11, RF17, RF12, RF13)

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| GET | `/programas` | Pub | Query: `tipo (ENTRADA|FINANCIAMENTO|BOLSA), q, universidadeId, apenasGlobais`. Pesquisa da Figura 20 |
| GET | `/programas/destaques` | Pub | Carrossel da home (Figura 14) |
| GET | `/programas/:id` | Pub | Detalhe (Figura 21 e protótipo Stitch): descrição, como funciona, requisitos, `eventos[]` (cronograma), `universidades[]` que aceitam. Registra visita |
| POST | `/programas` | D (globais) ou U (com `universidadeId` próprio, apenas tipo BOLSA) | Cria |
| PATCH | `/programas/:id` | D ou U (dona) | Atualiza |
| DELETE | `/programas/:id` | D ou U (dona) | Lógica |
| POST | `/programas/:id/eventos` | D ou U (dona) | Cronograma |
| PATCH/DELETE | `/programas/eventos/:id` | D ou U (dona) | |
| GET | `/programas/:id/universidades` | Pub | Universidades relacionadas |

### 5.7 Avaliações (RF01)

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| POST | `/universidades/:id/avaliacoes` | A | Body: `nota (1..5), comentario`. Uma por usuário por universidade (upsert). Recalcula `media_avaliacao` e `total_avaliacoes` em transação |
| PATCH | `/avaliacoes/:id` | próprio | Edita |
| DELETE | `/avaliacoes/:id` | próprio ou D | Remove e recalcula |
| GET | `/avaliacoes/minhas` | A | Avaliações do aluno |

### 5.8 Sugestões e notificações (RF08, RF14, RF15)

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| POST | `/sugestoes` | Aut | Body: `titulo, texto, universidadeId?`. Cria `EM_ANALISE`. Dispara notificação `NOVA_SUGESTAO` para todos os `D` (ou para o dono da universidade, se `universidadeId`) |
| GET | `/sugestoes` | D (todas) ou U (da sua universidade) | Query: `status, page` |
| GET | `/sugestoes/minhas` | Aut | Histórico de sugestões (Figura 25) |
| GET | `/sugestoes/:id` | D, U (dona), autor | Detalhe |
| PATCH | `/sugestoes/:id/status` | D ou U (dona) | Body: `status (APROVADA|REPROVADA|EM_ANALISE), resposta?`. Notifica o autor (`SUGESTAO_AVALIADA`) |
| GET | `/notificacoes` | Aut | Lista, `naoLidas` count |
| PATCH | `/notificacoes/:id/lida` | Aut | Marca lida |
| PATCH | `/notificacoes/lidas` | Aut | Marca todas |

### 5.9 Favoritos e pesquisas salvas (perfil aluno, Figura 25 e classe pesquisaSalva)

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| GET/POST/DELETE | `/favoritos/universidades[/:id]` | A, U | Faculdades salvas |
| GET/POST/DELETE | `/pesquisas-salvas[/:id]` | A, U | Body: `nome, tipo, parametros` |

### 5.10 Relatório de pesquisa (RF02) e estatísticas (RF16)

| Método | Rota | Acesso | Descrição |
| --- | --- | --- | --- |
| GET | `/relatorios/pesquisa` | Pub | Mesmos filtros de `/universidades` + `formato (csv|pdf)`. Gera arquivo com universidades, campus, cursos e programas do resultado. "O sistema gera relatório no formato que usuário especifica" |
| GET | `/estatisticas/resumo` | D | Cards do dashboard: total usuários por tipo, universidades por status, cursos, programas, sugestões por status, avaliações |
| GET | `/estatisticas/visitas` | D | Query: `de, ate, agrupar (dia|mes)`. Série temporal de visitas e visitas por tipo de usuário ("visitas no site; quantidade de usuários logados; média por mês") |
| GET | `/estatisticas/ranking` | D | Universidades, programas e cursos mais visitados |
| GET | `/estatisticas/universidade/:id` | U (dona) | Visualizações (30 d) e interessados (favoritos) do card "Estatísticas do Perfil" do protótipo |
| GET | `/estatisticas/exportar` | D | CSV do relatório escolhido |

### 5.11 Erros padronizados

| HTTP | code | Quando |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Zod falhou. `details[]` com campo e mensagem |
| 401 | `UNAUTHENTICATED` | Sem token ou expirado |
| 403 | `FORBIDDEN` | Perfil sem permissão ou não é dono |
| 403 | `UNIVERSIDADE_NAO_APROVADA` | Universidade tenta ação que exige aprovação |
| 404 | `NOT_FOUND` | |
| 409 | `EMAIL_EM_USO`, `CNPJ_EM_USO`, `AVALIACAO_DUPLICADA` | |
| 429 | `RATE_LIMITED` | Login e forgot-password: 10 req/15 min por IP |
| 500 | `INTERNAL_ERROR` | Nunca vaza stack em produção |

---

## 6. Regras de negócio consolidadas

1. **Aprovação (RF23):** universidade nasce `P`. Só `A` é listada publicamente, recebe avaliações e aparece em relatórios. Ao aprovar, enviar e-mail ("sua conta foi aprovada") e criar notificação. O aviso da Figura 27 informa prazo de até 15 dias.
2. **Avaliação (RF01):** só perfil `A` logado, uma avaliação por universidade, nota inteira de 1 a 5, comentário opcional até 500 caracteres. Média com 2 decimais, recalculada em transação. Universidade não avalia (evita autoavaliação).
3. **Sugestão (RF08, RF14, RF15):** qualquer logado envia. Notificação imediata aos destinatários. Status inicial `EM_ANALISE`. Avaliador pode registrar resposta. Autor vê o histórico com status no perfil.
4. **Pesquisa dinâmica (RF04, RNF05):** todos os filtros são opcionais; sem nenhum filtro, retorna os destaques. O TG coloca "logado" como pré-condição no Quadro 6, mas o ator é Visitante e as telas (Figuras 17 e 20) são públicas. Decisão: pesquisa pública; salvar pesquisa exige login.
5. **Links externos (RF03, RNF06):** sempre `target=_blank` com `rel=noopener`. Se a universidade não informou `linkSimulados`, ocultar o botão em vez de mostrar link quebrado (RNF06).
6. **Propriedade (ownership):** perfil `U` só lê/escreve recursos cuja `id_universidade` pertença ao seu usuário. Verificado no middleware, nunca só no frontend.
7. **Exclusão de conta:** exige confirmação explícita (Figura 36). Irreversível. Universidade excluída deixa de aparecer imediatamente.
8. **Privacidade (RNF07):** não coletar CPF de alunos, não gravar IP em `visita_pagina`, não expor e-mail de usuários em avaliações públicas (mostrar apenas primeiro nome).
9. **Logs (RNF09):** todo POST/PATCH/PUT/DELETE grava `log_auditoria` antes de responder, dentro da mesma transação quando possível.
10. **Logoff (RF06):** frontend exibe confirmação; backend revoga refresh token; frontend limpa storage e redireciona para a home.

---

## 7. Fluxos principais (diagramas de atividade do TG)

### 7.1 RF01 Avaliar Universidade
Aluno acessa detalhe da universidade > clica em "Avaliar" > se não logado, abre modal de login e retorna à tela > escolhe nota (1 a 5 estrelas) e escreve comentário > envia > API valida, salva/atualiza, recalcula média > tela atualiza a média e a lista de avaliações com a nova no topo.

### 7.2 RF14 Notificação de Sugestão
Usuário logado abre "Sugestões" (perfil ou rodapé) > preenche título e texto (e opcionalmente a universidade) > envia > API salva `EM_ANALISE` e cria uma `notificacao` para cada administrador (ou para o dono da universidade) > o sino do header do painel mostra contador > administrador abre a notificação > cai na tela de avaliação da sugestão (RF15) > seleciona status e resposta > autor recebe notificação.

### 7.3 Cadastro de Universidade (Figuras 23, 27 a 30)
"Criar conta" > escolhe "Universidade" > tela de aviso (avaliação administrativa, dados usados somente para validação, retorno em até 15 dias) > checkbox "Concordo com os termos e condições" > Prosseguir > Passo 1 dados institucionais (razão social, CNPJ, nome fantasia, telefone principal, link da página inicial, link de simulados anteriores, e-mail, senha, confirmar senha) > Passo 2 programas de entrada aceitos (multi-seleção agrupada em Financiamento, Bolsas, Entrada) > Passo 3 primeiro campus (nome, logradouro, bairro, cidade, estado, número, telefone) > Cadastrar > tela de sucesso "Cadastro enviado para análise" > login liberado com aviso de pendência.

### 7.4 Recuperação de senha (RF07)
Login > "Esqueci minha senha" > informa e-mail > mensagem neutra de sucesso > e-mail com link > tela "Redefinir senha" (nova senha + confirmação) > sucesso > login.

---

## 8. Telas: inventário completo e especificação

Numeração alinhada às figuras do TG. Para cada tela: rota, acesso, componentes, dados, ações e estados (loading, vazio, erro). Referências de layout visual em `docs/prototipo/` e no `DESIGN-SYSTEM.md`.

### Layout público (PublicLayout)
- **Header fixo** (Figura 12): logo "Guia Jovem" à esquerda; links Início, Programas de Entrada, Universidades (item ativo com sublinhado); à direita botão "Entrar" (pill). Logado: avatar com menu (Visualizar Perfil, Painel Administrativo [se U ou D], Desligar, Excluir Conta em vermelho), conforme Figuras 25, 31 e 34. Mobile: menu hambúrguer.
- **Footer** (Figura 16): coluna esquerda "Guia Jovem" + texto "Sobre o Guia Jovem" (O Guia Jovem é uma plataforma que ajuda estudantes a encontrar as melhores faculdades e programas de entrada com bolsas de estudo), contato (e-mail, telefone), copyright "© 2026 Guia Jovem. O Mentor Dinâmico."; coluna direita links Sobre, Contato, Privacidade, Termos.

### T01 Home `/` (Figuras 12 a 16) | Pub
- Hero com título e barra de pesquisa tripla: "Escolha uma cidade", "Curso que deseja estudar", "Faculdade que deseja estudar" + toggle "Públicas / Federais" e "Privadas" + botão Pesquisar. Submete para T02 com query string.
- Seção "Faculdades" com link "Ver todas as faculdades": carrossel de cards (logo, nome, descrição curta, média com estrelas e total de avaliações, botão "Saiba Mais"). Fonte: `/universidades/destaques`.
- Seção "Programas de Entrada" com "Ver todos os programas": carrossel de cards (imagem, sigla, nome, descrição curta, "Saiba Mais"). Fonte: `/programas/destaques`.
- Seção "Principais Cursos Disponíveis": grade 4 colunas de cards ilustrados com o nome do curso, link "Ver mais cursos". Fonte: `/cursos/destaques`. Clique leva a T06.
- Estados: skeleton nos carrosséis; se API falhar, mensagem "Não foi possível carregar" com botão tentar novamente.

### T02 Pesquisa de Universidades `/universidades` (Figuras 17 e 18) | Pub
- Barra de filtros: universidade (texto), cidade (texto ou autocomplete), toggle natureza, slider "Nota" mínima (Figura 17), filtros avançados colapsáveis: estado, programa aceito, área do curso. Botão Pesquisar. Chips dos filtros aplicados. Botão "Salvar pesquisa" (só logado).
- Resultado: grade de cards de universidade (logo, nome, cidade/UF, média, programas em tags). Paginação. Ordenar por nome, média, avaliações.
- Botão "Gerar relatório" (RF02): abre menu CSV ou PDF, chama `/relatorios/pesquisa` com os filtros atuais.
- Vazio: ilustração + "Nenhuma universidade encontrada com esses filtros".

### T03 Detalhe da Universidade `/universidades/:id` (Figura 18) | Pub
- Apresentado como modal grande no TG (Figura 18) sobre a pesquisa; no design final pode ser página. Conteúdo: logo, nome, descrição, botão "Acessar Página da Faculdade" (RF03), botão "Simulados Anteriores" (RF03, oculto se vazio), média + total avaliações.
- Bloco "Campus": campo "Pesquisar campus" + lista (nome, cidade, botão "ver campus" > T04).
- Bloco "Como entrar na universidade": lista dos programas aceitos agrupados (Programas de Entrada, Financiamento, Bolsas) com tags clicáveis para T08.
- Bloco "Avaliações": média, distribuição por nota, lista paginada (primeiro nome, nota, comentário, data). Botão "Avaliar" (RF01) abre modal T03a.
- Ação "Salvar faculdade" (ícone de favorito, só logado).

### T03a Modal Avaliar Universidade | A
- Seletor de 5 estrelas, textarea 500 caracteres com contador, botões Cancelar e Enviar. Se já avaliou, abre preenchido com opção Atualizar.

### T04 Detalhe do Campus `/campus/:id` (Figura 19) | Pub
- Modal/página: nome do campus, "Lista de cursos oferecidos neste campus", endereço completo, telefones, e-mail. Lista de cursos com turno e vagas; clique leva a T06.

### T05 Pesquisa de Programas de Entrada `/programas` (Figura 20 e protótipo Stitch "Programas de Entrada") | Pub
- Hero "Escolha o Programa de Entrada que deseja ver" com campo único "Qual programa deseja ver?" e botão Pesquisar (Stitch).
- Filtro por tipo em tabs ou chips: Todos, Programas de Entrada, Financiamento, Bolsas de Estudo.
- Grid de cards (imagem, ícone, sigla colorida por tipo, título, descrição, botão "Ver Detalhes") conforme bento grid do Stitch.

### T06 Detalhe do Curso `/cursos/:id` e `/cursos/nome/:nome` | Pub
- Nome, área, grau, modalidade, duração, descrição. Lista "Universidades que oferecem este curso" com campus e cidade (texto da Figura 15). Link para T03.

### T07 (reservado) Lista de cursos `/cursos` | Pub
- Grid com busca e filtro por área. Origem: "Ver mais cursos" da Figura 15.

### T08 Detalhe do Programa `/programas/:id` (Figura 21 e protótipo Stitch "ENEM") | Pub
- Hero: tag "Programa de entrada / Financiamento / Bolsa", título, descrição, imagem, botões "Ver site oficial" e "Voltar".
- Cards: "Como Funciona", "Elegibilidade / Requisitos", "Datas Importantes" (eventos do cronograma em timeline), "Universidades que aceitam" (grid com logo e nome, link para T03).
- CTA final "Pronto para começar seu futuro?" pode ser reaproveitado do protótipo, apontando para T02.

### T09 Login `/login` (Figura 22) | Pub
- Modal/card centralizado "Acesse sua conta!": e-mail, senha (mostrar/ocultar), botão "Acessar minha conta", link "Esqueci minha senha", link "Ainda não tem conta? Criar uma conta", separador "OU", botão "Entrar com Google".
- Erro de credencial inline. Redireciona para a rota de origem após login.

### T10 Escolha do tipo de cadastro `/cadastro` (Figura 23) | Pub
- Modal "Qual tipo de cadastro gostaria de fazer?" com dois blocos explicativos e botões "Aluno" e "Universidade". Textos: "Se você deseja ingressar futuramente em uma universidade e quer buscar informações... escolha a opção Aluno" e "Agora se você é o representante legal de alguma universidade... escolha a opção Universidade".

### T11 Cadastro de Aluno `/cadastro/aluno` (Figura 24) | Pub
- "Vamos criar sua conta no Guia Jovem?" Campos: nome, e-mail, senha (7+ caracteres), confirmar senha. Botão "Criar conta", separador, "Entrar com Google". Validação inline com mensagens em vermelho (Figura 24).

### T12 Aviso de Cadastro de Universidade `/cadastro/universidade` (Figura 27) | Pub
- Card "Atenção!" com o texto de aviso, checkbox "Concordo com os termos e condições", botão "Prosseguir" desabilitado até marcar.

### T13 Cadastro Universidade Passo 1 `/cadastro/universidade/dados` (Figura 28) | Pub
- Stepper de 3 passos no topo. Campos: razão social, nome fantasia, CNPJ (máscara e validação), natureza (pública/privada), telefone principal, link da página inicial, link da página de simulados anteriores (opcional), e-mail, senha, confirmar senha. Botão "Próximo".

### T14 Cadastro Universidade Passo 2 `/cadastro/universidade/programas` (Figura 29) | Pub
- "Adicione os programas de entrada aceitos por sua instituição!" Multi-seleção em três grupos: Programas de Financiamento, Bolsas de Estudo, Programas de Entrada. Botões "Voltar" e "Próximo".

### T15 Cadastro Universidade Passo 3 `/cadastro/universidade/campus` (Figura 30) | Pub
- "Cadastre seu primeiro Campus!" Campos: nome do campus, logradouro, número, complemento, bairro, cidade, estado (select UF), CEP, telefone. Botões "Voltar" e "Cadastrar". Sucesso: tela "Cadastro enviado para análise, você receberá um e-mail".

### T16 Perfil do Aluno `/perfil` (Figuras 25 e 26) | A
- Avatar com botão de câmera para alterar foto, campos nome e e-mail, botões empilhados: Editar Perfil, Alterar Senha (T21), Histórico de Sugestões (T18), Faculdades Salvas (T19), e botão vermelho "Sair" (RF06 com confirmação). Excluir conta fica no menu do header (Figura 26) e abre T22.

### T17 Perfil da Universidade `/perfil` (Figuras 31 e 32) | U
- Igual ao T16 mais o botão "Painel Administrativo" (T23). Badge de status da universidade (Em análise, Aprovada, Reprovada).

### T18 Histórico de Sugestões `/perfil/sugestoes` | Aut
- Lista com título, data, status em tag colorida (Em análise, Aprovada, Reprovada) e resposta quando houver. Botão "Nova sugestão" abre T20.

### T19 Faculdades Salvas `/perfil/salvos` | Aut
- Grid de cards de universidade com ação de remover. Aba secundária "Pesquisas salvas" com nome, tipo, filtros e botão "Executar".

### T20 Nova Sugestão (modal) | Aut
- Campos: título, texto (até 2000), select opcional "Direcionar para uma universidade". Botão Enviar. Toast de sucesso.

### T21 Alterar Senha (modal, Figura 35) | Aut
- Senha atual, nova senha, confirmar nova senha, botão "Alterar Senha". Feedback de sucesso ou erro.

### T22 Excluir Conta (diálogo, Figura 36) | Aut
- Título "Confirmação", texto "Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita.", campo de confirmação (senha ou digitar EXCLUIR), botões "Cancelar" e "Excluir" (vermelho).

### T23 Painel de Administração da Universidade `/painel-universidade` (Figura 33 e protótipo Stitch "Painel de Administração da Universidade") | U aprovada (pendente vê aviso)
Layout do protótipo: header com "Guia Jovem | Painel de Administração da Universidade", sino de notificações, avatar. Título "Configurações Gerais", botões "Descartar" e "Salvar Alterações". Tabs horizontais com ícones:
1. **Informações** (`PATCH /universidades/:id`): seções "Identidade Institucional" (nome fantasia, razão social, CNPJ, status de operação read-only), "Localização e Contato" (endereço principal, telefone, e-mail), "Descrição", "Links" (página, simulados). Coluna lateral: card "Visibilidade da Página" (status aprovado/pendente), card "Estatísticas do Perfil" (visualizações 30 d, interessados) via `/estatisticas/universidade/:id`, card upload "Logo da Instituição".
2. **Cursos** (RF19, RF20): tabela (nome, área, grau, modalidade, campus onde é ofertado, ações). Botão "Novo curso" abre drawer com formulário + multi-seleção de campus com turno e vagas.
3. **Campus** (RF21): tabela (nome, cidade/UF, telefone, principal, ações). Drawer com formulário completo de campus e endereço. Não permite excluir o único campus.
4. **Programas de Entrada** (RF12, RF17): multi-seleção dos programas globais tipo ENTRADA e FINANCIAMENTO com salvar.
5. **Bolsas de Estudo** (RF11, RF13): dois blocos: bolsas globais aceitas (ProUni etc., seleção) e bolsas institucionais (CRUD próprio: nome, descrição, requisitos, percentual, link).
6. **Sugestões** (RF15 no escopo da universidade): lista de sugestões direcionadas à universidade com filtro por status e ação de avaliar (drawer com status + resposta).

### T24 Painel de Administração (Guia Jovem) `/admin` (Figura 34) | D
Mesmo layout do T23, título "Painel de Administração". Tabs:
1. **Dashboard** (RF16): cards de resumo (`/estatisticas/resumo`), gráfico de visitas por dia/mês, ranking de universidades/programas/cursos mais vistos, filtro de período, botão "Exportar relatório".
2. **Usuários** (RF09): tabela (nome, e-mail, tipo, ativo, criado em), busca, filtro por tipo, ações editar/excluir, botão "Novo usuário".
3. **Universidades** (RF18, RF23): sub-aba "Pendentes de aprovação" (cards com dados completos, botões Aprovar e Reprovar com motivo) e sub-aba "Todas" (tabela com status, ações editar/inativar, acesso ao painel da universidade em modo admin).
4. **Cursos** (RF19): tabela global com filtro por universidade e área, CRUD.
5. **Financiamento** (RF10): CRUD de programas tipo FINANCIAMENTO com cronograma.
6. **Bolsas de Estudo** (RF11): CRUD de programas tipo BOLSA globais.
7. **Programas de Entrada** (RF17): CRUD de programas tipo ENTRADA. (A Figura 34 mostra 7 abas; esta é acrescentada porque o RF17 exige gerenciar programas de entrada.)
8. **Sugestões** (RF14, RF15): lista de todas as sugestões, filtro por status, indicador de não lidas, avaliação com resposta.

### T25 Redefinir senha `/redefinir-senha?token=` | Pub
- Nova senha, confirmar, botão Redefinir. Token inválido mostra mensagem e link para solicitar de novo.

### T26 Esqueci minha senha `/recuperar-senha` | Pub
- Campo e-mail, botão Enviar, mensagem neutra de sucesso.

### T27 Notificações (dropdown do sino) | Aut
- Lista das últimas 10 com título, mensagem, tempo relativo, estado lida/não lida, "Marcar todas como lidas". Clique navega para a referência.

---

## 9. Matriz de rastreabilidade RF x Tela x Endpoint x Tabela

| RF | Descrição | Telas | Endpoints | Tabelas |
| --- | --- | --- | --- | --- |
| RF01 | Avaliar universidade | T03, T03a | POST /universidades/:id/avaliacoes | avaliacao, universidade |
| RF02 | Relatório de pesquisa | T02 | GET /relatorios/pesquisa | universidade, campus, curso, programa |
| RF03 | Página de detalhamento da universidade, com os links do site e dos simulados | T03, T04 | GET /universidades/:id (`linkPagina`, `linkSimulados`), /campus | universidade, campus, endereco, curso |
| RF04 | Pesquisa dinâmica | T01, T02, T05, T07 | GET /universidades, /programas, /cursos | todas de catálogo |
| RF04 (extensão) | Salvar pesquisa | T02, T19 | /pesquisas-salvas | pesquisa_salva |
| RF05 | Login | T09 | POST /auth/login, /auth/google | usuario, refresh_token |
| RF06 | Logoff | menu header, T16, T17 | POST /auth/logout | refresh_token |
| RF07 | Recuperar senha | T26, T25 | POST /auth/forgot-password, /auth/reset-password | token_recuperacao |
| RF08 | Área de sugestão | T20, T18 | POST /sugestoes, GET /sugestoes/minhas | sugestao |
| RF09 | Fazer cadastro, gerenciar perfil e gerenciar usuários | T11, T16, T17, T21, T22, T24.2 | /usuarios, /auth/register/*, PATCH /usuarios/:id/senha, DELETE /usuarios/:id | usuario e dependentes |
| RF10 | Gerenciar financiamento | T24.5 | /programas (tipo FINANCIAMENTO) | programa, programa_evento |
| RF11 | Gerenciar bolsa | T24.6, T23.5 | /programas (tipo BOLSA) | programa |
| RF12 | Relacionar financiamento x universidade | T14, T23.4 | PUT /universidades/:id/programas | universidade_programa |
| RF13 | Relacionar bolsa x universidade | T14, T23.5 | PUT /universidades/:id/programas | universidade_programa |
| RF14 | Notificação de sugestão | T27 | GET /notificacoes | notificacao |
| RF15 | Avaliação de sugestão | T24.8, T23.6 | PATCH /sugestoes/:id/status | sugestao, notificacao |
| RF16 | Estatísticas do site | T24.1 | /estatisticas/* | visita_pagina e agregações |
| RF17 | Relacionar programa de entrada x universidade | T14, T23.4, T24.7 | PUT /universidades/:id/programas | universidade_programa |
| RF18 | Gerenciar universidade | T13 a T15, T23.1, T24.3 | /universidades | universidade |
| RF19 | Gerenciar curso | T23.2, T24.4 | /cursos | curso |
| RF20 | Relacionar curso x campus | T23.2 | PUT /campus/:id/cursos | campus_curso |
| RF21 | Gerenciar campus | T15, T23.3 | /campus | campus, endereco |
| RF22 | Relacionar campus x universidade | T15, T23.3 | POST /universidades/:id/campus | campus |
| RF23 | Aprovar universidade | T24.3 | POST /universidades/:id/aprovar | universidade, notificacao |
| RF24 | Salvar universidade (faculdades salvas) | T03, T02, T19 | /favoritos/universidades | universidade_salva |
| RF25 | Página de detalhamento do programa | T08 | GET /programas/:id | programa, programa_evento, universidade_programa |

---

## 10. Requisitos não funcionais: como cada um é atendido

| RNF | Implementação |
| --- | --- |
| RNF01, RNF03, RNF04 (navegação, interface e informações) | Design system, navegação com no máximo 3 níveis, breadcrumbs nos painéis, estados vazios com orientação |
| RNF02 (senha criptografada) | bcrypt custo 12, nunca retornar `senha_hash` |
| RNF05 (mínimo de dados) | Pesquisa funciona sem filtros; barra única na home |
| RNF06 (links visíveis) | Botões "Acessar página" e "Simulados" em destaque no detalhe |
| RNF07 (confidencialidade) | Ownership middleware, e-mails ocultos em conteúdo público, HTTPS em produção, CORS restrito; sem CPF de alunos, sem IP em métricas, `visita_pagina` agregável apenas por tipo |
| RNF08 (responsivo) | Breakpoints do design system, testes em 360, 768, 1024, 1440 px |
| RNF09 (log resiliente) | `log_auditoria` na mesma transação; MySQL com InnoDB e `innodb_flush_log_at_trx_commit=1` |
| RNF10 (escala) | API stateless, pool de conexões, paginação obrigatória, índices |
| RNF11 (< 5 s) | Índices, cache das médias, `EXPLAIN` nas queries de pesquisa, imagens otimizadas |
| RNF12 (stack) | Node/Express + Flutter + MySQL |

---

## 11. Plano de desenvolvimento em fases

Cada fase gera um PR revisado. Critério de conclusão entre parênteses.

**Fase 0. Fundação (1 semana)**
Monorepo, Docker Compose, Prisma schema com todas as tabelas da seção 4, migrations, seed, Express com middlewares, Swagger, CI com lint e testes. Flutter com tema do design system, router, layouts, componentes base. (`docker compose up` sobe API em `/docs` e app mostra home com dados do seed.)

**Fase 1. Autenticação e perfis (RF05, RF06, RF07, RF09 parcial)**
Register aluno, login, Google, refresh, logout, forgot/reset, alterar senha, excluir conta. Telas T09, T10, T11, T16, T21, T22, T25, T26. (Testes de integração de todos os endpoints de auth.)

**Fase 2. Catálogo público (RF03, RF04)**
Endpoints GET de universidades, campus, cursos, programas. Telas T01 a T08. Registro de visitas. (Lighthouse acessibilidade > 90, pesquisa responde < 1 s com seed.)

**Fase 3. Cadastro e painel da universidade (RF18, RF19, RF20, RF21, RF22, RF12, RF13, RF17, RF11 institucional)**
Register universidade em 3 passos (T12 a T15), painel T23 completo, ownership. (Universidade consegue cadastrar-se e gerenciar tudo da sua instituição; outra universidade recebe 403.)

**Fase 4. Interação (RF01, RF08, RF14, RF15)**
Avaliações, sugestões, notificações, favoritos, pesquisas salvas. Telas T03a, T18, T19, T20, T27. (Média recalcula corretamente com testes de concorrência; notificações chegam aos admins.)

**Fase 5. Administração (RF23, RF09, RF10, RF11, RF17, RF16, RF02)**
Painel T24 completo, aprovação com e-mail, CRUDs globais, dashboard e relatórios CSV/PDF. (Fluxo completo: universidade se cadastra > admin aprova > aparece na pesquisa > aluno avalia > relatório exportado.)

**Fase 6. Qualidade e implantação**
Testes E2E do fluxo principal, revisão de RNFs, README com instruções da seção 5 do TG (`npm install`, `flutter pub get`, `npm start`, `flutter run`), backup automatizado (mysqldump agendado) e logs (RNF09, seção Implantação do TG).

---

## 12. Divergências encontradas no TG e decisões tomadas

Registrar aqui para alinhar com a orientadora antes da versão final do texto. Os itens 3, 4 e 10 se referiam à versão anterior do TG e foram resolvidos no documento final.

1. Quadro 6 (RF04) coloca "usuário logado" como pré-condição, mas o ator é Visitante e as telas de pesquisa são públicas. Decisão: pesquisa pública.
2. Quadro 10 (RF07) coloca "usuário logado" como pré-condição para recuperar senha. Faz sentido "possuir cadastro". Decisão: público.
3. Quadro 27 está intitulado "Relacionar campus e Universidade", mas descreve RF23 Aprovar Universidade. Ajustar o título no TG.
4. Quadro 3 está intitulado "Gerenciar Anúncio", mas descreve o Simulado Anterior (no documento final, parte do RF03). Ajustar o título.
5. Modelo lógico: `CURSO` com `idCampus` e `idUniversidade`. Decisão: `curso` por universidade e `campus_curso` N:N para atender RF20.
6. Modelo lógico não contém avaliação, sugestão, notificação, faculdades salvas, pesquisas salvas nem endereço da universidade, embora RF01, RF08, RF14, RF15 e as Figuras 25/26 exijam. Decisão: tabelas complementares da seção 4.3. Sugere-se atualizar as Figuras 8 e 9 do TG.
7. Modelo lógico: `telefoneCelular NUMERIC(12)` e `telefoneFixo VARCHAR(12)`. Decisão: ambos `VARCHAR(15)` para aceitar máscara e DDI.
8. Modelo lógico: `ENDERECO.idCampus VARCHAR(100)`. Decisão: FK fica em `campus.id_endereco` (1:1), evitando tipo inconsistente.
9. Figura 34 mostra 7 abas no painel admin, sem "Programas de Entrada", embora exista RF17. Decisão: incluir a aba.
10. RNF numerados fora de sequência na versão anterior do TG. No documento final vão de RNF01 a RNF12, em sequência.
11. Rodapé das figuras com "© 2024". Atualizar para 2026.
12. Protótipo traz seções "Cronograma" e "Datas Importantes" para programas, que não estão no TG. Decisão: incluir via `programa_evento`, pois enriquece o RF10/RF11/RF17 sem alterar o escopo.

