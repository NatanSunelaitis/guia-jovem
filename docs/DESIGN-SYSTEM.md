# Guia Jovem Design System (GJDS) v1.2

> Fonte única de verdade para a identidade visual e os componentes da plataforma Guia Jovem.
> Serve a três consumidores: o protótipo de alta fidelidade, a implementação em Flutter e a documentação do TG (seção 4.5, Interfaces com o usuário).
> Os tokens abaixo foram extraídos do protótipo feito no Stitch (Material 3, paleta azul) e consolidados com as telas do TG.

---

## 1. Princípios

1. **Clareza antes de tudo.** O público são estudantes de ensino médio, muitos com pouca familiaridade digital e afetados por analfabetismo funcional (Introdução do TG). Textos curtos, hierarquia óbvia, uma ação principal por tela.
2. **Um sistema, três audiências.** Aluno, Universidade e Administrador compartilham os mesmos tokens e componentes. O que muda é o layout (público x painel), nunca a linguagem visual.
3. **Cor com significado.** Azul é a marca e a ação. Vermelho é só perigo (excluir, sair, erro). Verde só sucesso. Amarelo/âmbar só atenção e nota (estrelas). Nada de cor decorativa aleatória.
4. **Acessível por padrão.** Contraste AA, alvo de toque 44 px, foco visível, tudo operável por teclado.
5. **Consistência acima de novidade.** Se um padrão já existe neste documento, reutilizar. Criar componente novo só depois de registrá-lo aqui.

---

## 2. Fundamentos (tokens)

Nomenclatura: `gj.<categoria>.<nome>`. Em Flutter viram constantes em `lib/core/theme/`. Em CSS (protótipos) viram variáveis `--gj-*`. A coluna "Stitch" mostra a origem no protótipo.

### 2.1 Cores

#### Marca e ação
| Token | Hex | Stitch | Uso |
| --- | --- | --- | --- |
| `gj.color.primary` | `#0061A4` | `primary` | Cor de marca, textos de ênfase, ícones ativos, links, fundo do rodapé |
| `gj.color.primary.container` | `#2196F3` | `primary-container` | Botão primário, tabs ativas, barras de progresso |
| `gj.color.primary.on` | `#FFFFFF` | `on-primary` | Texto sobre primary |
| `gj.color.primary.container.on` | `#002C4F` | `on-primary-container` | Texto escuro sobre container claro (usar branco `#FFFFFF` quando o fundo for `#2196F3` sólido) |
| `gj.color.primary.fixed` | `#D1E4FF` | `primary-fixed` | Fundo de seleção, tags informativas, hover suave |
| `gj.color.primary.fixed.dim` | `#9ECAFF` | `primary-fixed-dim` | Bordas de destaque, gráficos secundários |
| `gj.color.primary.dark` | `#00497D` | `on-primary-fixed-variant` | Hover/pressed do botão primário, títulos sobre fundo claro azul |

#### Secundária (apoio, tipo "Bolsas")
| Token | Hex | Stitch | Uso |
| --- | --- | --- | --- |
| `gj.color.secondary` | `#005FAF` | `secondary` | Categoria Bolsas/ProUni/SiSU, ícones secundários |
| `gj.color.secondary.container` | `#54A0FE` | `secondary-container` | Progresso secundário, chips |
| `gj.color.secondary.fixed` | `#D4E3FF` | `secondary-fixed` | Fundo de chips secundários |

#### Terciária (categoria "Financiamento" e perigo)
| Token | Hex | Stitch | Uso |
| --- | --- | --- | --- |
| `gj.color.tertiary` | `#B3272A` | `tertiary` | Categoria Financiamento/FIES. Também é o vermelho da faixa DEMO |
| `gj.color.tertiary.container` | `#FA5B57` | `tertiary-container` | Destaques quentes |
| `gj.color.tertiary.fixed` | `#FFDAD7` | `tertiary-fixed` | Fundo de tag Financiamento |
| `gj.color.tertiary.dark` | `#8C1D20` | (derivado) | Hover/pressed de botões na categoria Financiamento, simétrico ao `primary.dark` |

#### Semânticas
| Token | Hex | Uso |
| --- | --- | --- |
| `gj.color.error` | `#BA1A1A` | Mensagens de erro, borda de campo inválido, botão destrutivo (Excluir conta, Sair) |
| `gj.color.error.container` | `#FFDAD6` | Fundo de alerta de erro |
| `gj.color.error.on.container` | `#93000A` | Texto do alerta de erro |
| `gj.color.success` | `#1B7F3B` | Aprovado, publicado, sucesso |
| `gj.color.success.container` | `#D8F3DC` | Fundo de tag Aprovada |
| `gj.color.warning` | `#B26A00` | Em análise, pendente |
| `gj.color.warning.container` | `#FFE8B8` | Fundo de tag Em análise |
| `gj.color.rating` | `#F5A623` | Estrelas de avaliação |

