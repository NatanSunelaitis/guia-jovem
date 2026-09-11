# Decisões e divergências

Registro de decisões tomadas durante o desenvolvimento que divergem ou complementam `ESPECIFICACAO.md`. Uma entrada por decisão, mais recente no topo.

| Data | Área | Decisão | Motivo | Impacto no TG |
| --- | --- | --- | --- | --- |
| 2026-09-10 | Backend (hash de senha) | Usar o pacote `bcryptjs` em vez de `bcrypt` (RNF02) | `bcrypt` é um binário nativo (node-gyp) e falha ao instalar em ambientes sem toolchain de compilação C++; `bcryptjs` é uma implementação pura em JavaScript, mesmo algoritmo e API compatível (`hash`/`compare`), sem dependência nativa | Nenhum: RNF02 exige o algoritmo bcrypt com custo configurável, não um pacote específico |
| 2026-09-10 | Banco de dados (migration inicial) | Ações referenciais (`ON DELETE` / `ON UPDATE`) de algumas FKs seguem o padrão do Prisma em vez do DDL literal da seção 4.3: `log_auditoria.id_usuario` usa `ON DELETE SET NULL` (o DDL não define ação, o que resultaria em `RESTRICT` e bloquearia a exclusão física de usuário com log); todas as FKs receberam `ON UPDATE CASCADE` | O DDL de referência não define `ON DELETE`/`ON UPDATE` explícitos para diversas FKs. O padrão do Prisma para FKs opcionais é `SET NULL`, o que é compatível com a regra de exclusão física de usuário (RNF17) sem quebrar a auditoria | Sugere-se registrar `ON DELETE SET NULL` explicitamente na FK de `log_auditoria.id_usuario` no DDL do TG |

---

## Pendências

| Data | Área | Pendência |
| --- | --- | --- |
| 2026-09-11 | Infra (Fase 0) | Validação local do `docker compose up` com Docker Desktop ainda não foi executada (Docker não está disponível no ambiente onde a Fase 0 foi implementada). O ambiente (migrations + seed) foi validado apenas via CI, que roda `prisma migrate deploy` e o seed contra um serviço MySQL 8 real no GitHub Actions. Falta confirmar localmente que `docker compose up` sobe a API com o seed carregado. |
