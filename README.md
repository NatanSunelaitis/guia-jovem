# Guia Jovem

**Seu guia completo para financiamento estudantil, ingresso universitário e bolsas de estudo.**

## Sobre o projeto

O Guia Jovem é uma plataforma web que centraliza, em um só lugar, informações sobre programas de financiamento estudantil (FIES), bolsas de estudo (ProUni e bolsas institucionais), programas de entrada (ENEM, SiSU, vestibulares) e universidades, com seus campus e cursos.

O produto é voltado principalmente a estudantes de ensino médio de escolas públicas, oferecendo um catálogo público com pesquisa dinâmica por filtros, avaliação de universidades, área de sugestões e painéis de administração para universidades e para a equipe do Guia Jovem.

Este projeto nasce do Trabalho de Graduação **"Guia Jovem: Seu Guia Completo para Financiamento Estudantil, Ingresso Universitário e Bolsas de Estudos"**. A especificação completa do que será construído está em [docs/ESPECIFICACAO.md](docs/ESPECIFICACAO.md).

## Perfis de usuário

| Perfil | Código `tipo_usuario` | Descrição | Acesso |
| --- | --- | --- | --- |
| Visitante | (não autenticado) | Qualquer pessoa navegando | Home, pesquisa, detalhamento, login, cadastro, recuperação de senha |
| Aluno | `A` | Estudante cadastrado | Tudo do Visitante, além de avaliar universidade, enviar sugestão, salvar faculdades, salvar pesquisas, perfil, alterar senha, excluir conta |
| Universidade | `U` | Representante de uma instituição | Tudo do Aluno (exceto avaliar), além do Painel de Administração da Universidade (somente da sua instituição). Só aparece publicamente após aprovação |
| Administrador | `D` | Equipe Guia Jovem | Painel de Administração geral: CRUD de tudo, aprovação de universidades, avaliação de sugestões, estatísticas |

## Tecnologias

| Camada | Tecnologia | Observação |
| --- | --- | --- |
| Apresentação | Flutter (Dart), alvo Web principal, com Android/iOS como bônus | Flutter Web responsivo |
| Negócio | Node.js + Express.js | API REST em JSON, padrão MVC |
| Dados | MySQL 8 | Acesso via Prisma ORM, migrations versionadas |
| Autenticação | JWT (access token + refresh token) e OAuth 2.0 Google | Senhas com bcrypt |
| E-mail | Nodemailer com SMTP configurável | Recuperação de senha e aprovação de universidade |
| Testes | Backend: Jest + Supertest. Frontend: flutter_test + integration_test | Cobertura mínima nas regras de negócio |
| Infra local | Docker Compose (mysql + api) | `docker compose up` sobe o ambiente |

## Estrutura do monorepo

```
guia-jovem/
├── docs/
│   ├── ESPECIFICACAO.md            (o que construir, fases, contrato da API, telas)
│   ├── DESIGN-SYSTEM.md            (tokens e componentes do Flutter)
│   ├── DECISOES.md                 (divergências e decisões registradas durante o desenvolvimento)
│   └── prototipo/                  (exportação HTML do protótipo aprovado, por grupo de telas)
├── api/                            (Node.js + Express)
├── app/                            (Flutter)
├── docker-compose.yml
└── README.md
```

## Instalação e execução

### Pré-requisitos

- Docker e Docker Compose
- Node.js 18+ e npm
- Flutter SDK (canal stable)

### Subindo a API com Docker Compose

O `docker-compose.yml` sobe o banco de dados MySQL 8 e a API Node.js, já com as migrations e o seed aplicados.

```bash
docker compose up
```

A API fica disponível em `http://localhost:3000` e a documentação interativa (Swagger) em `http://localhost:3000/docs`.

### Execução local sem Docker

Alternativa ao Docker Compose para quem já tem um MySQL 8 instalado no Windows (ex.: serviço **MySQL80**, porta 3306).

1. Confirme que o serviço do MySQL está rodando (PowerShell):

   ```powershell
   Get-Service MySQL80
   ```

2. Copie `api/.env.example` para `api/.env` e preencha `DATABASE_URL` com o usuário/senha do seu MySQL local (ex.: `mysql://root:SUA_SENHA@127.0.0.1:3306/guiajovem`). O arquivo `api/.env` nunca é versionado (está no `.gitignore`).

3. Instale as dependências e prepare o banco (cria o banco `guiajovem` se não existir, aplica as migrations e roda o seed):

   ```powershell
   cd api
   npm install
   npm run db:local
   ```

4. Suba a API:

   ```powershell
   npm start
   ```

5. Acesse `http://localhost:3000/docs` para conferir a documentação Swagger.

`npm run db:local` também serve para reaplicar migrations/seed depois de atualizar o código (`git pull`), sem precisar do Docker.

### Rodando o app Flutter

```bash
cd app
flutter pub get
flutter run -d chrome
```

#### Endereço da API (`API_BASE_URL`)