#### Superfícies e texto (escala neutra do Stitch)
| Token | Hex | Stitch | Uso |
| --- | --- | --- | --- |
| `gj.color.background` | `#F9F9F9` | `background` / `surface` | Fundo da página |
| `gj.color.surface.lowest` | `#FFFFFF` | `surface-container-lowest` | Cards principais, inputs no painel, modais |
| `gj.color.surface.low` | `#F3F3F3` | `surface-container-low` | Cards secundários, fundo de inputs no site público, linhas alternadas |
| `gj.color.surface` | `#EEEEEE` | `surface-container` | Hover de card, barras de progresso (trilho) |
| `gj.color.surface.high` | `#E8E8E8` | `surface-container-high` | Divisores fortes |
| `gj.color.surface.highest` | `#E2E2E2` | `surface-container-highest` | Skeleton loading |
| `gj.color.surface.dim` | `#DADADA` | `surface-dim` | Bordas de tabela |
| `gj.color.text.primary` | `#1A1C1C` | `on-surface` | Títulos e corpo |
| `gj.color.text.secondary` | `#404752` | `on-surface-variant` | Descrições, labels, legendas |
| `gj.color.text.disabled` | `#707883` | `outline` | Placeholder, ícones inativos, texto desabilitado |
| `gj.color.border` | `#BFC7D4` | `outline-variant` | Bordas de input, cards com borda, divisores |
| `gj.color.inverse.surface` | `#2F3131` | `inverse-surface` | Fundo de tooltip e toast escuro |
| `gj.color.inverse.on` | `#F1F1F1` | `inverse-on-surface` | Texto do tooltip |

#### Cores por categoria de programa (regra fixa)
| Categoria | Cor do ícone/sigla | Fundo da tag |
| --- | --- | --- |
| Programa de Entrada (ENEM, SiSU, Vestibular) | `gj.color.primary` | `gj.color.primary.fixed` |
| Bolsa de Estudo (ProUni, institucionais) | `gj.color.secondary` | `gj.color.secondary.fixed` |
| Financiamento (FIES) | `gj.color.tertiary` | `gj.color.tertiary.fixed` |

#### Status (regra fixa)
| Status | Texto | Fundo |
| --- | --- | --- |
| Aprovada / Publicado / Ativa | `gj.color.success` | `gj.color.success.container` |
| Em análise / Pendente | `gj.color.warning` | `gj.color.warning.container` |
| Reprovada / Inativa | `gj.color.error.on.container` | `gj.color.error.container` |

Modo escuro: não faz parte da v1. O Stitch gerou classes `dark:`; ignorar.

### 2.2 Tipografia

| Família | Uso | Pesos |
| --- | --- | --- |
| **Plus Jakarta Sans** | Títulos (display, headline, título de card, logo) | 700, 800 |
| **Inter** | Corpo, labels, botões, tabelas | 400, 500, 600 |

Escala (desktop / mobile), line-height em fator:

| Token | Fonte | Tamanho | Peso | Uso |
| --- | --- | --- | --- | --- |
| `gj.type.display` | Jakarta | 48 / 36 px, lh 1.1, tracking -0.02em | 800 | Título do hero da home e de detalhe de programa |
| `gj.type.h1` | Jakarta | 36 / 28 px, lh 1.15 | 800 | Título de página ("Configurações Gerais") |
| `gj.type.h2` | Jakarta | 28 / 24 px, lh 1.2 | 700 | Título de seção |
| `gj.type.h3` | Jakarta | 22 / 20 px, lh 1.3 | 700 | Título de card grande, nome da universidade |
| `gj.type.h4` | Jakarta | 18 px, lh 1.35 | 700 | Título de card pequeno, cabeçalho de modal |
| `gj.type.eyebrow` | Jakarta | 14 px, uppercase, tracking 0.12em | 800 | Sigla de programa (ENEM, FIES), rótulo "PROGRAMA PRINCIPAL" |
| `gj.type.body.lg` | Inter | 18 px, lh 1.6 | 400 | Parágrafo introdutório |
| `gj.type.body` | Inter | 16 px, lh 1.6 | 400 | Corpo padrão |
| `gj.type.body.sm` | Inter | 14 px, lh 1.5 | 400 | Descrições em cards, célula de tabela |
| `gj.type.label` | Inter | 14 px, lh 1.4 | 600 | Label de campo, item de tab, botão |
| `gj.type.caption` | Inter | 12 px, lh 1.4 | 500 | Legendas, timestamps, contador de caracteres |
| `gj.type.logo` | Jakarta | 24 px, tracking -0.03em | 800 | Wordmark "Guia Jovem" em texto, apenas como fallback do logo (ver 2.10) |

