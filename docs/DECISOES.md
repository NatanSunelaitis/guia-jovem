# Decisões e divergências

Registro de decisões tomadas durante o desenvolvimento que divergem ou complementam `ESPECIFICACAO.md`. Uma entrada por decisão, mais recente no topo.

| Data | Área | Decisão | Motivo | Impacto no TG |
| --- | --- | --- | --- | --- |
| 2026-09-11 | Escopo (Fase 1) | `POST /auth/register/universidade` (seção 5.1) não foi implementado nesta fase, mesmo estando na tabela de endpoints de Auth | A seção 11 (plano de fases) reserva explicitamente o cadastro de universidade para a Fase 3, junto com campus/cursos/programas, que ainda não existem como módulos. Implementá-lo agora pularia fase (regra do CLAUDE.md) | Nenhum: mantém a ordem de fases já definida na seção 11 |
| 2026-09-11 | Banco de dados (Fase 1) | `universidade.id_usuario` deixou de ser `NOT NULL` e passou a `ON DELETE SET NULL` | RNF17 exige exclusão física do usuário; a regra de negócio da seção 5.2 diz que, ao excluir um usuário tipo `U`, "a universidade vai para status=I" (ou seja, o registro da universidade permanece). Com `id_usuario NOT NULL` e sem ação de delete, a FK bloquearia essa exclusão (`RESTRICT`). Tornar a coluna anulável com `SET NULL` permite excluir o usuário e manter a universidade inativada | Sugere-se atualizar o DDL do TG: `UNIVERSIDADE.idUsuario` deveria ser opcional |
| 2026-09-11 | Backend (RF11) | `POST /usuarios` e `PATCH /usuarios/:id` não aceitam `tipoUsuario = 'U'` | Um usuário tipo `U` só faz sentido vinculado a uma universidade (`universidade.id_usuario`), criada apenas pelo fluxo de `/auth/register/universidade` (Fase 3). Permitir criar/converter para `U` por esses endpoints deixaria um usuário `U` órfão, sem universidade | Nenhum: RF11 não detalha esse caso; ficará documentado até a Fase 3 existir |
| 2026-09-11 | Testes (Fase 1) | Os testes de integração de `auth` e `usuarios` mockam o Prisma Client em vez de rodar contra um MySQL real | Não há Docker nem credenciais de um MySQL local disponíveis no ambiente onde o backend foi desenvolvido (ver pendência abaixo). Os testes cobrem rotas, validação (Zod) e regras de negócio; o schema/migrations continuam validados à parte pelo CI, que roda `prisma migrate deploy` contra um MySQL 8 real | Nenhum: é uma decisão de ambiente de desenvolvimento, não altera o contrato da API |
| 2026-09-10 | Backend (hash de senha) | Usar o pacote `bcryptjs` em vez de `bcrypt` (RNF02) | `bcrypt` é um binário nativo (node-gyp) e falha ao instalar em ambientes sem toolchain de compilação C++; `bcryptjs` é uma implementação pura em JavaScript, mesmo algoritmo e API compatível (`hash`/`compare`), sem dependência nativa | Nenhum: RNF02 exige o algoritmo bcrypt com custo configurável, não um pacote específico |
| 2026-09-10 | Banco de dados (migration inicial) | Ações referenciais (`ON DELETE` / `ON UPDATE`) de algumas FKs seguem o padrão do Prisma em vez do DDL literal da seção 4.3: `log_auditoria.id_usuario` usa `ON DELETE SET NULL` (o DDL não define ação, o que resultaria em `RESTRICT` e bloquearia a exclusão física de usuário com log); todas as FKs receberam `ON UPDATE CASCADE` | O DDL de referência não define `ON DELETE`/`ON UPDATE` explícitos para diversas FKs. O padrão do Prisma para FKs opcionais é `SET NULL`, o que é compatível com a regra de exclusão física de usuário (RNF17) sem quebrar a auditoria | Sugere-se registrar `ON DELETE SET NULL` explicitamente na FK de `log_auditoria.id_usuario` no DDL do TG |

---

## Pendências

| Data | Área | Pendência |
| --- | --- | --- |
| 2026-09-11 | Infra (Fase 0) | Validação local do `docker compose up` com Docker Desktop ainda não foi executada (Docker não está disponível no ambiente onde a Fase 0 foi implementada). O ambiente (migrations + seed) foi validado apenas via CI, que roda `prisma migrate deploy` e o seed contra um serviço MySQL 8 real no GitHub Actions. Falta confirmar localmente que `docker compose up` sobe a API com o seed carregado. |
