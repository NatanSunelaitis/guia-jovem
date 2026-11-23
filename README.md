# Guia Jovem

**Seu guia completo para financiamento estudantil, ingresso universitário e bolsas de estudo.**

## Sobre o projeto

O Guia Jovem é uma plataforma web que centraliza, em um só lugar, informações sobre programas de financiamento estudantil (FIES), bolsas de estudo (ProUni e bolsas institucionais), programas de entrada (ENEM, SiSU, vestibulares) e universidades, com seus campi e cursos.

O produto é voltado principalmente a estudantes de ensino médio de escolas públicas, oferecendo um catálogo público com pesquisa dinâmica por filtros, relatório da pesquisa em CSV e PDF, avaliação de universidades, área de sugestões e painéis de administração para universidades e para a equipe do Guia Jovem.

Este projeto nasce do Trabalho de Graduação **"Guia Jovem: Seu Guia Completo para Financiamento Estudantil, Ingresso Universitário e Bolsas de Estudos"**. A especificação técnica está em [docs/ESPECIFICACAO.md](docs/ESPECIFICACAO.md) e as decisões tomadas durante o desenvolvimento, em [docs/DECISOES.md](docs/DECISOES.md).

## Perfis de usuário

| Perfil | Código `tipo_usuario` | Descrição | Acesso |
| --- | --- | --- | --- |
| Visitante | (não autenticado) | Qualquer pessoa navegando | Home, pesquisa, detalhamento, relatório da pesquisa, login, cadastro, recuperação de senha |
| Aluno | `A` | Estudante cadastrado | Tudo do Visitante, além de avaliar e salvar universidades, salvar pesquisas, enviar sugestões, notificações e perfil |
| Universidade | `U` | Representante de uma instituição | Painel da universidade (instituição, campi, cursos e ofertas, programas aceitos, bolsas institucionais, sugestões e avaliações recebidas e conta). Só aparece publicamente depois da aprovação |
| Administrador | `D` | Equipe Guia Jovem | Painel de administração: dashboard, usuários, aprovação de universidades, cursos, programas, sugestões e a própria conta |

## Tecnologias

| Camada | Tecnologia | Observação |
| --- | --- | --- |
| Apresentação | Flutter (Dart) 3.13, alvo Web | Flutter Web responsivo |
| Negócio | Node.js 20 + Express | API REST em JSON, documentada em OpenAPI (`/docs`) |
| Dados | MySQL 8 | Prisma ORM, migrations versionadas |
| Autenticação | JWT (access e refresh token) e login com Google | Senhas com bcrypt |
| E-mail | Nodemailer com SMTP configurável | Recuperação de senha e aprovação de universidade |
| Testes | Jest + Supertest na API, flutter_test no app e conferência de ponta a ponta contra MySQL real | Todos rodam na CI (GitHub Actions) |
| Infra local | Docker Compose (MySQL e API) ou MySQL 8 instalado | |

## Estrutura do monorepo

```
guia-jovem/
├── docs/                       especificação, design system, decisões e protótipo
├── api/                        Node.js + Express + Prisma
│   ├── prisma/                 schema, migrations, seed e dados de demonstração (prisma/demo)
│   ├── scripts/                criação do banco, conferência de ponta a ponta e backup
│   └── src/                    módulos da API (rotas, schemas Zod, services, repositories)
├── app/                        Flutter Web
├── docker-compose.yml
└── README.md
```

## Rodando tudo do zero

### Pré-requisitos

- Node.js 20 e npm
- Flutter 3.13 (canal stable) e o Google Chrome
- MySQL 8: o Docker Compose deste repositório ou um MySQL 8 instalado (no Windows, o serviço **MySQL80**)

### 1. Banco de dados

**Com Docker Compose**, que sobe o MySQL e a API já com as migrations e o seed:

```bash
docker compose up
```

**Com MySQL local**: confirme que o serviço está rodando (`Get-Service MySQL80` no PowerShell) e siga para o passo 2, que cria o banco.

### 2. API

```bash
cd api
cp .env.example .env        # no PowerShell: Copy-Item .env.example .env
```

Edite o `api/.env`: em `DATABASE_URL`, o usuário e a senha do seu MySQL (ex.: `mysql://root:SUA_SENHA@127.0.0.1:3306/guiajovem`); troque `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` e `ADMIN_SENHA`. O `api/.env` nunca é versionado.

```bash
npm install
npm run db:local            # cria o banco se faltar, aplica as migrations e roda o seed
npm start
```

A API fica em `http://localhost:3000`, com a documentação Swagger em `http://localhost:3000/docs` e a verificação em `http://localhost:3000/api/v1/health`. O seed cria o administrador do `.env` (`ADMIN_EMAIL` e `ADMIN_SENHA`), os programas de exemplo e três universidades. Depois de um `git pull` com migration nova, rode `npx prisma migrate deploy` (ou `npm run db:local` de novo): nenhum dos dois apaga dados.