Regras: nunca usar mais de 3 tamanhos numa mesma tela pública; corpo nunca abaixo de 14 px; largura de linha máxima 72 caracteres (max-width 680 px em parágrafos).

### 2.3 Espaçamento (base 4 px)

| Token | Valor | Uso |
| --- | --- | --- |
| `gj.space.1` | 4 | Entre ícone e texto |
| `gj.space.2` | 8 | Entre label e input, gap de chips |
| `gj.space.3` | 12 | Padding interno de chip/tag, gap de lista densa |
| `gj.space.4` | 16 | Padding de botão, gap padrão entre campos |
| `gj.space.5` | 20 | |
| `gj.space.6` | 24 | Padding de card compacto, gap entre cards no mobile |
| `gj.space.8` | 32 | Padding de card padrão (Stitch usa `p-8`), gap entre cards desktop |
| `gj.space.12` | 48 | Padding de modal grande, gap entre seções internas |
| `gj.space.16` | 64 | Espaço entre seções da página |
| `gj.space.24` | 96 | Margem inferior do hero |

### 2.4 Raio de borda (Stitch: `borderRadius`)

| Token | Valor | Uso |
| --- | --- | --- |
| `gj.radius.xs` | 4 | Tags pequenas, células |
| `gj.radius.sm` | 8 | Inputs de painel (`rounded-lg` do Stitch é 16, mas para inputs usar 8 ou 12) |
| `gj.radius.md` | 12 | Inputs públicos, botões retangulares, itens de timeline |
| `gj.radius.lg` | 16 | Cards (`rounded-lg` = 1rem) |
| `gj.radius.xl` | 20 | Cards de destaque, modais (`rounded-xl` = 1.25rem) |
| `gj.radius.full` | 9999 | Botões pill ("Entrar", "Salvar Alterações"), avatares, chips |

### 2.5 Elevação e bordas

| Token | Valor | Uso |
| --- | --- | --- |
| `gj.shadow.none` | | Cards sobre `surface.low` (o Stitch prefere fundo cinza a sombra) |
| `gj.shadow.sm` | `0 1px 2px rgba(0,0,0,.06)` | Cards brancos no painel, header |
| `gj.shadow.md` | `0 4px 12px rgba(0,0,0,.08)` | Hover de card, dropdown |
| `gj.shadow.lg` | `0 10px 30px rgba(0,0,0,.12)` | Modal, drawer |
| `gj.border.subtle` | `1px solid rgba(191,199,212,.2)` | Contorno discreto de card no painel (Stitch `border-outline-variant/5..10`) |
| `gj.border.default` | `1px solid #BFC7D4` | Inputs com borda, tabela |

### 2.6 Iconografia

- Família: **Material Symbols Outlined**, peso 400, FILL 0 por padrão; FILL 1 apenas para ícone de categoria em card e para estrelas preenchidas.
- Tamanhos: 20 px (inline em tabs e inputs), 24 px (padrão), 32 px (ilustrativo em cards), 100 a 200 px com opacidade 10% (decorativo de fundo, como `auto_awesome`, `bolt`, `school` no Stitch).
- Mapa de ícones fixos: Universidades `account_balance`; Campus `location_on`; Cursos `menu_book`; Programas de Entrada `school`; Bolsas `workspace_premium`; Financiamento `account_balance_wallet`; Sugestões `chat_bubble`; Notificações `notifications`; Avaliação `star`; Favorito `bookmark`; Perfil `person`; Sair `logout`; Excluir `delete`; Editar `edit`; Salvar `save`; Pesquisar `search`; Voltar `arrow_back`; Link externo `open_in_new`; Simulados `quiz`; Informações `info`; Dashboard `dashboard`; Usuários `group`; Aprovar `check_circle`; Reprovar `cancel`.
- Em Flutter: pacote `material_symbols_icons` com os mesmos nomes.

### 2.7 Grid e breakpoints

| Nome | Largura | Colunas | Margem lateral | Gutter |
| --- | --- | --- | --- | --- |
| mobile | < 600 | 4 | 16 | 16 |
| tablet | 600 a 1023 | 8 | 24 | 24 |
| desktop | 1024 a 1439 | 12 | 32 | 32 |
| wide | >= 1440 | 12, container máximo 1280 px (Stitch `max-w-7xl`) | auto | 32 |

