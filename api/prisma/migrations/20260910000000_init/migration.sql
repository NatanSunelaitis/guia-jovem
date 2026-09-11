-- CreateTable
CREATE TABLE `usuario` (
    `id_usuario` INTEGER NOT NULL AUTO_INCREMENT,
    `nome` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL,
    `senha_hash` VARCHAR(255) NULL,
    `tipo_usuario` CHAR(1) NOT NULL,
    `cpf` CHAR(11) NULL,
    `google_id` VARCHAR(64) NULL,
    `foto_url` VARCHAR(255) NULL,
    `ativo` BOOLEAN NOT NULL DEFAULT true,
    `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `atualizado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `usuario_email_key`(`email`),
    UNIQUE INDEX `usuario_google_id_key`(`google_id`),
    PRIMARY KEY (`id_usuario`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `universidade` (
    `id_universidade` INTEGER NOT NULL AUTO_INCREMENT,
    `id_usuario` INTEGER NOT NULL,
    `nome_fantasia` VARCHAR(100) NOT NULL,
    `razao_social` VARCHAR(100) NOT NULL,
    `cnpj` CHAR(14) NOT NULL,
    `descricao` TEXT NULL,
    `telefone_principal` VARCHAR(15) NULL,
    `link_pagina` VARCHAR(255) NULL,
    `link_simulados` VARCHAR(255) NULL,
    `logo_url` VARCHAR(255) NULL,
    `natureza` CHAR(1) NOT NULL DEFAULT 'V',
    `status` CHAR(1) NOT NULL DEFAULT 'P',
    `aprovado_em` DATETIME NULL,
    `aprovado_por` INTEGER NULL,
    `media_avaliacao` DECIMAL(3, 2) NULL,
    `total_avaliacoes` INTEGER NOT NULL DEFAULT 0,
    `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `atualizado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `universidade_id_usuario_key`(`id_usuario`),
    UNIQUE INDEX `universidade_cnpj_key`(`cnpj`),
    INDEX `idx_universidade_status`(`status`),
    INDEX `idx_universidade_nome`(`nome_fantasia`),
    PRIMARY KEY (`id_universidade`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `endereco` (
    `id_endereco` INTEGER NOT NULL AUTO_INCREMENT,
    `logradouro` VARCHAR(100) NOT NULL,
    `numero` VARCHAR(10) NOT NULL,
    `complemento` VARCHAR(100) NULL,
    `bairro` VARCHAR(100) NOT NULL,
    `cidade` VARCHAR(100) NOT NULL,
    `estado` CHAR(2) NOT NULL,
    `cep` CHAR(8) NULL,

    INDEX `idx_endereco_cidade`(`cidade`),
    INDEX `idx_endereco_estado`(`estado`),
    PRIMARY KEY (`id_endereco`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `campus` (
    `id_campus` INTEGER NOT NULL AUTO_INCREMENT,
    `id_universidade` INTEGER NOT NULL,
    `id_endereco` INTEGER NOT NULL,
    `nome` VARCHAR(100) NOT NULL,
    `telefone_celular` VARCHAR(15) NULL,
    `telefone_fixo` VARCHAR(15) NULL,
    `email_campus` VARCHAR(100) NULL,
    `principal` BOOLEAN NOT NULL DEFAULT false,
    `ativo` BOOLEAN NOT NULL DEFAULT true,

    PRIMARY KEY (`id_campus`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `curso` (
    `id_curso` INTEGER NOT NULL AUTO_INCREMENT,
    `id_universidade` INTEGER NOT NULL,
    `nome` VARCHAR(100) NOT NULL,
    `area_curso` VARCHAR(100) NULL,
    `nota_mec` VARCHAR(100) NULL,
    `modalidade` VARCHAR(20) NULL,
    `grau` VARCHAR(20) NULL,
    `duracao_semestres` TINYINT NULL,
    `descricao` TEXT NULL,
    `ativo` BOOLEAN NOT NULL DEFAULT true,

    INDEX `idx_curso_nome`(`nome`),
    INDEX `idx_curso_area`(`area_curso`),
    PRIMARY KEY (`id_curso`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `campus_curso` (
    `id_campus` INTEGER NOT NULL,
    `id_curso` INTEGER NOT NULL,
    `turno` VARCHAR(20) NULL,
    `vagas` INTEGER NULL,

    PRIMARY KEY (`id_campus`, `id_curso`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `programa` (
    `id_programa` INTEGER NOT NULL AUTO_INCREMENT,
    `nome` VARCHAR(100) NOT NULL,
    `sigla` VARCHAR(20) NULL,
    `descricao` TEXT NOT NULL,
    `tipo` ENUM('ENTRADA', 'FINANCIAMENTO', 'BOLSA') NOT NULL,
    `requisitos` TEXT NULL,
    `como_funciona` TEXT NULL,
    `link_oficial` VARCHAR(255) NULL,
    `imagem_url` VARCHAR(255) NULL,
    `id_usuario` INTEGER NOT NULL,
    `id_universidade` INTEGER NULL,
    `ativo` BOOLEAN NOT NULL DEFAULT true,
    `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_programa_tipo`(`tipo`),
    PRIMARY KEY (`id_programa`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `programa_evento` (
    `id_evento` INTEGER NOT NULL AUTO_INCREMENT,
    `id_programa` INTEGER NOT NULL,
    `titulo` VARCHAR(100) NOT NULL,
    `descricao` VARCHAR(255) NULL,
    `data_inicio` DATE NOT NULL,
    `data_fim` DATE NULL,

    PRIMARY KEY (`id_evento`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `universidade_programa` (
    `id_universidade` INTEGER NOT NULL,
    `id_programa` INTEGER NOT NULL,
    `observacao` VARCHAR(255) NULL,

    PRIMARY KEY (`id_universidade`, `id_programa`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `avaliacao` (
    `id_avaliacao` INTEGER NOT NULL AUTO_INCREMENT,
    `id_usuario` INTEGER NULL,
    `id_universidade` INTEGER NOT NULL,
    `nota` TINYINT NOT NULL,
    `comentario` VARCHAR(500) NULL,
    `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `uk_avaliacao_usuario_univ`(`id_usuario`, `id_universidade`),
    PRIMARY KEY (`id_avaliacao`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `sugestao` (
    `id_sugestao` INTEGER NOT NULL AUTO_INCREMENT,
    `id_usuario` INTEGER NULL,
    `id_universidade` INTEGER NULL,
    `titulo` VARCHAR(100) NOT NULL,
    `texto` TEXT NOT NULL,
    `status` ENUM('EM_ANALISE', 'APROVADA', 'REPROVADA') NOT NULL DEFAULT 'EM_ANALISE',
    `resposta` TEXT NULL,
    `avaliado_por` INTEGER NULL,
    `avaliado_em` DATETIME NULL,
    `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id_sugestao`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `notificacao` (
    `id_notificacao` INTEGER NOT NULL AUTO_INCREMENT,
    `id_usuario` INTEGER NOT NULL,
    `tipo` VARCHAR(30) NOT NULL,
    `titulo` VARCHAR(100) NOT NULL,
    `mensagem` VARCHAR(255) NOT NULL,
    `referencia_tipo` VARCHAR(30) NULL,
    `referencia_id` INTEGER NULL,
    `lida` BOOLEAN NOT NULL DEFAULT false,
    `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_notificacao_usuario_lida`(`id_usuario`, `lida`),
    PRIMARY KEY (`id_notificacao`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `universidade_salva` (
    `id_usuario` INTEGER NOT NULL,
    `id_universidade` INTEGER NOT NULL,
    `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id_usuario`, `id_universidade`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `pesquisa_salva` (
    `id_pesquisa` INTEGER NOT NULL AUTO_INCREMENT,
    `id_usuario` INTEGER NOT NULL,
    `nome` VARCHAR(100) NOT NULL,
    `tipo` ENUM('UNIVERSIDADE', 'PROGRAMA', 'CURSO') NOT NULL,
    `parametros` JSON NOT NULL,
    `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id_pesquisa`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `token_recuperacao` (
    `id_token` INTEGER NOT NULL AUTO_INCREMENT,
    `id_usuario` INTEGER NOT NULL,
    `token_hash` CHAR(64) NOT NULL,
    `expira_em` DATETIME NOT NULL,
    `usado_em` DATETIME NULL,

    UNIQUE INDEX `token_recuperacao_token_hash_key`(`token_hash`),
    PRIMARY KEY (`id_token`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `refresh_token` (
    `id_refresh` INTEGER NOT NULL AUTO_INCREMENT,
    `id_usuario` INTEGER NOT NULL,
    `token_hash` CHAR(64) NOT NULL,
    `expira_em` DATETIME NOT NULL,
    `revogado_em` DATETIME NULL,

    UNIQUE INDEX `refresh_token_token_hash_key`(`token_hash`),
    PRIMARY KEY (`id_refresh`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `log_auditoria` (
    `id_log` BIGINT NOT NULL AUTO_INCREMENT,
    `id_usuario` INTEGER NULL,
    `acao` VARCHAR(20) NOT NULL,
    `entidade` VARCHAR(40) NOT NULL,
    `entidade_id` INTEGER NULL,
    `dados_antes` JSON NULL,
    `dados_depois` JSON NULL,
    `ip` VARCHAR(45) NULL,
    `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id_log`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `visita_pagina` (
    `id_visita` BIGINT NOT NULL AUTO_INCREMENT,
    `rota` VARCHAR(120) NOT NULL,
    `entidade` VARCHAR(30) NULL,
    `entidade_id` INTEGER NULL,
    `tipo_usuario` CHAR(1) NULL,
    `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_visita_data`(`criado_em`),
    INDEX `idx_visita_entidade`(`entidade`, `entidade_id`),
    PRIMARY KEY (`id_visita`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `universidade` ADD CONSTRAINT `universidade_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `universidade` ADD CONSTRAINT `universidade_aprovado_por_fkey` FOREIGN KEY (`aprovado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `campus` ADD CONSTRAINT `campus_id_universidade_fkey` FOREIGN KEY (`id_universidade`) REFERENCES `universidade`(`id_universidade`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `campus` ADD CONSTRAINT `campus_id_endereco_fkey` FOREIGN KEY (`id_endereco`) REFERENCES `endereco`(`id_endereco`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `curso` ADD CONSTRAINT `curso_id_universidade_fkey` FOREIGN KEY (`id_universidade`) REFERENCES `universidade`(`id_universidade`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `campus_curso` ADD CONSTRAINT `campus_curso_id_campus_fkey` FOREIGN KEY (`id_campus`) REFERENCES `campus`(`id_campus`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `campus_curso` ADD CONSTRAINT `campus_curso_id_curso_fkey` FOREIGN KEY (`id_curso`) REFERENCES `curso`(`id_curso`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `programa` ADD CONSTRAINT `programa_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `programa` ADD CONSTRAINT `programa_id_universidade_fkey` FOREIGN KEY (`id_universidade`) REFERENCES `universidade`(`id_universidade`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `programa_evento` ADD CONSTRAINT `programa_evento_id_programa_fkey` FOREIGN KEY (`id_programa`) REFERENCES `programa`(`id_programa`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `universidade_programa` ADD CONSTRAINT `universidade_programa_id_universidade_fkey` FOREIGN KEY (`id_universidade`) REFERENCES `universidade`(`id_universidade`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `universidade_programa` ADD CONSTRAINT `universidade_programa_id_programa_fkey` FOREIGN KEY (`id_programa`) REFERENCES `programa`(`id_programa`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `avaliacao` ADD CONSTRAINT `avaliacao_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `avaliacao` ADD CONSTRAINT `avaliacao_id_universidade_fkey` FOREIGN KEY (`id_universidade`) REFERENCES `universidade`(`id_universidade`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `sugestao` ADD CONSTRAINT `sugestao_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `sugestao` ADD CONSTRAINT `sugestao_id_universidade_fkey` FOREIGN KEY (`id_universidade`) REFERENCES `universidade`(`id_universidade`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `sugestao` ADD CONSTRAINT `sugestao_avaliado_por_fkey` FOREIGN KEY (`avaliado_por`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `notificacao` ADD CONSTRAINT `notificacao_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `universidade_salva` ADD CONSTRAINT `universidade_salva_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `universidade_salva` ADD CONSTRAINT `universidade_salva_id_universidade_fkey` FOREIGN KEY (`id_universidade`) REFERENCES `universidade`(`id_universidade`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `pesquisa_salva` ADD CONSTRAINT `pesquisa_salva_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `token_recuperacao` ADD CONSTRAINT `token_recuperacao_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `refresh_token` ADD CONSTRAINT `refresh_token_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `log_auditoria` ADD CONSTRAINT `log_auditoria_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

-- CheckConstraint (fidelidade ao DDL de referência, seção 4.3 da especificação)
ALTER TABLE `usuario` ADD CONSTRAINT `usuario_tipo_usuario_check` CHECK (`tipo_usuario` IN ('A', 'U', 'D'));

ALTER TABLE `avaliacao` ADD CONSTRAINT `avaliacao_nota_check` CHECK (`nota` BETWEEN 1 AND 5);
