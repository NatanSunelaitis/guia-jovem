-- DropForeignKey
ALTER TABLE `universidade` DROP FOREIGN KEY `universidade_id_usuario_fkey`;

-- AlterTable
ALTER TABLE `universidade` MODIFY `id_usuario` INTEGER NULL;

-- AddForeignKey
ALTER TABLE `universidade` ADD CONSTRAINT `universidade_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