Header fixo: 72 px de altura (padding 16 vertical). Conteúdo começa com `padding-top` 112 px (`pt-28`).

### 2.8 Movimento

| Token | Valor | Uso |
| --- | --- | --- |
| `gj.motion.fast` | 150 ms ease-out | Hover, pressed (Stitch `duration-150`), toggle |
| `gj.motion.base` | 200 ms ease-in-out | Troca de tab, abertura de dropdown |
| `gj.motion.slow` | 300 ms ease-in-out | Card hover com escala de imagem (Stitch `duration-300/500`), modal |
| Redução | `prefers-reduced-motion` desativa escalas e translações |

### 2.9 Ilustração e imagem

- Fotos: tom claro, estudantes reais em ambientes de estudo, sem filtro pesado. Recorte 16:9 em cards (`h-48` = 192 px) e 4:3 em heros. Sempre `object-fit: cover`.
- Formas decorativas: ícones gigantes translúcidos (10% da cor) posicionados fora da borda do card, como no Stitch. Máximo um por card.
- Os "zigzags" e "raios" pretos do protótipo original do TG (Figuras 12 e 17) são substituídos por esses ícones translúcidos e por formas geométricas suaves em `primary.fixed`.
- Logos de universidades: caixa branca 4:3 com padding 16, `object-fit: contain`, fallback com as iniciais em `primary.fixed`.
- Avatar padrão de usuário sem foto: `gj.brand.symbol` sobre `primary.fixed`.

### 2.10 Marca e logo

Arquivo-fonte: `logo2.svg` (composição empilhada: "GUIA" sobre "JOVEM", arco tracejado, lâmpada à esquerda e foguete abaixo). Versões derivadas devem ser criadas na prancha de Design System e guardadas em `app/assets/brand/`.

| Token | Arquivo | Uso | Tamanho mínimo |
| --- | --- | --- | --- |
| `gj.brand.logo.stacked` | `logo-stacked.svg` | Login, cadastro, telas de sucesso, capa do TG, tela de carregamento | 120 px de largura |
| `gj.brand.logo.horizontal` | `logo-horizontal.svg` | Header público, header de painel, footer, e-mails | 140 x 40 px (header usa 40 px de altura) |
| `gj.brand.symbol` | `symbol.svg` | Favicon, ícone do app, avatar padrão, marcador em mapas, estado vazio | 24 px |
| `gj.brand.logo.mono.light` | `logo-horizontal-white.svg` | Footer e cards com fundo `primary` | igual ao horizontal |

Regras:
- Cores do logo seguem os tokens: texto em `gj.color.text.primary` (`#1A1C1C`) e traços (arco, lâmpada, foguete) em `gj.color.primary` (`#0061A4`). A versão monocromática branca é toda `#FFFFFF`. Os tons originais do arquivo (`#494949` e `#77C6FC`) não são usados.
- O arquivo original contém dois elementos rasterizados embutidos; todas as versões derivadas devem ser 100% vetoriais.
- Área de respiro mínima ao redor do logo: altura da letra "G".
- Não deformar, rotacionar, aplicar sombra ou gradiente. Não usar o wordmark em texto ("Guia Jovem" em Plus Jakarta Sans) onde o logo horizontal couber; o wordmark em texto fica apenas como fallback em espaços menores que 140 px.
- Sobre fotos, usar a versão branca com overlay escuro de 40%.

---

## 3. Componentes

Para cada componente: anatomia, variantes, estados, tokens e regras. Prefixo `GJ` em Flutter.

### 3.1 GJButton
- **Variantes:** `primary` (fundo `primary.container`, texto branco), `secondary` (borda 1px `primary/20`, texto `primary`, hover preenche `primary` e texto branco, como "Ver Detalhes" do Stitch), `ghost` (só texto `primary`, hover `surface.low`), `danger` (fundo `error`, texto branco), `google` (fundo branco, borda `border`, ícone do Google, texto `text.primary`).
- **Formas:** `pill` (radius full; usar em header, ações de painel e CTAs curtos) e `rect` (radius md; usar em formulários e cards com largura total).
- **Tamanhos:** sm 36 px / md 44 px / lg 52 px de altura; padding horizontal 16 / 24 / 32.
- **Estados:** default, hover (brightness 110% ou `primary.dark`), pressed (scale 0.97 e `gj.motion.fast`), focus (anel 2px `primary` com offset 2), disabled (opacidade 40%, sem hover), loading (spinner 16 px substitui o texto, largura mantida).
- **Regras:** um único `primary` por região visual. Ícone opcional à esquerda, 20 px, gap 8. Texto em `gj.type.label`, sem caixa alta.