Sem `SMTP_HOST`, a API não envia e-mail: fora de produção, o conteúdo (com o link de recuperação de senha) aparece no terminal da API.

O CORS aceita só as origens de `CORS_ORIGENS` (separadas por vírgula). Vazia, vale o `APP_URL` e, fora de produção, também `http://localhost:8080` e `http://127.0.0.1:8080`. Em produção, defina a lista com o endereço do site (e o do Netlify, se for usado). Se o app rodar em outra porta no computador, inclua a origem dele na lista.

### 3. App

```bash
cd app
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

A porta 8080 é a do `APP_URL` do `api/.env`, para os links de recuperação de senha abrirem o app. Variáveis de compilação (`--dart-define`):

| Variável | Para quê | Padrão |
| --- | --- | --- |
| `API_BASE_URL` | Endereço da API, com o prefixo `/api/v1` | `http://localhost:3000/api/v1` |
| `GOOGLE_CLIENT_ID` | Liga o botão "Entrar com Google" (seção [Login com Google](#login-com-google-rf05)) | vazio: o botão não aparece |

O build de produção fica em `app/build/web`:

```bash
flutter build web --dart-define=API_BASE_URL=https://api.exemplo.com.br/api/v1 --dart-define=GOOGLE_CLIENT_ID=...
```

Como os valores entram na compilação, mudar a API ou o client do Google exige rodar ou gerar o build de novo.

### 4. Dados de demonstração

`npm run db:demo` grava os dados da apresentação num banco indicado por `DEMO_DATABASE_URL` (no `api/.env` ou no terminal), separado do seed. O banco é criado se não existir e recebe as migrations.

```bash
cd api
# PowerShell: $env:DEMO_DATABASE_URL="mysql://root:SUA_SENHA@127.0.0.1:3306/guiajovem_demo"
export DEMO_DATABASE_URL="mysql://root:SUA_SENHA@127.0.0.1:3306/guiajovem_demo"
npm run db:demo
```

Se o banco já tiver qualquer usuário ou universidade, o comando para sem alterar nada. Para apagar tudo e gravar só os dados de demonstração, confirme com `npm run db:demo -- --substituir`. Para usar esse banco, aponte o `DATABASE_URL` do `api/.env` para ele e suba a API.

Conteúdo: 6 universidades aprovadas da região de Sorocaba (fictícias), com campi, cursos, ofertas com turno e vagas, programas aceitos, links e avaliações; 1 universidade pendente e 1 reprovada com motivo, para demonstrar a aprovação; os programas de entrada, financiamento e bolsa com datas importantes; 2 bolsas institucionais; visitas e logins dos últimos 30 dias para o dashboard. Sugestões, pesquisas salvas e faculdades salvas ficam vazias, para serem criadas ao vivo. **Todos os dados factuais (datas, vagas, notas, endereços, telefones, CNPJs e links) são ilustrativos** e ficam em `api/prisma/demo/dados.js`; os sites, as páginas de simulados e os e-mails das universidades e dos campi usam o domínio reservado `example.com`.

Contas (senha `Demo@2026` em todas, ou o valor de `DEMO_SENHA`):

| Perfil | E-mail | Para demonstrar |
| --- | --- | --- |
| Administrador | `admin@demo.guiajovem.com.br` | Dashboard, aprovação da pendente, usuários, programas, sugestões |
| Aluno | `beatriz@demo.guiajovem.com.br` | Ainda não avaliou UESP, UniTatuí e Faculdade Municipal de Salto |
| Aluno | `lucas@demo.guiajovem.com.br` | Ainda não avaliou Faculdade Votorantim de Tecnologia, FEITU e Faculdade Municipal de Salto |
| Universidade aprovada | `univale@example.com` | Painel completo, com bolsa institucional |
| Universidades aprovadas | `uesp@`, `fvt@`, `feitu@`, `unitatui@` e `fams@example.com` | Demais painéis |
| Universidade pendente | `fcsboituva@example.com` | Painel em análise; aparece para o administrador aprovar |
| Universidade reprovada | `isepiedade@example.com` | Motivo da reprovação e "Reenviar para análise" |

#### Rodar a demonstração no Windows com um comando

Com o MySQL no ar, o `guiajovem_demo` já gravado (`npm run db:demo`) e o `npm install` da API feito, na raiz do repositório:

```bat
iniciar-demo.cmd
```

O script confere se o banco de demonstração responde e tem dados, gera o build web release do app (cerca de 1 minuto) apontando para a API local, sobe a caixa de e-mails de testes (MailDev, instalado pelo `npm install` da API: SMTP local e interface web, sem Docker e sem internet), sobe a API contra o `guiajovem_demo` enviando os e-mails para essa caixa e serve o build num servidor estático. Todos ficam em segundo plano:

| O quê | Endereço |
| --- | --- |
| App | http://localhost:8080 |
| API | http://localhost:3000/api/v1 (health em `/api/v1/health`) |
| Documentação da API | http://localhost:3000/docs |
| Caixa de e-mails de testes | http://localhost:1080 (recuperação de senha, aprovação, reprovação, inativação e reativação chegam aqui) |

O banco usado é o `DEMO_DATABASE_URL` do `api/.env` ou, sem ele, o `DATABASE_URL` com o nome trocado para `guiajovem_demo`; o banco do `DATABASE_URL` não é tocado. Os logs ficam em `.demo/`, fora do Git.

Opções: `-PortaApi 3001`, `-PortaApp 8081`, `-PortaSmtp 1026` e `-PortaEmail 1081` trocam as portas; `-SemBuild` reaproveita o `app/build/web` existente (gerado para a mesma porta da API). Se uma porta estiver ocupada, o script para e diz qual programa a usa, sem derrubar nada.

**Limite de login na demonstração.** A API conta as tentativas de login sem sucesso por IP e e-mail e bloqueia depois de `LIMITE_TENTATIVAS_LOGIN` falhas em 15 minutos (padrão 10, o valor de produção), com a mensagem "Tente novamente em N minutos". Logins certos não contam. O `iniciar-demo` sobe a API com `LIMITE_TENTATIVAS_LOGIN=500`, para ensaios, capturas e apresentações com muitos logins seguidos não esbarrarem no bloqueio; `-LimiteLogin 20` troca o valor (por exemplo, para mostrar o bloqueio). **Esse valor alto é só do ambiente de demonstração**: em produção, deixe `LIMITE_TENTATIVAS_LOGIN` em 10 (ou fora do `.env`). Reiniciar a API com o `parar-demo` e o `iniciar-demo` zera as contagens.

Para parar a API, o app e a caixa de e-mails:

```bat
parar-demo.cmd
```

### 5. Testes

```bash
cd api
npm run lint
npm test                    # testes de integração com o Prisma simulado
npm run conferencia         # ponta a ponta contra um MySQL real (abaixo)

cd ../app
flutter analyze
flutter test
flutter build web
```

`npm run conferencia` recria o banco de `CONFERENCIA_DATABASE_URL` (o nome precisa terminar em `_teste`, `_test` ou `_e2e`, porque ele é apagado a cada execução), aplica as migrations e o seed, sobe a API numa porta própria (3999) e percorre pela HTTP os fluxos do visitante, do aluno, da universidade e do administrador: pesquisa, relatório CSV e PDF, cadastro e login, avaliação, faculdades e pesquisas salvas, sugestões e notificações, aprovação e reprovação, painel da universidade, cursos de mesmo nome (agrupamento, sugestão de nomes e nomes parecidos), dashboard, recuperação e troca de senha, exclusão de conta, auditoria e registro de visitas. Termina com erro se algum ponto falhar.

```bash
CONFERENCIA_DATABASE_URL="mysql://root:SUA_SENHA@127.0.0.1:3306/guiajovem_teste" npm run conferencia
```

`src/modules/estatisticas/estatisticas.banco.test.js` também roda contra o MySQL quando `TESTE_BANCO_REAL=1`.

### Integração contínua

A cada push e pull request, o GitHub Actions roda dois jobs. **API**: lint, migrations num MySQL 8, testes, seed e a conferência de ponta a ponta num banco próprio (`guiajovem_e2e`). **App**: `flutter analyze`, `flutter test` e `flutter build web`.

## Login com Google (RF05)

O botão "Entrar com Google" usa o Google Identity Services: o Google devolve ao app um ID token (JWT), o app envia esse token a `POST /api/v1/auth/google` e a API confere a assinatura, a validade, o e-mail verificado e se o token foi emitido para o mesmo identificador de cliente (`aud`). Sem conta com aquele e-mail, a API cria uma conta de aluno. Não há client secret: só o identificador do cliente é usado, e ele não é segredo.

Sem a variável `GOOGLE_CLIENT_ID` na compilação do app, o botão não aparece e o login continua só com e-mail e senha.

**1. No Google Cloud Console** ([console.cloud.google.com](https://console.cloud.google.com)):

1. Crie um projeto (ou escolha um existente).
2. Em **APIs e serviços > Tela de consentimento OAuth** (no console novo, **Google Auth Platform**), configure o app: tipo de usuário **Externo**, nome "Guia Jovem", e-mail de suporte e e-mail de contato. Os escopos básicos (`openid`, `email`, `profile`) bastam e não exigem verificação do Google.
3. Enquanto o app estiver no status **Em teste**, só as contas listadas em **Usuários de teste** conseguem entrar. Para a apresentação, adicione as contas que serão usadas ou publique o app (**Publicar app**), o que não pede revisão para os escopos básicos.
4. Em **APIs e serviços > Credenciais > Criar credenciais > ID do cliente OAuth**, escolha o tipo **Aplicativo da Web**.
5. Em **Origens JavaScript autorizadas**, cadastre o endereço exato de onde o app é aberto (protocolo, domínio e porta, sem barra no fim):
   - ambiente local: `http://localhost:8080` e `http://localhost` (o Google pede as duas para testes locais);
   - produção: o endereço do site, por exemplo `https://guiajovem.com.br`, e o endereço do Netlify (`https://<seu-site>.netlify.app`), se ele também for usado.
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

Problemas comuns: "origin_mismatch" ou o botão sumindo depois de carregar indicam que o endereço aberto no navegador não está nas origens autorizadas; 401 "Token do Google inválido ou expirado" indica que o `GOOGLE_CLIENT_ID` da API é diferente do usado no app; contas de universidade e de administrador não entram pelo Google (403) e usam e-mail e senha.

## Backup do banco

`npm run backup` (na pasta `api/`) gera um `mysqldump` comprimido com o nome datado (`guiajovem-<banco>-AAAA-MM-DD_HHMMSS.sql.gz`) em `api/backups/` (ignorada pelo Git) e apaga os backups locais mais antigos que a retenção. O `mysqldump` precisa estar no PATH ou em `MYSQLDUMP_PATH` (no Windows, `C:/Program Files/MySQL/MySQL Server 8.0/bin/mysqldump.exe`; no Ubuntu, pacote `mysql-client`). A senha vai num arquivo de opções temporário, fora da linha de comando.

| Variável | Padrão | Uso |
| --- | --- | --- |
| `BACKUP_DATABASE_URL` | `DATABASE_URL` | Banco a copiar |
| `BACKUP_DIR` | `api/backups` | Pasta dos arquivos |
| `BACKUP_RETENCAO_DIAS` | `7` | Dias que um backup local é mantido |
| `MYSQLDUMP_PATH` | `mysqldump` | Caminho do executável |
| `BACKUP_S3_ENDPOINT`, `BACKUP_S3_BUCKET`, `BACKUP_S3_ACCESS_KEY_ID`, `BACKUP_S3_SECRET_ACCESS_KEY` | vazias | Envio opcional a um armazenamento compatível com S3, como o Cloudflare R2 (endpoint `https://<id-da-conta>.r2.cloudflarestorage.com` e um token de API do R2 com permissão de escrita no bucket). Sem as quatro, o backup fica só no arquivo local; com só parte delas, o comando para com erro |
| `BACKUP_S3_REGIAO`, `BACKUP_S3_PREFIXO` | `auto`, `guiajovem/` | Região da assinatura e pasta dentro do bucket |

**Agendar todo dia às 3h**

- Linux (VPS), com `crontab -e`:

  ```
  0 3 * * * cd /opt/guia-jovem/api && /usr/bin/node scripts/backup/backup.js >> /var/log/guiajovem-backup.log 2>&1
  ```

  Com o MySQL no Docker Compose, a porta 3306 publicada no host permite rodar o backup do próprio host, com o `mysql-client` instalado e o `DATABASE_URL` apontando para `127.0.0.1`.

- Windows, no PowerShell como administrador (ajuste o caminho):

  ```powershell
  schtasks /Create /TN "Guia Jovem backup" /SC DAILY /ST 03:00 /TR "cmd /c cd /d C:\guia-jovem\api && npm run backup >> backups\backup.log 2>&1"
  ```

**Restaurar** um backup num banco vazio (o arquivo não cria o banco):

```bash
mysql -u root -p -e "CREATE DATABASE guiajovem_restaurado CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
gzip -dc api/backups/guiajovem-guiajovem-2026-11-18_030000.sql.gz | mysql -u root -p guiajovem_restaurado
```

## Documentação

- [docs/ESPECIFICACAO.md](docs/ESPECIFICACAO.md): especificação técnica, fases de desenvolvimento e contrato da API.
- [docs/DESIGN-SYSTEM.md](docs/DESIGN-SYSTEM.md): tokens visuais e componentes do design system em Flutter.
- [docs/DECISOES.md](docs/DECISOES.md): divergências, decisões e pendências registradas durante o desenvolvimento.
- `http://localhost:3000/docs`: documentação OpenAPI da API.

## Autores

- Mayara Sabrina dos Santos
- Natan Pierre de Almeida Sunelaitis

**Instituição:** FATEC Sorocaba, Análise e Desenvolvimento de Sistemas (ADS), 2026.

> Este repositório substitui o `GuiaJovem-Front-end`, reestruturado como monorepo (`api/` + `app/`).