O app lê o endereço da API na compilação, pela variável `API_BASE_URL` (`--dart-define`). Ela deve incluir o prefixo `/api/v1`. Sem a variável, o padrão é `http://localhost:3000/api/v1`, que é a API local subida por qualquer um dos dois caminhos acima.

Para rodar o app apontando para a API local:

1. Suba a API (`docker compose up` ou `npm start` em `api/`) e confira `http://localhost:3000/api/v1/health`.
2. Rode o app na porta 8080, a mesma do `APP_URL` do `api/.env`, para os links de recuperação de senha enviados por e-mail abrirem o app:

   ```bash
   cd app
   flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://localhost:3000/api/v1
   ```

Para apontar para outra API (ex.: um servidor de testes), troque só o valor:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://api.exemplo.com.br/api/v1
```

O mesmo vale para o build web, que fica em `app/build/web`:

```bash
flutter build web --dart-define=API_BASE_URL=https://api.exemplo.com.br/api/v1
```

Como o valor entra na compilação, mudar a API exige rodar ou gerar o build de novo.

### Login com Google (RF05)

O botão "Entrar com Google" usa o Google Identity Services: o Google devolve ao app um ID token (JWT), o app envia esse token a `POST /api/v1/auth/google` e a API confere a assinatura, a validade, o e-mail verificado e se o token foi emitido para o mesmo identificador de cliente (`aud`). Sem conta com aquele e-mail, a API cria uma conta de aluno. Não há client secret: só o identificador do cliente é usado, e ele não é segredo.

Sem a variável `GOOGLE_CLIENT_ID` na compilação do app, o botão não aparece e o login continua só com e-mail e senha.

**1. No Google Cloud Console** ([console.cloud.google.com](https://console.cloud.google.com)):

1. Crie um projeto (ou escolha um existente).
2. Em **APIs e serviços > Tela de consentimento OAuth** (no console novo, **Google Auth Platform**), configure o app: tipo de usuário **Externo**, nome "Guia Jovem", e-mail de suporte e e-mail de contato. Os escopos básicos (`openid`, `email`, `profile`) bastam e não exigem verificação do Google.
3. Enquanto o app estiver no status **Em teste**, só as contas listadas em **Usuários de teste** conseguem entrar. Para a apresentação, adicione as contas que serão usadas ou publique o app (**Publicar app**), o que não pede revisão para os escopos básicos.
4. Em **APIs e serviços > Credenciais > Criar credenciais > ID do cliente OAuth**, escolha o tipo **Aplicativo da Web**.
5. Em **Origens JavaScript autorizadas**, cadastre o endereço exato de onde o app é aberto (protocolo, domínio e porta, sem barra no fim):
   - ambiente local: `http://localhost:8080` e `http://localhost` (o Google pede as duas para testes locais);
   - produção: o endereço do site, por exemplo `https://guiajovem.com.br` e o endereço do Netlify (`https://<seu-site>.netlify.app`), se ele também for usado.
6. **URIs de redirecionamento autorizados** podem ficar vazios: o botão abre um pop-up e devolve o token direto ao app.
7. Salve e copie o **ID do cliente** (termina em `.apps.googleusercontent.com`). As origens novas podem levar alguns minutos para valer.

**2. Na API**, em `api/.env` (ou no `environment` do serviço `api` no `docker-compose.yml`):

```
GOOGLE_CLIENT_ID=1234567890-abc.apps.googleusercontent.com
```

**3. No app**, o mesmo valor na compilação, junto com o endereço da API. A porta precisa ser uma das origens autorizadas:

```bash
flutter run -d chrome --web-port 8080 \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1 \
  --dart-define=GOOGLE_CLIENT_ID=1234567890-abc.apps.googleusercontent.com

flutter build web \
  --dart-define=API_BASE_URL=https://api.guiajovem.com.br/api/v1 \
  --dart-define=GOOGLE_CLIENT_ID=1234567890-abc.apps.googleusercontent.com
```

Problemas comuns: "origin_mismatch" ou o botão some depois de carregar indicam que o endereço aberto no navegador não está nas origens autorizadas; 401 "Token do Google inválido ou expirado" indica que o `GOOGLE_CLIENT_ID` da API é diferente do usado no app; contas de universidade e de administrador não entram pelo Google (403) e usam e-mail e senha.

## Documentação

- [docs/ESPECIFICACAO.md](docs/ESPECIFICACAO.md): especificação técnica completa, fases de desenvolvimento e contrato da API.
- [docs/DESIGN-SYSTEM.md](docs/DESIGN-SYSTEM.md): tokens visuais e componentes do design system em Flutter.

## Autores

- Mayara Sabrina dos Santos
- Natan Pierre de Almeida Sunelaitis

**Instituição:** FATEC Sorocaba, Análise e Desenvolvimento de Sistemas (ADS), 2026.

> Este repositório substitui o `GuiaJovem-Front-end`, reestruturado como monorepo (`api/` + `app/`).