### 3.2 GJInput (texto, e-mail, senha, telefone, CNPJ, URL, textarea, select)
- **Anatomia:** label acima (`gj.type.label`, `text.secondary`, margin-left 4), campo, texto de apoio ou erro abaixo (`gj.type.caption`).
- **Visual público:** fundo `surface.lowest`, sem borda, sombra sm, radius md, padding 16 vertical e 16 horizontal (Stitch hero). **Visual painel:** fundo `surface.low`, sem borda, radius sm, padding 12/16.
- **Estados:** default, hover (fundo um nível mais escuro), focus (anel 2px `primary`), error (anel 2px `error` + mensagem em `error` com ícone `error`), disabled (opacidade 60%), read-only (fundo `surface.high`).
- **Extras:** ícone à esquerda 20 px (`search`, `map`, `mail`); botão mostrar/ocultar senha; máscaras `00.000.000/0000-00`, `(00) 00000-0000`, `00000-000`; contador `120/500` em textareas.
- **Regras:** placeholder nunca substitui label. Mensagem de erro sempre específica ("Informe uma senha com 7 ou mais caracteres").

### 3.3 GJSearchBar
- Barra composta: 1 a 3 campos lado a lado + botão primário "Pesquisar" com ícone `search`. No mobile empilha. Fundo dos campos `surface.lowest`, radius md. Linha abaixo opcional com `GJToggleGroup` ("Públicas / Federais", "Privadas") e `GJSlider` ("Nota").

### 3.4 GJCard
- **Base:** fundo `surface.low`, radius lg, padding 32 (desktop) / 24 (mobile), sem borda, hover fundo `surface` e `gj.motion.slow`. Variante `elevated` (fundo branco, sombra sm, `border.subtle`) para painéis.
- **GJCard.universidade:** logo (caixa 4:3), nome (`h3`), cidade/UF (`body.sm` secundário), `GJRating` compacto com média e total, até 3 `GJTag` de programas, botão secundário "Saiba mais".
- **GJCard.programa:** imagem 16:9 (radius lg no topo), linha com ícone FILL 1 + sigla em `eyebrow` na cor da categoria, título `h3`, descrição `body` secundária, botão secundário largura total "Ver detalhes". Pode ter ícone decorativo translúcido.
- **GJCard.curso:** imagem quadrada ilustrada, nome em `label` centralizado, borda arredondada. Usado na grade da home.
- **GJCard.info:** ícone 24 px em caixa 48x48 `primary.container` radius sm + título + descrição (item de cronograma do Stitch).
- **GJCard.metric:** label pequeno, valor grande em `h2` `primary`, barra de progresso 6 px trilho `surface` preenchimento `primary` (Estatísticas do Perfil).
- **GJCard.highlight:** fundo `primary`, texto branco, ícone decorativo 9xl 10% no canto (Visibilidade da Página).

### 3.5 GJCarousel
- Scroll horizontal com snap, setas nas laterais em desktop (botões ghost circulares 40 px), indicador de página em pontos. Cards com largura fixa 320 px desktop / 85% da tela mobile. Cabeçalho da seção com título `h2` à esquerda e link "Ver todas" à direita.

### 3.6 GJTag / GJChip
- **Tag (leitura):** radius full, padding 4/12, `caption` 600. Cores conforme tabela de categoria e status.
- **Chip (interação):** mesmo visual com ícone `close` para remover filtro; variante selecionável com borda.

### 3.7 GJRating
- 5 ícones `star` 20 px (compacto) ou 32 px (input). Preenchido em `rating`, vazio em `border`. Texto ao lado "4,6 (128 avaliações)" em `body.sm`. Modo input com hover e teclado (setas).

### 3.8 GJTabs
- Horizontal com ícone 20 px + texto `label`, padding 16 vertical / 24 horizontal. Ativa: texto `primary` 700, borda inferior 2px `primary`. Inativa: `text.secondary`, hover `primary`. Linha inferior do grupo `border/10`. Com scroll horizontal no mobile, sem quebra.

### 3.9 GJStepper
- 3 círculos numerados ligados por linha. Concluído: fundo `primary`, ícone `check`. Atual: borda 2px `primary`, número em `primary`. Futuro: borda `border`, número em `text.disabled`. Rótulo abaixo em `caption`.

