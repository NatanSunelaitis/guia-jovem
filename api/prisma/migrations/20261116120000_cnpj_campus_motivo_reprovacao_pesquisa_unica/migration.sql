-- AlterTable
ALTER TABLE `campus` ADD COLUMN `cnpj` CHAR(14) NULL;

-- AlterTable
ALTER TABLE `universidade` ADD COLUMN `motivo_reprovacao` TEXT NULL;

-- CreateIndex
CREATE UNIQUE INDEX `uk_pesquisa_salva_usuario_nome` ON `pesquisa_salva`(`id_usuario`, `nome`);