### 3.10 GJModal / GJDialog
- **Modal (conteúdo):** overlay `on-background/20` com blur 8 px, container branco radius xl, sombra lg, largura máx. 896 px (`max-w-4xl`), botão fechar `close` no canto superior direito, padding 48. Pode ter coluna lateral colorida `primary` com título e texto (detalhe de programa no Stitch).
- **Dialog (decisão):** largura 440 px, título `h4`, texto `body`, ações à direita: ghost "Cancelar" + primário ou danger. Sempre usado em: sair, excluir conta, excluir registro, reprovar universidade.
- **Drawer (formulário em painel):** lateral direita 480 px, título + botão fechar, corpo com scroll, rodapé fixo com "Cancelar" e "Salvar".

### 3.11 GJHeader
- Altura 72, fundo `white/80` com blur 20 (glass), sombra sm, fixo. Esquerda: `gj.brand.logo.horizontal` com 40 px de altura, link para a home. Centro: links (`body` 500 `text.secondary`; ativo `primary` 700 com borda inferior 2px). Direita: botão pill "Entrar" ou `GJAvatarMenu`. Variante painel: logo horizontal + divisor vertical + título do painel em `text.secondary`, sino com badge numérico, avatar com iniciais.

### 3.12 GJAvatarMenu
- Avatar circular 40 px (foto ou iniciais sobre `primary.container`). Dropdown 240 px, itens com ícone 20 px: Visualizar Perfil, Painel Administrativo (condicional), Desligar, divisor, Excluir Conta (em `error`).

### 3.13 GJFooter
- Fundo `primary` (Stitch usa `bg-primary` / `blue-700`), texto branco e `blue-100/80` para secundário. Grade 2 colunas desktop. Logo `gj.brand.logo.mono.light` no topo da coluna esquerda. Copyright em 14 px.

### 3.14 GJDataTable
- Cabeçalho `label` 600 em `surface.low`, linhas 56 px, divisores `surface.dim`, hover `surface.low`. Coluna de ações à direita com ícones ghost. Paginação abaixo. Em mobile transforma-se em lista de cards. Toolbar acima com busca, filtros (chips) e botão primário "Novo".

### 3.15 GJEmptyState
- Ícone 48 px em `text.disabled`, título `h4`, texto `body.sm`, botão opcional. Textos de referência: "Nenhuma universidade encontrada com esses filtros", "Você ainda não salvou nenhuma faculdade".

### 3.16 GJToast / GJAlert
- **Toast:** canto inferior direito (desktop) ou topo (mobile), fundo `inverse.surface`, texto `inverse.on`, ícone semântico, 4 s. Sucesso, erro, info.
- **Alert (inline):** fundo container semântico, texto on-container, ícone à esquerda, radius md. Usado para "Cadastro em análise" no painel e avisos de formulário.

### 3.17 GJNotificationBell
- Ícone `notifications` 24 px, badge circular 18 px `error` com contador. Dropdown 360 px com lista (título 600, mensagem `body.sm`, tempo `caption`), não lida com ponto `primary` à esquerda, rodapé "Marcar todas como lidas".

### 3.18 GJTimeline
- Itens verticais: data à esquerda em coluna fixa (mês `caption` uppercase + dia `h3` `primary`), linha vertical `border`, título 600 + descrição `body.sm`. Usado em "Datas Importantes".

### 3.19 GJStatusBadge
- Tag com ponto colorido 8 px à esquerda (verde pulsante para "Publicado e Ativo", como no Stitch).

### 3.20 GJSkeleton
- Blocos `surface.highest` com shimmer, mesmas dimensões do componente final.

---

## 4. Padrões

### 4.1 Formulários
- Uma coluna no mobile; duas colunas no painel desktop (grid 2 x N, gap 24).
- Label sempre visível; campos obrigatórios sem asterisco, opcionais marcados com "(opcional)".
- Validação ao sair do campo e ao enviar. Erro no topo do formulário só quando vier da API.
- Botões no rodapé: secundário "Descartar/Cancelar" à esquerda, primário à direita. Em telas públicas o primário ocupa a largura total.

### 4.2 Páginas de listagem (pesquisa)
Hero curto com título + `GJSearchBar` > chips de filtros aplicados > toolbar (contagem de resultados, ordenação, "Gerar relatório") > grid de `GJCard` 3 colunas desktop / 2 tablet / 1 mobile > paginação.

### 4.3 Páginas de detalhe
Cabeçalho com identidade (logo/imagem, título, tags, ações principais como botões pill) > blocos em cards distribuídos em grid 2/3 + 1/3 > seção de relacionamento (campus, universidades que aceitam) > avaliações.

### 4.4 Painéis administrativos
Header de painel > título de página + ações (Descartar, Salvar) > `GJTabs` > conteúdo em grid 2/3 (formulários ou tabela) + 1/3 (cards de status e métricas). Ações destrutivas sempre com `GJDialog`.

### 4.5 Fluxos em etapas (cadastro de universidade)
Card centralizado 560 px com `GJStepper` no topo, um grupo de campos por etapa, botões "Voltar" (ghost) e "Próximo"/"Cadastrar" (primário). Progresso salvo em memória ao voltar.

### 4.6 Autenticação
Cards centralizados 440 px sobre fundo com forma decorativa `primary.fixed`. Título `h3`, subtítulo `body.sm`, campos, primário largura total, links em `primary` 600, divisor "OU", botão Google.

### 4.7 Estados de carregamento e erro
Skeleton para listas e cards; spinner só dentro de botões. Erro de rede: `GJEmptyState` com "Tentar novamente". Nunca tela branca.

---

## 5. Conteúdo e voz

- Português do Brasil, tom encorajador e direto, sem jargão institucional. "Você" como tratamento.
- Títulos em frase (só a primeira letra maiúscula), exceto siglas.
- Botões começam com verbo: "Ver detalhes", "Salvar alterações", "Criar conta".
- Mensagens de erro dizem o que fazer, não só o que deu errado.
- Termos fixos: "Programa de Entrada" (não "programa de ingresso" no público), "Bolsa de Estudo", "Financiamento Estudantil", "Universidade" (não "faculdade", exceto no botão histórico "Acessar página da faculdade"), "Campus".
- Sem travessão em textos de interface; usar dois pontos, vírgula ou ponto.

---

## 6. Acessibilidade

- Contraste mínimo 4.5:1 para texto e 3:1 para ícones e bordas. Combinações aprovadas: `text.primary`/`background`, branco/`primary`, branco/`primary.container` (3.2:1, usar apenas em texto 600 de 16 px ou maior), `primary`/`primary.fixed`.
- Foco visível em todo elemento interativo (anel 2 px `primary`).
- Alvos de toque mínimo 44 x 44.
- Todos os ícones sem texto têm `tooltip`/`semanticsLabel`.
- Imagens de conteúdo com texto alternativo; decorativas marcadas como tal.
- Estrelas de avaliação operáveis por teclado e anunciadas como "4 de 5 estrelas".
- Modais com foco preso e fechamento por Esc.

---

## 7. Implementação em Flutter

### 7.1 Estrutura
```
lib/core/theme/
├── gj_colors.dart        // class GJColors { static const primary = Color(0xFF0061A4); ... }
├── gj_typography.dart    // TextTheme com GoogleFonts.plusJakartaSans / inter
├── gj_spacing.dart       // class GJSpace { static const s4 = 16.0; ... }
├── gj_radius.dart
├── gj_shadows.dart
├── gj_breakpoints.dart   // isMobile(context), isTablet, isDesktop
└── gj_theme.dart         // ThemeData build(): ColorScheme + component themes
lib/shared/widgets/       // um arquivo por componente GJ*
```

### 7.2 Mapeamento ColorScheme (Material 3)
```dart
ColorScheme(
  brightness: Brightness.light,
  primary: GJColors.primary,                 // 0061A4
  onPrimary: Colors.white,
  primaryContainer: GJColors.primaryContainer, // 2196F3
  onPrimaryContainer: Colors.white,
  secondary: GJColors.secondary,             // 005FAF
  onSecondary: Colors.white,
  secondaryContainer: GJColors.secondaryFixed, // D4E3FF
  onSecondaryContainer: Color(0xFF003567),
  tertiary: GJColors.tertiary,               // B3272A
  onTertiary: Colors.white,
  tertiaryContainer: GJColors.tertiaryFixed, // FFDAD7
  onTertiaryContainer: Color(0xFF5D0008),
  error: GJColors.error,                     // BA1A1A
  onError: Colors.white,
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF93000A),
  surface: Color(0xFFF9F9F9),
  onSurface: Color(0xFF1A1C1C),
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFF3F3F3),
  surfaceContainer: Color(0xFFEEEEEE),
  surfaceContainerHigh: Color(0xFFE8E8E8),
  surfaceContainerHighest: Color(0xFFE2E2E2),
  onSurfaceVariant: Color(0xFF404752),
  outline: Color(0xFF707883),
  outlineVariant: Color(0xFFBFC7D4),
  inverseSurface: Color(0xFF2F3131),
  onInverseSurface: Color(0xFFF1F1F1),
  inversePrimary: Color(0xFF9ECAFF),
)
```

### 7.3 Regras de código
- Nenhum `Color(0x...)` fora de `gj_colors.dart`. Nenhum número de espaçamento literal fora de `gj_spacing.dart`.
- Todo componente `GJ*` recebe apenas dados e callbacks; sem chamadas de API dentro de widgets compartilhados.
- Cada componente tem um exemplo em `widgetbook/` (ou uma tela `/dev/components` acessível só em debug) exibindo todas as variantes e estados. Essa galeria é o "Storybook" do projeto e serve para validar com o protótipo aprovado.
- Testes de golden para GJButton, GJCard.universidade, GJCard.programa, GJInput e GJTabs.

### 7.4 Equivalência Tailwind (Stitch) > Flutter
| Stitch | Flutter |
| --- | --- |
| `rounded-xl` (1.25rem) | `BorderRadius.circular(GJRadius.xl)` = 20 |
| `rounded-lg` (1rem) | `GJRadius.lg` = 16 |
| `rounded-full` | `StadiumBorder()` |
| `p-8` | `EdgeInsets.all(GJSpace.s8)` = 32 |
| `gap-8` | `SizedBox(width/height: 32)` ou `Wrap(spacing: 32)` |
| `max-w-7xl` | `ConstrainedBox(maxWidth: 1280)` |
| `shadow-sm` | `GJShadows.sm` |
| `backdrop-blur-md` header | `ClipRect + BackdropFilter(ImageFilter.blur(sigmaX: 10, sigmaY: 10))` |
| `hover:scale-95` / `active:scale-95` | `AnimatedScale(scale: pressed ? 0.97 : 1, duration: GJMotion.fast)` |
| `text-primary/10` ícone decorativo | `Icon(color: GJColors.primary.withValues(alpha: .10))` |

---

## 8. Como construir e manter o design system (processo)

1. **Tokens primeiro.** Criar `gj_colors`, `gj_typography`, `gj_spacing`, `gj_radius`, `gj_shadows`, `gj_brand` (caminhos dos SVGs do logo) e `gj_theme` antes de qualquer tela. Validar renderizando a galeria de tokens.
2. **Componentes base.** Implementar na ordem: GJButton, GJInput, GJCard, GJTag, GJTabs, GJModal/Dialog, GJHeader, GJFooter. São usados por todas as telas.
3. **Componentes de domínio.** GJCard.universidade, GJCard.programa, GJCard.curso, GJRating, GJCarousel, GJTimeline, GJStepper, GJDataTable, GJNotificationBell.
4. **Galeria.** Tela `/dev/components` com todas as variantes e estados; comparar lado a lado com o protótipo aprovado; ajustar tokens (nunca a tela) até bater.
5. **Telas.** Só depois montar as páginas da especificação (seção 8 do `ESPECIFICACAO.md`) compondo componentes; se uma tela pedir algo que não existe, criar o componente aqui primeiro.
6. **Governança.** Toda mudança de token ou componente novo passa por este arquivo (versão no topo). Changelog no final.

---

## 9. Checklist de conformidade (para revisar cada tela)

- [ ] Só cores dos tokens; azul para ação, vermelho para perigo, categoria de programa na cor correta.
- [ ] Um botão primário por região.
- [ ] Títulos em Plus Jakarta Sans, corpo em Inter, tamanhos da escala.
- [ ] Espaçamentos múltiplos de 4; padding de card 32/24.
- [ ] Radius: cards 16/20, botões pill ou 12, inputs 8/12.
- [ ] Estados: loading (skeleton), vazio, erro, sucesso.
- [ ] Responsivo em 360, 768, 1024, 1440.
- [ ] Contraste AA, foco visível, alvos 44 px.
- [ ] Textos em pt-BR, botões com verbo, sem travessão.
- [ ] Sem faixa "DEMO", sem classes `dark:`.
- [ ] Logo oficial (não o wordmark em texto) no header e no footer, nas cores dos tokens.

---

## Changelog
- **v1.2** Token `tertiary.dark` (#8C1D20) para hover na categoria Financiamento, a partir do protótipo do Grupo Público.
- **v1.1** Seção 2.10 Marca e logo: logo oficial em SVG com versões empilhada, horizontal, símbolo e monocromática branca; header, footer e avatar padrão atualizados.
- **v1.0** Consolidação inicial a partir do protótipo Stitch (2 telas: Programas de Entrada e Painel de Administração da Universidade, mais a tela ENEM) e das Figuras 12 a 36 do TG.
